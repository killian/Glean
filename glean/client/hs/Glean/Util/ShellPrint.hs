-- Copyright 2004-present Facebook. All Rights Reserved.

module Glean.Util.ShellPrint
  ( ShellFormat(..)
  , shellPrint
  ) where

import Prelude hiding ((<>))

import qualified Data.Text as Text
import qualified Data.HashMap.Strict as HashMap
import Data.Time.Clock.POSIX
import Data.List hiding (span)
import Util.TimeSec
import Text.PrettyPrint.Annotated.HughesPJ
import System.Console.ANSI

import qualified Glean.Types as Thrift
import Glean.Backend.Remote (dbShard)
import Glean.Repo.Text (showRepo)

data Context = Context
  { ctxVerbose :: Bool
  , ctxIsTTY :: Bool
  , ctxNow :: Time
  }

shellPrint :: ShellFormat a => Bool -> Bool -> Time -> a -> String
shellPrint ctxVerbose ctxIsTTY ctxNow x =
  renderDecorated
    colourStart
    colourEnd
    (shellFormat Context{..} x)
  where
    colourStart c
      | ctxIsTTY = setSGRCode [SetColor Foreground Vivid c]
      | otherwise = mempty
    colourEnd _
      | ctxIsTTY = setSGRCode [Reset]
      | otherwise = mempty

class ShellFormat a where
    shellFormat :: Context -> a -> Doc Color

instance ShellFormat Thrift.DatabaseStatus where
  shellFormat _ctx status =
    case status of
      Thrift.DatabaseStatus_Complete -> parens "complete"
      Thrift.DatabaseStatus_Finalizing -> parens "finalizing"
      Thrift.DatabaseStatus_Incomplete -> parens "incomplete"
      Thrift.DatabaseStatus_Restoring -> parens "restoring"
      Thrift.DatabaseStatus_Broken -> parens "broken"
      Thrift.DatabaseStatus_Restorable -> parens "restorable"
      Thrift.DatabaseStatus_Missing -> parens "missing deps"

instance ShellFormat (Maybe Thrift.DatabaseStatus) where
  shellFormat ctx status =
    maybe
      (parens "unknown")
      (shellFormat ctx)
      status

instance ShellFormat Thrift.Repo where
  shellFormat _ctx repo = text (showRepo repo)

statusColour :: Maybe Thrift.DatabaseStatus -> Color
statusColour status = case status of
  Just Thrift.DatabaseStatus_Complete -> Green
  Just Thrift.DatabaseStatus_Finalizing -> Green
  Just Thrift.DatabaseStatus_Incomplete -> Blue
  Just Thrift.DatabaseStatus_Restoring -> Black
  Just Thrift.DatabaseStatus_Broken -> Red
  Just Thrift.DatabaseStatus_Restorable -> Black
  Just Thrift.DatabaseStatus_Missing -> Black
  Nothing -> Red

instance ShellFormat Thrift.Database where
  shellFormat ctx db = shellFormat ctx (db, [] :: [String])

instance ShellFormat (Thrift.Database, [String]) where
  shellFormat ctx@Context{..} (db, extras) = cat
    [ annotate (statusColour status) (shellFormat ctx repo)
        <+> shellFormat ctx status
      , nest 2 $ vcat $
        [ "Created:" <+> showWhen t
        | Just t <- [Thrift.database_created_since_epoch db]
        ]
        ++
        [ "Completed:" <+> showWhen t
        | Just t <- [Thrift.database_completed db]
        ]
        ++
        map text extras
        ++
        [ "Backup:" <+> text (Text.unpack loc)
        | ctxVerbose ||
          Thrift.database_status db == Just Thrift.DatabaseStatus_Restorable
        , Just loc <- [Thrift.database_location db]
        ]
        ++
        [ "Expires in:" <+> text (Text.unpack (ppTimeSpan timeSpan))
        | ctxVerbose
        , Just expiresEpochTime <-
            [Thrift.unPosixEpochTime <$> Thrift.database_expire_time db]
        , let expires = Time $ fromIntegral expiresEpochTime
        , let timeSpan = expires `timeDiff` ctxNow
        ]
        ++
        [ "Shard:" <+> text (Text.unpack (dbShard repo))
        | ctxVerbose
        ]
        ++
        [ nest 2 $ text (Text.unpack name) <> ":" <+> text (Text.unpack value)
        | ctxVerbose
        , (name,value) <- sortOn fst $
            HashMap.toList (Thrift.database_properties db)
        ]
    ]
    where
      showWhen (Thrift.PosixEpochTime t) =
        text (show (posixSecondsToUTCTime (fromIntegral t))) <+>
          parens (text (Text.unpack age) <+> "ago")
        where
          age = ppTimeSpanWithGranularity Hour $
            ctxNow `timeDiff` Time (fromIntegral t)

      status = Thrift.database_status db
      repo = Thrift.database_repo db
