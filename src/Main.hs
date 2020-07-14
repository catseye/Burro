module Main where

import System.Environment
import Language.Burro
import qualified Language.Burro.Debugger as Debugger

main = do
    args <- getArgs
    case args of
        ["run", fileName] -> do
            c <- readFile fileName
            burroText <- readFile fileName
            putStrLn $ show $ interpret burroText
        ["debug", fileName] -> do
            c <- readFile fileName
            burroText <- readFile fileName
            state <- Debugger.interpret burroText
            putStrLn $ show $ state
        _ -> do
            putStrLn "Usage: burro (run|debug) <filename.burro>"
