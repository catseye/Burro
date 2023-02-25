module Language.Burro.Debugger where

import System.Environment

import Language.Burro.Definition hiding (exec, run, interpret)


dump :: Burro -> State -> IO ()
dump p s = do
    putStrLn (show s ++ " ::: " ++ show p)

exec :: Burro -> State -> IO State
exec (Seq a b) s = do
    s' <- exec a s
    s'' <- exec b s'
    return s''
exec Null s = do
    dump Null s
    return s
exec ToggleHalt s@(State dat stack halt) = do
    dump ToggleHalt s
    return $ State dat stack (not halt)
exec Inc s@(State dat stack halt) = do
    dump Inc s
    return $ State (inc dat) stack halt
exec Dec s@(State dat stack halt) = do
    dump Dec s
    return $ State (dec dat) stack halt
exec GoLeft s@(State dat stack halt) = do
    dump GoLeft s
    return $ State (left dat) stack halt
exec GoRight s@(State dat stack halt) = do
    dump GoRight s
    return $ State (right dat) stack halt
exec p@(Test thn els) s@(State dat stack halt) = do
    dump p s
    let x = get dat
    let (dat', stack') = swap dat stack
    let stack'' = right (set stack' (0 - (get stack')))
    let f = if x > 0 then thn else if x < 0 then els else Null
    (State dat''' stack''' halt') <- exec f (State dat' stack'' halt)
    let (dat'''', stack'''') = swap dat''' (left stack''')
    return $ State dat'''' stack'''' halt'

run program state = do
    state'@(State dat' stack' halt') <- exec program state
    case halt' of
        False -> run program (State dat' (tape [0]) True)
        True -> return state'

interpret text = run (parse text) newstate
