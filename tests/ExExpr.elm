module ExExpr exposing (..)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Expr exposing (..)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


testParseTerm : String -> Term -> Test
testParseTerm str term =
    test str <|
        \_ -> Expect.equal ( Ok term ) ( parse str )


testParseFail : String -> Test
testParseFail str =
    test str <|
        \_ -> Expect.err ( parse str )


testEval : String -> Term -> Dict String Int -> Maybe Int -> Test
testEval str trm dict expected =
    test str <|
        \_ -> Expect.equal ( eval dict trm ) expected


testDict : Dict String Int
testDict =
    [ ( "a", 1 )
    , ( "b", 2 )
    , ( "c", 3 )
    , ( "d", 4 )
    , ( "e", 5 )
    , ( "f", 6 )
    ]
    |> Dict.fromList


suite : Test
suite = describe "Test Expr"
    [ describe "expr parser"
        [ describe "parseが成功"
            [ testParseTerm "1" ( Con 1 )
            , testParseTerm "1 + x" ( App Add (Con 1) (Var "x") )
            , testParseTerm "1 - x" ( App Sub (Con 1) (Var "x") )
            , testParseTerm
                "y % 4 + 2 / x"
                ( App Add (App Mod (Var "y") (Con 4)) (App Div (Con 2) (Var "x")) )
            , testParseTerm
                "dp[i][j]"
                ( Dp (Var "i") (Var "j") )
            , testParseTerm
                "dp[i*2][j+1] % i + 2 * dp[i][j-1]"
                ( App Add
                    ( App Mod (Dp (App Mul (Var "i") (Con 2)) (App Add (Var "j") (Con 1))) (Var "i") )
                    ( App Mul (Con 2) (Dp (Var "i") (App Sub (Var "j") (Con 1))) )
                )
            ]
        , describe "parseが失敗"
            [ testParseFail "+1"
            , testParseFail "1+"
            , testParseFail "1%"
            ]
        ]
    , describe "eval"
        [ describe "evalが成功する"
            [ testEval "10" ( Con 10 ) testDict ( Just 10 )
            , testEval "a => 1" ( Var "a" ) testDict ( Just 1 )
            , testEval "b + 1 => 2 + 1 => 3" ( App Add (Var "b") (Con 1) ) testDict ( Just 3 )
            , testEval "c + d * 2 - e => 3 + 4 * 2 - 5 => " ( App Sub ( App Add ( Var "c" ) ( App Mul ( Var "d" ) ( Con 2 ) )) ( Var "e" ) ) testDict ( Just 6 )
            , testEval "f % 4 => 2" ( App Mod ( Var "f" ) ( Con 4 ) ) testDict ( Just 2 )
            , testEval "dpテーブルは未実装で0になる" ( Dp (Con 0) (Con 0) ) testDict ( Just 0 )
            ]
        , describe "evalが失敗する"
            [ testEval "xは存在しない" ( Var "x" ) testDict Nothing
            , testEval "a + y + b, yは存在しない" ( App Add (Var "a") ( App Add (Var "y") (Var "b")) ) testDict Nothing
            ]
        ]
    ]