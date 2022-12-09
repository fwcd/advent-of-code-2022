module Main (main) where

main :: IO ()
main = do
  lines <- lines <$> readFile "resources/demo.txt"
  mapM_ putStrLn lines
