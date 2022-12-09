module Main (main) where

import qualified Data.Set as S
import Data.Maybe (mapMaybe)

data Pos = Pos Int Int

combine :: (Int -> Int -> Int) -> Pos -> Pos -> Pos
combine op (Pos x1 y1) (Pos x2 y2) = Pos (op x1 y1) (op x2 y2)

(+.) :: Pos -> Pos -> Pos
(+.) = combine (+)

(-.) :: Pos -> Pos -> Pos
(-.) = combine (-)

data BridgeState = BridgeState
  { tailPos :: Pos
  , headPos :: Pos
  , visited :: S.Set Pos
  }

data Dir = R | U | L | D
  deriving (Read, Show, Eq, Ord)

data Inst = Inst Dir Int
  deriving (Read, Show, Eq, Ord)

parseInst :: String -> Maybe Inst
parseInst (d:' ':c) = Just $ Inst (read [d]) (read c)
parseInst _ = Nothing

perform :: Inst -> BridgeState -> BridgeState
perform (Inst dir n) = undefined

main :: IO ()
main = do
  lines <- lines <$> readFile "resources/demo.txt"
  let insts = mapMaybe parseInst lines
  mapM_ print insts
