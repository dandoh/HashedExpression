module SimplifyEval.OneRSpec where

import Commons
import Data.Map.Strict
import Data.Maybe (fromJust)
import HashedExpression
import HashedInterp
import HashedOperation hiding (product, sum)
import qualified HashedOperation
import HashedPrettify
import HashedSimplify
import HashedUtils
import Prelude hiding
    ( (*)
    , (+)
    , (-)
    , (/)
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
    , sum
    , tan
    , tanh
    )
import Test.Hspec
import Test.QuickCheck

-- |
--
prop_SimplifyThenEval :: SuiteOneR -> Bool
prop_SimplifyThenEval (SuiteOneR exp valMaps) =
    eval valMaps exp ~= eval valMaps (simplify exp)
-- |
--
prop_Add :: SuiteOneR -> SuiteOneR -> (Bool, Bool, Bool) -> Bool
prop_Add (SuiteOneR exp1 valMaps1) (SuiteOneR exp2 valMaps2) (simplify1, simplify2, simplifySum) =
    eval valMaps exp1' + eval valMaps exp2' ~= eval valMaps expSum'
  where
    valMaps = mergeValMaps valMaps1 valMaps2
    exp1'
        | simplify1 = simplify exp1
        | otherwise = exp1
    exp2'
        | simplify2 = simplify exp2
        | otherwise = exp2
    expSum'
        | simplifySum = simplify (exp1 + exp2)
        | otherwise = exp1 + exp2

prop_Multiply :: SuiteOneR -> SuiteOneR -> (Bool, Bool, Bool) -> Bool
prop_Multiply (SuiteOneR exp1 valMaps1) (SuiteOneR exp2 valMaps2) (simplify1, simplify2, simplifyMul) =
    if lhs ~= rhs
        then True
        else error
                 (prettify exp1' ++
                  " * " ++
                  prettify exp2' ++ " not ~= " ++ prettify expMul' ++ " ----- " ++ show lhs ++ " " ++ show rhs ++ " " ++ show valMaps)
  where
    valMaps = mergeValMaps valMaps1 valMaps2
    exp1'
        | simplify1 = simplify exp1
        | otherwise = exp1
    exp2'
        | simplify2 = simplify exp2
        | otherwise = exp2
    expMul'
        | simplifyMul = simplify (exp1 * exp2)
        | otherwise = exp1 * exp2
    lhs = eval valMaps exp1' * eval valMaps exp2'
    rhs = eval valMaps expMul'

prop_AddMultiply :: SuiteOneR -> Bool
prop_AddMultiply (SuiteOneR exp valMaps) =
    eval valMaps (simplify (exp + exp)) ~=
    eval valMaps (simplify (const 2 *. exp))

spec :: Spec
spec =
    describe "simplify & eval property for One R" $ do
        specify "evaluate must equals simplify then evaluate " $
            property prop_SimplifyThenEval
        specify "prop_Add" $ property prop_Add
        specify "prop_Multiply" $ property prop_Multiply
        specify "prop_AddMultiply" $ property prop_AddMultiply