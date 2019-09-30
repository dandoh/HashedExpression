{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module RecoverKSpace.RecoverKSpace where

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
import Graphics.EasyPlot
import HashedCollect
import HashedPlot
import HashedSolver
import HashedToC (singleExpressionCProgram)
import HashedUtils
import HashedVar
import Test.Hspec
import ToF.VelocityGenerator

directory :: FilePath
directory = "app/RecoverKSpace/data/"

--smilingFaceProblem :: IO ()
--smilingFaceProblem = do
--    let [x, mask, im, re] =
--            map (variable2D @128 @128) ["x", "mask", "im", "re"]
--        one = constant2D @128 @128 1
--        zero = constant2D @128 @128 0
--    let objectiveFunction =
----            norm2square ((mask +: zero) * (ft x - (re +: im)))
--            norm2square (ft x)
--    let valMap =
--            fromList
--                [ ("mask", V2DFile HDF5 "mask.h5")
--                , ("re", V2DFile HDF5 "re.h5")
--                , ("im", V2DFile HDF5 "im.h5")
--                , ("x", V2D $ listArray ((0, 0), (127, 127)) $ repeat 21)
--                ]
--        vars = ["x"]
--    let constraint = 
--            BoxConstraint 
--                [ ("x", LowerBound $ V2DFile HDF5 "x_lb.h5")
--                , ("x", UpperBound $ V2DFile HDF5 "x_ub.h5")
--                ]
--    let problem = constructProblem objectiveFunction vars constraint
--    print problem
--    case generateProblemCode valMap problem of
--        Invalid str -> putStrLn str
--        Success proceed -> proceed "algorithms/lbfgs-b"
smilingFaceProblem :: IO ()
smilingFaceProblem = do
    let x = variable2D @128 @128 "x"
        one = constant2D @128 @128 1
        zero = constant2D @128 @128 0
    let objectiveFunction = norm2square x
    let valMap = fromList [("x", V2D $ listArray ((0, 0), (127, 127)) $ repeat 21)]
        vars = ["x"]
    let constraint =
            BoxConstraint
                [ ("x", LowerBound $ V2DFile HDF5 "x_lb.h5")
                , ("x", UpperBound $ V2DFile HDF5 "x_ub.h5")
                ]
    let problem = constructProblem objectiveFunction vars constraint
    print problem
    case generateProblemCode valMap problem of
        Invalid str -> putStrLn str
        Success proceed -> proceed "algorithms/lbfgs-b-c"
