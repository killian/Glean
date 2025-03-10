{-
  Copyright (c) Meta Platforms, Inc. and affiliates.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree.
-}

module Glean.Regression.Driver.DeriveForCodemarkup (
    main,
    codemarkupDerivePasses
  ) where

import Derive.Lib as Lib
import Glean.Clang.Test.DerivePass

--
-- Derive things we will need for codemarkup.* calls
--
main :: IO ()
main = testDeriver codemarkupDerivePasses

--
-- Standard things we need to derive (also Glass) for full code search/nav
--
codemarkupDerivePasses :: [DerivePass]
codemarkupDerivePasses =
  Lib.allManualPasses ++
  [DeriveGeneric "cxx1.DeclByName"
  ,DeriveGeneric "cxx1.FunctionDeclAttribute"
  ,DeriveGeneric "cxx1.DeclarationToUSR"
  ]
