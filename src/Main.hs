module Main where

import System.Environment
import Language.Burro

main = do
    args <- getArgs
    case args of
        [fileName] -> do
            c <- readFile fileName
            burroText <- readFile fileName
            putStrLn $ show $ interpret burroText
        _ -> do
            putStrLn "Usage: burro <filename.burro>"
