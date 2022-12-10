module Main (main) where

import qualified Data.Set as S
import Data.Maybe (mapMaybe)
import Data.List (elemIndex)

data Pos = Pos Int Int
  deriving (Show, Eq, Ord)

zipPos :: (Int -> Int -> Int) -> Pos -> Pos -> Pos
zipPos f (Pos i1 j1) (Pos i2 j2) = Pos (f i1 i2) (f j1 j2)

norm :: Pos -> Int
norm (Pos i j) = max (abs i) (abs j)

dist :: Pos -> Pos -> Int
dist (Pos i1 j1) (Pos i2 j2) = norm $ Pos (i2 - i1) (j2 - j1)

insertAll :: Ord a => [a] -> S.Set a -> S.Set a
insertAll xs s = foldr S.insert s xs

data BridgeState = BridgeState
  { headKnot  :: Pos
  , tailKnots :: [Pos]
  , visited   :: S.Set Pos
  }
  deriving (Show, Eq, Ord)

initialState :: Int -> BridgeState
initialState n = BridgeState
  { headKnot  = startPos
  , tailKnots = replicate (n - 1) startPos
  , visited   = S.fromList [startPos]
  }
  where startPos = Pos 0 0

pretty :: BridgeState -> String
pretty s = unlines $ [[format (Pos i j) | j <- [j1..j2]] | i <- [i1..i2]]
  where
    ps = (headKnot s : (tailKnots s ++ S.toList (visited s)))
    Pos i1 j1 = foldr1 (zipPos min) ps
    Pos i2 j2 = foldr1 (zipPos max) ps
    format p = case elemIndex p (tailKnots s) of
      Just i                           -> head $ show (i + 1)
      Nothing | p == headKnot s        -> 'H'
              | p `S.member` visited s -> '#'
              | otherwise              -> '.'

data Dir = L | R | U | D
  deriving (Read, Show, Eq, Ord)

data Inst = Inst Dir Int
  deriving (Read, Show, Eq, Ord)

parseInst :: String -> Maybe Inst
parseInst (d:' ':c) = Just $ Inst (read [d]) (read c)
parseInst _ = Nothing

moveHead :: Dir -> Pos -> Pos
moveHead d (Pos i j) = case d of
  L -> Pos i (j - 1)
  R -> Pos i (j + 1)
  U -> Pos (i - 1) j
  D -> Pos (i + 1) j

moveTail :: Pos -> Pos -> Pos
moveTail h@(Pos h1 h2) t@(Pos t1 t2) | dist h t <= 1 = t
                                     | otherwise     = Pos (t1 + signum (h1 - t1)) (t2 + signum (h2 - t2))

moveTails :: Pos -> [Pos] -> [Pos]
moveTails h ts = case ts of
  []      -> []
  t : ts' -> t' : moveTails t' ts'
    where t' = moveTail h t

moveInst :: Inst -> Pos -> [Pos] -> (Pos, [Pos], [Pos])
moveInst (Inst d n) h ts | n == 0    = (h, ts, [last ts])
                         | otherwise = let h'  = moveHead d h
                                           ts' = moveTails h' ts
                                           (h'', ts'', dv) = moveInst (Inst d (n - 1)) h' ts'
                                       in (h'', ts'', last ts' : dv)

performInst :: Inst -> BridgeState -> BridgeState
performInst inst s = s'
  where (h', ts', dv) = moveInst inst (headKnot s) (tailKnots s)
        s' = BridgeState h' ts' $ insertAll dv $ visited s

main :: IO ()
main = do
  lines <- lines <$> readFile "resources/input.txt"
  let insts = mapMaybe parseInst lines
      finalState n = foldl (flip performInst) (initialState n) insts
      solve n = S.size (visited (finalState n))
  putStrLn $ "Part 1: " ++ show (solve 2)
  putStrLn $ "Part 2: " ++ show (solve 10)
