{-
  Copyright (c) Meta Platforms, Inc. and affiliates.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree.
-}

{-# LANGUAGE ApplicativeDo #-}
module GleanCLI.Restore (RestoreCommand) where

import Control.Monad (forM_, forM)
import Control.Monad.Extra (firstJustM)
import Control.Concurrent
import Data.Text (Text)
import Data.Maybe (listToMaybe)
import qualified Data.Text as Text
import Data.Time
import Data.Time.Clock.POSIX
import Options.Applicative

import Util.IO
import Util.OptParse
import Util.Log (logInfo)
import Util.STM (atomically)

import Glean
  ( Repo(..)
  , Database(..)
  , DatabaseStatus(..)
  )
import qualified Glean
import qualified Glean.Database.Backup.Locator as Backup
import Glean.LocalOrRemote (BackendKind(BackendEnv), backendKind)
import Glean.Database.Backup.Backend (Site(inspect))
import Glean.Database.Meta (metaFromProps, metaToThriftDatabase)

import GleanCLI.Common
import GleanCLI.Types
import Glean.Database.Repo (inRepo)
import Glean.Database.Open (depParent)

data WhatToRestore
  = RestoreLocator Text
  | RestoreDb Repo
  | RestoreDbOnDay Text Day

data RestoreCommand
  = Restore
      { what :: WhatToRestore
      , ignoreDependencies :: Bool
      }

type Locator = Text

instance Plugin RestoreCommand where
  parseCommand =
    commandParser "restore" (progDesc "Restore a database") $
      Restore <$> what <*> deps
    where
      locator = strArgument
        (  metavar "LOCATOR"
        <> help "DB location, see :list-all in glean shell."
        )
      deps = switch
        (  long "ignore-dependencies"
        <> help "Don't download database dependencies when specifying a DB name.")
      what =
        (RestoreLocator <$> locator) <|>
        (RestoreDb <$> dbSlash) <|> do
          repoName <- dbNameOpt
          spec <- Left <$> dbInstanceOpt <|> Right <$> dayOpt
          return $ case spec of
            Left hash -> RestoreDb (Repo repoName hash)
            Right day -> RestoreDbOnDay repoName day

      parseDay = return .
        parseTimeOrError False defaultTimeLocale (iso8601DateFormat Nothing)

      dayOpt = option (eitherReader parseDay)
        (long "date" <> metavar "YYYY-MM-DD")

  runCommand _ _ backend Restore{..} = do
    targets <- locatorsToRestore
    restore targets
    wait (fst <$> targets)
    where
      locatorsToRestore = case what of
        -- ignores dependencies
        RestoreLocator locator -> return [(locator, Nothing)]
        RestoreDb repo
          | BackendEnv env <- backendKind backend -> do
            logInfo $ inRepo repo "Searching"
            sites <- atomically $ Backup.getAllSites env
            db <- getDatabaseFromSite sites repo
            if ignoreDependencies then withLocator [db] [repo] else do
            allDbs <- getDependenciesOneByOne sites db
            withLocator allDbs (map database_repo allDbs)
          | otherwise -> do
            databases <- listWithBackups
            let deps = if ignoreDependencies
                  then []
                  else dependencies databases repo
            withLocator databases $ repo : deps
        RestoreDbOnDay repoName day -> do
          databases <- listWithBackups
          let matchingDay = listToMaybe
                [ database_repo
                | Database{..} <- databases
                , repo_name database_repo == repoName
                , let t = database_created_since_epoch
                , day == utctDay (posixSecondsToUTCTime $ fromIntegral $
                    Glean.unPosixEpochTime t)
                ]
          case matchingDay of
            Just repo -> do
              let deps = if ignoreDependencies
                    then []
                    else dependencies databases repo
              withLocator databases $ repo : deps
            Nothing -> die 1 $ unwords
              ["Cannot find backup locator for", Text.unpack repoName, "on"
              , formatTime defaultTimeLocale (iso8601DateFormat Nothing) day ]

      getDependenciesOneByOne sites db = do
        case database_dependencies db of
          Nothing -> return [db]
          Just dep -> do
            dep_db <- getDatabaseFromSite sites (depParent dep)
            (db:) <$> getDependenciesOneByOne sites dep_db

      getDatabaseFromSite sites repo = do
        result <- flip firstJustM sites $ \(prefix, site) ->
                    restorable prefix site repo <$> inspect site repo
        maybe (dieHere repo) return result

      restorable prefix site repo props
        | Right meta <-
            metaFromProps (Backup.toRepoLocator prefix site repo) props
        = Just $
          metaToThriftDatabase Glean.DatabaseStatus_Restorable Nothing repo meta
        | otherwise = Nothing

      dieHere repo = die 1 $ "Cannot find " <> show repo

      withLocator :: [Database] -> [Repo] -> IO [(Locator, Maybe Repo)]
      withLocator databases repos = forM repos $ \repo -> do
        locator <- repoLocator databases repo
        return (locator, Just repo)

      listWithBackups =
        Glean.listDatabasesResult_databases <$>
          Glean.listDatabases backend Glean.ListDatabases
            { listDatabases_includeBackups = True
            , listDatabases_client_info = Nothing
            }

      restore targets = do
        forM_ targets $ \(locator, mrepo) -> do
          logInfo $ unwords $
            [ "Restoring" ] ++
            [ Glean.showRepo repo | Just repo <- [mrepo]] ++
            [ "from", Text.unpack locator]
          Glean.restoreDatabase backend locator

      wait locators = do
        localDatabases <- Glean.listDatabasesResult_databases <$>
          Glean.listDatabases backend Glean.ListDatabases
              { listDatabases_includeBackups = False
              , listDatabases_client_info = Nothing
              }
        dbs <- traverse (locatorDb localDatabases) locators
        let isRestoring = (DatabaseStatus_Restoring ==) . database_status
        if any isRestoring dbs
           then threadDelay 1000000 >> wait locators
           else forM_ dbs $ \db -> case database_status db of
                DatabaseStatus_Complete -> return ()
                DatabaseStatus_Missing -> putStrLn $ unwords
                  [ "Some of"
                  , Glean.showRepo (database_repo db)
                  , "dependencies are missing."
                  , "You may want to restore those as well"
                  ] -- TODO: List missing dependencies
                status ->
                  die 1 $ "error: unexpected database status: " <> show status
        where
          locatorDb databases locator =
            case
              [ db
              | db <- databases
              , database_location db == Just locator ]
            of
              [db] -> return db
              [] -> die 1 $ unwords
                ["error: did not find database locator", Text.unpack locator]
              _ -> die 1 $ unwords
                ["error: server has multiple DBs with the locator"
                , Text.unpack locator]

repoLocator :: [Database] -> Repo -> IO Locator
repoLocator databases repo =
  case [ locator
        | Database{..} <- databases
        , database_repo == repo
        , Just locator <- [database_location] ]
  of
    (locator:_) -> return locator
    [] -> die 1 $ "Cannot find backup locator for " <> Glean.showRepo repo

dependencies :: [Database] -> Repo -> [Repo]
dependencies databases repo = repoDeps repo
  where
    repoDeps base =
      case repoDirectDep base of
        Nothing -> []
        Just repo -> repo : repoDeps repo
    repoDirectDep repo = listToMaybe
        [ depParent dep
        | Database{..} <- databases
        , database_repo == repo
        , Just dep <- [database_dependencies]
        ]
