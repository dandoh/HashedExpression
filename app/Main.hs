{-# LANGUAGE DataKinds #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Data.Array
import Data.Complex
import qualified Data.IntMap.Strict as IM
import Data.Map (empty, fromList, union)
import qualified Data.Set as Set
import HashedDerivative
import HashedExpression
import HashedInterp
import HashedNormalize
import HashedOperation hiding (product, sum)
import qualified HashedOperation
import HashedPrettify
import Prelude hiding
    ( (*)
    , (+)
    , (-)
    , (/)
    , (^)
    , acos
    , acosh
    , asin
    , asinh
    , atan
    , atanh
    , const
    , cos
    , cosh
    , exp
    , log
    , negate
    , product
    , sin
    , sinh
    , sqrt
    , sum
    , tan
    , tanh
    )
import ToF.ToF

import Data.List (intercalate)
import Data.Maybe (fromJust)
import Data.STRef.Strict
import Fruit.Fruit
import Graphics.EasyPlot
import HashedCollect
import HashedPlot
import HashedSolver
import HashedToC (singleExpressionCProgram)
import HashedUtils
import HashedVar
import RecoverKSpace.RecoverKSpace
import Test.Hspec
import ToF.VelocityGenerator

reFT :: (DimensionType d) => Expression d R -> Expression d R
reFT = xRe . ft

imFT :: (DimensionType d) => Expression d R -> Expression d R
imFT = xIm . ft

--
--main = do
--    let exp = norm2square $ reFT . reFT $ x1
--    showExp . collectDifferentials . exteriorDerivative allVars $ exp--    let x = var "x"
--    let exp = huber 1 x
--        fun = Function exp empty
--    plot1VariableFunction fun "haha"
main = easyFruitProblem
