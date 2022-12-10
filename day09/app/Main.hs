module Main (main) where

import qualified Data.Set as S
import Data.Maybe (mapMaybe)

data Pos = Pos Int Int
  deriving (Show, Eq, Ord)

zipPos :: (Int -> Int -> Int) -> Pos -> Pos -> Pos
zipPos f (Pos i1 j1) (Pos i2 j2) = Pos (f i1 i2) (f j1 j2)

norm :: Pos -> Int
norm (Pos i j) = max (abs i) (abs j)

swap :: Pos -> Pos
swap (Pos i j) = Pos j i

dist :: Pos -> Pos -> Int
dist (Pos i1 j1) (Pos i2 j2) = norm $ Pos (i2 - i1) (j2 - j1)

range :: Pos -> Pos -> [Pos]
range (Pos i1 j1) (Pos i2 j2) | i1 == i2  = Pos i1 <$> [min j1 j2..max j1 j2]
                              | j1 == j2  = flip Pos j1 <$> [min i1 i2..max i1 i2]
                              | otherwise = error "Can only perform range on axis-aligned positions"

insertAll :: Ord a => [a] -> S.Set a -> S.Set a
insertAll xs s = foldr S.insert s xs

data BridgeState a = BridgeState
  { headPos :: Pos
  , tailPos :: a
  , visited :: S.Set Pos
  }
  deriving (Show, Eq, Ord)

initialState1 :: BridgeState Pos
initialState1 = BridgeState
  { headPos = Pos 0 0
  , tailPos = Pos 0 0
  , visited = S.fromList [Pos 0 0]
  }

initialState2 :: Int -> BridgeState [Pos]
initialState2 len = BridgeState
  { headPos = Pos 0 0
  , tailPos = take len $ repeat $ Pos 0 0
  , visited = S.fromList [Pos 0 0]
  }

pretty :: BridgeState Pos -> String
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

moveHead :: Dir -> Pos -> Pos
moveHead d (Pos i j) = case d of
  L -> Pos i (j - 1)
  R -> Pos i (j + 1)
  U -> Pos (i - 1) j
  D -> Pos (i + 1) j

moveTail :: Pos -> Pos -> Pos
moveTail h@(Pos h1 h2) t@(Pos t1 t2) | dist h t <= 1 = t
                                     | otherwise     = Pos (t1 + signum (h1 - t1)) (t2 + signum (h2 - t2))

move :: Dir -> Pos -> Pos -> (Pos, Pos)
move d h t = (h', t')
  where h' = moveHead d h
        t' = moveTail h' t

moveInst :: Inst -> Pos -> Pos -> (Pos, Pos, [Pos])
moveInst (Inst d n) h t | n == 0    = (h, t, [t])
                        | otherwise = let (h', t')        = move d h t
                                          (h'', t'', dv') = moveInst (Inst d (n - 1)) h' t'
                                      in (h'', t'', t' : dv')

performInst1 :: Inst -> BridgeState Pos -> BridgeState Pos
performInst1 inst s = s'
  where (h', t', dv) = moveInst inst (headPos s) (tailPos s)
        s' = BridgeState h' t' $ insertAll dv $ visited s

-- performInst2 :: Inst -> BridgeState [Pos] -> BridgeState [Pos]
-- performInst2 inst s = BridgeState { headPos = h', tailPos = ts', visited = v' }
--   where 
--     ((h':ts'), v') = foldl f (headPos s, [], visited s) (tailPos s)
--     f (acc, v) p = 

main :: IO ()
main = do
  lines <- lines <$> readFile "resources/demo-single.txt"
  let insts = mapMaybe parseInst lines
      finalState = foldl (flip performInst1) initialState1 insts
  putStrLn $ "Part 1: " ++ show (S.size (visited finalState))
