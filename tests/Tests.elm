module Tests exposing (..)

import Dict exposing (Dict)

import Purememo exposing (Memo, purememo, purememoExplicit)
import Test exposing (..)
import Expect
import String


all : Test
all =
    describe "Purememo"
        [ describe "purememo"
            [ test "repeat" <|
                \() ->
                    let
                        doubler = (purememo identity ((*) 2))
                        actual = Purememo.repeat doubler Dict.empty 4 1
                        expected =
                            ( 16
                            , Dict.fromList
                                [ (1, 2)
                                , (2, 4)
                                , (4, 8)
                                , (8, 16)
                                ]
                            )
                    in
                        Expect.equal actual expected
            , test "thread" <|
                \() ->
                    let
                        getLength = (purememo identity String.length)
                        actual = Purememo.thread getLength Dict.empty ["one", "two", "three"]
                        expected =
                            ( [3, 3, 5]
                            , Dict.fromList
                                [ ("one", 3)
                                , ("two", 3)
                                , ("three", 5)
                                ]
                            )
                    in
                        Expect.equal actual expected
            ]
        , describe "purememoExplicit"
            [ test "Fibonacci" <|
                \() ->
                    Expect.equal (fib 50) 12586269025
            , test "Fibonacci internals" <|
                \() ->
                    Expect.equal
                        (List.foldl (\n d -> snd <| Purememo.apply memofib d n) Dict.empty [0..5])
                        (Dict.fromList
                            [ (0, 0)
                            , (1, 1)
                            , (2, 1)
                            , (3, 2)
                            , (4, 3)
                            , (5, 5)
                            ]
                        )
            , test "Factorials" <|
                \() ->
                    Expect.equal
                        (Purememo.apply memofac Dict.empty 4)
                        (24, Dict.fromList [(4, 24)])
            ]
        ]


memofac : Memo Int Int Int
memofac =
  let
    fac n d =
      if n == 0 then 0
      else if n == 1 then 1
      else n * (fst <| Purememo.apply memofac d (n - 1))
  in
    purememoExplicit identity fac


memofib =
    let
        fibX n d =
          if n == 0 then 0
          else if n == 1 then 1
          else
            let
              x = fst <| Purememo.apply memofib d (n - 1)
              y = fst <| Purememo.apply memofib d (n - 2)
            in
              x + y
    in purememoExplicit identity fibX

fib n =
  let
    iterations = List.foldl (\n d -> snd <| Purememo.apply memofib d n) Dict.empty [2..n]
  in
    case Dict.get n iterations of
      Just val -> val
      Nothing -> Debug.crash (toString iterations)
