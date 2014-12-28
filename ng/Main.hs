{-# LANGUAGE NoImplicitPrelude, OverloadedStrings #-}

module Main where

import BasePrelude
import Data.Text (Text)
import Lucid

newtype Title = Title Text
newtype ID = ID Integer

data Story =
  Story { _storyID :: ID
        , _storyTitle :: Title
        , _storyURL :: Text
        , _storyBody :: Text
        , _storyWhisks :: Integer
        }

data Comment =
  Comment { _commentID :: ID
          , _commentBody :: Text
          , _commentParentID :: ID
          , _commentStoryID :: ID
          }

header :: Html ()
header =
  do
    with section_
      [id_ "header"]
      (do headerleft
          headerright)
  where
    headerleft =
      ul_ (do favicon
              link "/" "Home"
              link "/hottest" "Spiciest"
              link "/comments" "Talk of the Town"
              link "/search" "Search")
    headerright =
      ul_ (do link "/threads" "Your Replies"
              link "/messages" "Your Messages"
              link "/settinsg" "hao (155)"
              link "/logout" "^D")
    favicon =
      li_ (p_ "[barn]")
    link path text =
      li_ (with a_ [href_ path] text)

home :: Html ()
home =
  html_ (do head_ (do title_ "Barnacles")
            body_ (do header))

main :: IO ()
main =
  renderToFile "index.html" home
