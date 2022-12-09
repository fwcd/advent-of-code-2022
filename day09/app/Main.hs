module Main (main) where

import qualified Data.Set as S
import Data.Maybe (mapMaybe)

data Pos = Pos Int Int
  deriving (Show, Eq, Ord)

zipPos :: (Int -> Int -> Int) -> Pos -> Pos -> Pos
zipPos f (Pos i1 j1) (Pos i2 j2) = Pos (f i1 i2) (f j1 j2)

norm :: Pos -> Int
norm (Pos i j) = max (abs i) (abs j)

dist :: Pos -> Pos -> Int
dist (Pos i1 j1) (Pos i2 j2) = norm $ Pos (i2 - i1) (j2 - j1)

range :: Pos -> Pos -> [Pos]
range (Pos i1 j1) (Pos i2 j2) | i1 == i2  = Pos i1 <$> [min j1 j2..max j1 j2]
                              | j1 == j2  = flip Pos j1 <$> [min i1 i2..max i1 i2]
                              | otherwise = error "Can only perform range on axis-aligned positions"

insertAll :: Ord a => [a] -> S.Set a -> S.Set a
insertAll xs s = foldr S.insert s xs

data BridgeState = BridgeState
  { tailPos :: Pos
  , headPos :: Pos
  , visited :: S.Set Pos
  }
  deriving (Show, Eq, Ord)

initialState :: BridgeState
initialState = BridgeState
  { headPos = Pos 0 0
  , tailPos = Pos 0 0
  , visited = S.fromList [Pos 0 0]
  }

pretty :: BridgeState -> String
pretty s = unlines $ [[format (Pos i j) | j <- [j1..j2]] | i <- [i1..i2]]
  where
    ps = (headPos s : tailPos s : S.toList (visited s))
    Pos i1 j1 = foldr1 (zipPos min) ps
    Pos i2 j2 = foldr1 (zipPos max) ps
    format p | p == headPos s         = 'H'
             | p == tailPos s         = 'T'
             | p `S.member` visited s = '#'
             | otherwise              = '.'

data Dir = L | R | U | D
  deriving (Read, Show, Eq, Ord)

data Inst = Inst Dir Int
  deriving (Read, Show, Eq, Ord)

parseInst :: String -> Maybe Inst
parseInst (d:' ':c) = Just $ Inst (read [d]) (read c)
parseInst _ = Nothing

moveHorizontally :: Int -> BridgeState -> BridgeState
moveHorizontally n s = BridgeState { headPos = h', tailPos = t', visited = v' }
  where
    h@(Pos h1 h2) = headPos s
    t@(Pos t1 t2) = tailPos s
    v   = visited s
    v'  = insertAll dv v
    h2' = h2 + n
    t2' = h2' + signum (t2 - h2')
    h' = Pos h1 h2'
    (t', dv) | dist h' t <= 1 = (t, [])
             | otherwise      = (Pos h1 t2', v')
                where v' | h1 == t1  = range t t'
                         | otherwise = range (Pos h1 (t2 + signum n)) t'

-- TODO: Implement moveVertically in terms of moveHorizontally with parameter swapping

moveVertically :: Int -> BridgeState -> BridgeState
moveVertically n s = BridgeState { headPos = h', tailPos = t', visited = v' }
  where
    h@(Pos h1 h2) = headPos s
    t@(Pos t1 t2) = tailPos s
    v   = visited s
    v'  = insertAll dv v
    h1' = h1 + n
    t1' = h1' + signum (t1 - h1')
    h' = Pos h1' h2
    (t', dv) | dist h' t <= 1 = (t, [])
             | otherwise      = (Pos t1' h2, v')
                where v' | h2 == t2  = range t t'
                         | otherwise = range (Pos (t1 + signum n) h2) t'

performInst :: Inst -> BridgeState -> BridgeState
performInst (Inst d n) = case d of
  L -> moveHorizontally (-n)
  R -> moveHorizontally n
  U -> moveVertically (-n)
  D -> moveVertically n

main :: IO ()
main = do
  lines <- lines <$> readFile "resources/input.txt"
  let insts = mapMaybe parseInst lines
      finalState = foldl (flip performInst) initialState insts
  putStrLn $ "Part 1: " ++ show (S.size (visited finalState))
