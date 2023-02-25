module Main where

import Haste.DOM (withElems, getValue, setProp)
import Haste.Events (onEvent, MouseEvent(Click))

import Language.Burro.Definition (interpret)


main = withElems ["prog", "result", "run-button"] driver

driver [progElem, resultElem, runButtonElem] =
    onEvent runButtonElem Click $ \_ -> do
        Just prog <- getValue progElem
        setProp resultElem "textContent" $ show $ interpret prog
