module Parakeet.Parser.Parser (
  parse
) where

import           Control.Monad.Parakeet (Parakeet, env, throw)
import           Data.Char (isSpace)
import           Data.Char.Extra (toLower)
import           Data.List (isPrefixOf, zipWith4)
import           Text.Parsec hiding (parse)

import           Parakeet.Types.FlatToken (FlatToken(..))
import qualified Parakeet.Types.Lexeme as Lexeme
import           Parakeet.Types.Meta (Meta(..), Author(..), Title(..))
import qualified Parakeet.Types.Token as Token
import           Parakeet.Types.Options (Options(..), FuriganaFormat(..))
import           Parakeet.Parser.Stage0 (stage0)
import           Parakeet.Parser.Stage1 (stage1)
import           Parakeet.Parser.Stage2 (stage2)

setLine l = do
  pos <- getPosition
  setPosition $ setSourceLine pos l

parseLine :: Line -> Line -> String -> String -> Parakeet [FlatToken]
parseLine lj lr j r = do
  keeplv <- env optKeepLV
  let stage2' = if keeplv then stage2 else return
  jf <- env optJInputFile
  rf <- env optRInputFile
  wd <- test =<< runParserT (setLine lj >> stage0) () jf j
  tk <- stage2' =<< test =<< runParserT (setLine lr >> stage1) wd rf (toLower r)
  sequence $ flatten <$> tk
  where test = either (throw . show) return

extractMeta :: (String, String) -> Maybe (String, String) -> Parakeet Meta
extractMeta (j1, j2) (Just (r1, r2)) = do
  title <- if null r1 then return [Lit j1] else init <$> parseLine 1 1 j1 r1
  author <- if null r2 then return [Lit j2] else init <$> parseLine 2 2 j2 r2
  let authorLit = if null r2 then [Lit j2] else [Lit j2, Lit ("(" ++ r2 ++ ")")]
  return $ Meta (Title title, Author (author, authorLit))
extractMeta (j1, j2) Nothing = return $ Meta (Title [Lit j1], Author ([Lit j2], [Lit j2]))

trimFront :: ([String], Line) -> ([String], Line)
trimFront (ls, l) = (drop emptys ls, l + emptys)
  where 
    emptys = length $ takeWhile isEmpty ls
    isEmpty = not . any (not . isSpace)

flatten :: Token.Token -> Parakeet FlatToken
flatten token = 
  case token of
       Token.Line -> return Line
       Token.Break -> return Break
       Token.Lit l -> return $ Lit (Lexeme.unwrap l)
       Token.Hiragana h r -> return $ Hiragana (Lexeme.unwrap h) (map Lexeme.unwrap r)
       Token.Katakana k r -> return $ Katakana (Lexeme.unwrap k) (map Lexeme.unwrap r)
       Token.Kanji k hs ks r -> do
          let romaji = map Lexeme.unwrap r
          furigana <- env optFurigana
          let kana = case furigana of
                InKatakana -> map Lexeme.unwrap ks
                InHiragana -> map Lexeme.unwrap hs
          return $ Kanji (Lexeme.unwrap k) kana romaji

-- TODO: refactor `parse` in a monadic way
parse :: Parakeet (Maybe Meta, [FlatToken])
parse = do
  (j, r) <- env optContent
  let (js, offsetJ) = trimFront (lines j, 1)
  let (rs, offsetR) = trimFront (lines r, 1)
  let (js0, js1, rs0, rs1) = (js!!0, js!!1, rs!!0, rs!!1)
  ignoreMeta <- env optNoMeta
  let hasMetaJ = not ignoreMeta && hasMeta js
  let hasMetaR = not ignoreMeta && hasMetaJ && hasMeta rs 
  let (js', offsetJ') = trimFront $ if hasMetaJ then (drop 2 js, offsetJ + 2) else (js, offsetJ)
  let (rs', offsetR') = trimFront $ if hasMetaR then (drop 2 rs, offsetR + 2) else (rs, offsetR)
  meta <- if hasMetaJ
    then if hasMetaR
      then Just <$> extractMeta (metaData js0, metaData js1) (Just (metaData rs0, metaData rs1))
      else Just <$> extractMeta (metaData js0, metaData js1) Nothing
    else return Nothing
  tokens <- concat <$> sequence (zipWith4 parseLine [offsetJ' .. ] [offsetR' .. ] js' rs')
  return (meta, tokens)
  where 
    hasMeta f = case f of
      (a:b:_) -> isMetaLine a && isMetaLine b
      _       -> False
    isMetaLine l = "##" `isPrefixOf` l 
    metaData l = dropWhile isSpace $ drop 2 l
