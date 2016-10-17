module Tests exposing (..)

import Dict exposing (Dict)

import Purememo exposing (purememo, purememoExplicit)
import Test exposing (..)
import Expect
import String


all : Test
all =
    describe "Purememo"
        [ describe "purememo"
            [
            --test "Factorials" <|
            --    \() ->
            --        Expect.equal
            --            (snd <| memofac (4, Dict.empty))
            --            (Dict.fromList
            --                [ (1, 2)
            --                ]
            --            )
            ]
        , describe "purememoExplicit"
            [ test "Fibonacci explicit" <|
                \() ->
                    Expect.equal (fib 50) 12586269025
            , test "Fibonacci internals" <|
                \() ->
                    Expect.equal
                        (List.foldl (\n d -> snd <| memofib (n, d)) Dict.empty [0..5])
                        (Dict.fromList
                            [ (0, 0)
                            , (1, 1)
                            , (2, 1)
                            , (3, 2)
                            , (4, 3)
                            , (5, 5)
                            ]
                        )
            ]
        ]

memofib =
    let
        fibX n d =
          if n == 0 then 0
          else if n == 1 then 1
          else
            let
              x = fst <| memofib (n - 1, d)
              y = fst <| memofib (n - 2, d)
            in
              x + y
    in purememoExplicit fibX

fib n =
  let
    iterations = List.foldl (\n d -> snd <| memofib (n, d)) Dict.empty [2..n]
  in
    case Dict.get n iterations of
      Just val -> val
      Nothing -> Debug.crash (toString iterations)
