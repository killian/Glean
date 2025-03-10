{-
  Copyright (c) Meta Platforms, Inc. and affiliates.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree.
-}

module Glean.Database.List (
  listDatabases,
  listRestorable,
) where

import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap
import Data.Maybe
import Data.Text (Text)

import Util.Control.Exception
import Util.Log
import Util.STM

import qualified Glean.Database.Backup.Backend as Backup
import qualified Glean.Database.Backup.Locator as Backup
import qualified Glean.Database.Catalog as Catalog
import Glean.Database.Meta
import Glean.Database.Types
import qualified Glean.ServerConfig.Types as ServerConfig
import Glean.Types hiding (Database)
import qualified Glean.Types as Thrift
import qualified Glean.Util.Observed as Observed


listDatabases :: Env -> Thrift.ListDatabases -> IO Thrift.ListDatabasesResult
listDatabases env@Env{..} Thrift.ListDatabases{..} = do
  now <- utcTimeToPosixEpochTime <$> envGetCurrentTime
  minDBAge <- ServerConfig.config_min_db_age <$> Observed.get envServerConfig
  let filterWithMinDBAge = filterDatabasePred now minDBAge
  backups <-
    if listDatabases_includeBackups
      then do
        -- Use the cache of restorable DBs populated by the janitor,
        -- if one is available.
        maybeLastFetch <- readTVarIO envCachedRestorableDBs
        restorables <- case maybeLastFetch of
          Just (_, dbs) -> return $ HashMap.fromList dbs
          Nothing -> do
            sites <- atomically $ Backup.getAllSites env
            HashMap.unions <$> mapM (uncurry listRestorable) sites
        return $ reposToResults restorables
      else
        return mempty
  local <- atomically $ Catalog.getLocalDatabases envCatalog
  let databases =
        HashMap.elems $
        fmap Thrift.getDatabaseResult_database $
        HashMap.union local backups
  return Thrift.ListDatabasesResult
    { listDatabasesResult_databases = filter filterWithMinDBAge databases }
  where
    reposToResults = HashMap.mapWithKey
      (\repo meta -> Thrift.GetDatabaseResult
        { getDatabaseResult_database = metaToThriftDatabase
            Thrift.DatabaseStatus_Restorable
            Nothing
            repo
            meta
        , getDatabaseResult_tasks = Nothing
        })
    filterDatabasePred now minDBAge db = currentAgeInSeconds >= minDBAge
      where
        dbTime = case Thrift.database_completed db of
          Just completedAt -> completedAt
          Nothing -> Thrift.database_created_since_epoch db
        currentAgeInSeconds = unPosixEpochTime now - unPosixEpochTime dbTime

listRestorable :: Backup.Site site => Text -> site -> IO (HashMap Repo Meta)
listRestorable prefix site = do
  (HashMap.fromList . mapMaybe restorable <$> Backup.enumerate site)
  `catchAll` \exc -> do
    logError $ "couldn't list restorable databases: " ++ show exc
    return mempty
  where
    restorable (repo, props)
      | Right meta <-
          metaFromProps (Backup.toRepoLocator prefix site repo) props =
            Just (repo, meta)
      | otherwise = Nothing
