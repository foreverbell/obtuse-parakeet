module TexElem (
  TexElem(..)
, texify
) where

import qualified Data.Text.Lazy as T
import           Data.Text.Lazy (Text)
import           Text.Printf (printf)

build :: Int -> String -> String
build f = printf "\\%s{%s}" (fonts !! f)
  where
    fonts = [ 
      "Huge", "huge", 
      "LARGE", "Large", "large", 
      "normalsize", "small", "footnotesize", "scriptsize", "tiny" ]

data TexElem = Line
             | Break
             | Lit String
             | Kanji String [String] [String]  -- kanji, hiragana(?), romaji
             | Hiragana String String      -- hiragana, romaji
             | Katakana String String      -- katakana, romaji
             deriving (Show)

-- map over list but head element
map' f (x:xs) = x : map f xs

texify :: TexElem -> Text
texify doc = case doc of
  Line         -> T.pack $ " \\\\ \n"
  Break        -> T.pack $ "\\, "
  Lit s        -> T.pack $ build mainFont s ++ " "
  Kanji k h r  -> T.pack $ printf "\\ruby{%s%s}{%s} " (build mainFont k) (build rubyFont ("(" ++ concat h ++ ")")) (build romajiFont (concat (map' ((:) '-') r)))
  Hiragana h r -> T.pack $ printf "\\ruby{%s}{%s} " (build mainFont h) (build romajiFont r)
  Katakana k r -> T.pack $ printf "\\ruby{%s}{%s} " (build mainFont k) (build romajiFont r)
  where 
    mainFont = 4
    rubyFont = 6
    romajiFont = 5
