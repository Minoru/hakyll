--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Core.Identifier.Tests
    ( tests
    ) where


--------------------------------------------------------------------------------
import qualified Test.QuickCheck                as Q
import           Test.Tasty                     (TestTree, testGroup)
import           Test.Tasty.HUnit               ((@=?))
import           Test.Tasty.QuickCheck          (testProperty)


--------------------------------------------------------------------------------
import           Hakyll.Core.Identifier
import           Hakyll.Core.Identifier.Pattern
import           System.FilePath                ((</>), isValid, equalFilePath, pathSeparators)
import           TestSuite.Util


--------------------------------------------------------------------------------
tests :: TestTree
tests = testGroup "Hakyll.Core.Identifier.Tests" $ concat
    [ captureTests
    , matchesTests
    , [ testProperty "toFilePath . fromFilePath" filepathConversionProp ]
    ]


--------------------------------------------------------------------------------
captureTests :: [TestTree]
captureTests = fromAssertions "capture"
    [ Just ["bar"]                    @=? capture "foo/**" "foo/bar"
    , Just ["foo" </> "bar"]          @=? capture "**" "foo/bar"
    , Nothing                         @=? capture "*" "foo/bar"
    , Just []                         @=? capture "foo" "foo"
    , Just ["foo"]                    @=? capture "*/bar" "foo/bar"
    , Just ["foo" </> "bar"]          @=? capture "**/qux" "foo/bar/qux"
    , Just ["foo" </> "bar", "qux"]   @=? capture "**/*" "foo/bar/qux"
    , Just ["foo", "bar" </> "qux"]   @=? capture "*/**" "foo/bar/qux"
    , Just ["foo"]                    @=? capture "*.html" "foo.html"
    , Nothing                         @=? capture "*.html" "foo/bar.html"
    , Just ["foo" </> "bar"]          @=? capture "**.html" "foo/bar.html"
    , Just ["foo" </> "bar", "wut"]   @=? capture "**/qux/*" "foo/bar/qux/wut"
    , Just ["lol", "fun" </> "large"] @=? capture "*cat/**.jpg" "lolcat/fun/large.jpg"
    , Nothing                         @=? capture "\\*.jpg" "foo.jpg"
    , Just ["xyz","42"]               @=? capture (fromRegex "cat-([a-z]+)/foo([0-9]+).jpg") "cat-xyz/foo42.jpg"
    ]


--------------------------------------------------------------------------------
matchesTests :: [TestTree]
matchesTests = fromAssertions "matches"
    [ True  @=? matches (fromList ["foo.markdown"]) "foo.markdown"
    , False @=? matches (fromList ["foo"]) (setVersion (Just "x") "foo")
    , True  @=? matches (fromVersion (Just "xz")) (setVersion (Just "xz") "bar")
    , True  @=? matches (fromRegex "^foo/[^x]*$") "foo/bar"
    , False @=? matches (fromRegex "^foo/[^x]*$") "foo/barx"
    , True  @=? matches (complement "foo.markdown") "bar.markdown"
    , False @=? matches (complement "foo.markdown") "foo.markdown"
    , True  @=? matches ("foo" .||. "bar") "bar"
    , False @=? matches ("bar" .&&. hasNoVersion) (setVersion (Just "xz") "bar")
    ]


--------------------------------------------------------------------------------
-- Ensure that `fromFilePath` and `toFilePath` are inverses of each other (#791)
filepathConversionProp :: Q.Property
filepathConversionProp 
    = Q.forAll genFilePath 
    $ \fp -> toFilePath (fromFilePath fp) `equalFilePath` fp
    where
        genFilePath 
            = Q.listOf1 (Q.elements $ ['a'..'z'] <> pathSeparators) 
                `Q.suchThat` 
                isValid