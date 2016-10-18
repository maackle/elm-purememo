# Pure Memoization in Elm

This package provides memoization helpers for Elm.

**This is a work in progress**. It's not a full-fledged elm package (yet). If you find this interesting or useful, please give me your feedback! I'm new to Elm, and I'm sure there are much cleaner ways of doing things. This is just a starting point.

There are some tests which show the internals in a little more detail, runnable with [node-test-runner](https://github.com/rtfeldman/node-test-runner) via `elm-test`

## How it works under the hood

Internally, Purememo takes a function like this:

    fn : a -> b

And turns it into this:

    memoized : (a, Dict comparable b) -> (b, Dict comparable b)

In order to create such a beast, you supply two values:

1. a function of type `a -> comparable`, which turns your function's inputs into Dict keys
2. `fn`, the function itself you want to memoize

This memoized function is wrapped in a `Memo` type, which means you never interact with it explicitly, and which also allows some convenient functions for doing more complex computations.

## How to use it

You can create a structure Purememo can work with like so:

```elm
import Purememo exposing (purememo)

memoized = purememo toKey fn
```

Where

```elm
fn : a -> b
```

is the function you need memoized, and
```elm
toKey : a -> comparable
```

is a function that turns your function inputs into `comparable` type. (Often this will simply be `identity`. More on this later.)

### A contrived example

Here's an illustrative example. It shows the most basic usage, but in reality there are helpers to make this a lot easier.

```elm

contrivedYetExpensiveComputation : Float -> Float
contrivedYetExpensiveComputation val = List.foldl (+) val [1..1000000]

memoized = purememo identity contrivedYetExpensiveComputation
d0 = Dict.empty
(x, d1) = Purememo.apply memoized d0 1  -- == 50005001
(y, d2) = Purememo.apply memoized d1 2  -- == 50005002
(z, d3) = Purememo.apply memoized d2 1  -- this time, the cached value 50005001 will be used
```

In this example, `x` and `y` have to be computed, but `z` will use the cached value of `x`. If future computations need to be done elsewhere, you pass the last memoization state `d3` into the next computation.

### The same thing, only easier

The above example was cumbersome because we had to manually carry the memoization state from the previous computation into the next one. For this kind of calculation, just use `Purememo.thread`:

```elm
memoized = purememo identity contrivedYetExpensiveComputation
(vals, d) = Purememo.thread Dict.empty [1, 2, 1]
```

Here, `vals` is the same as `[x, y, z]` from the prior example, and `d` is the same as `d3`

### Multi-argument functions

Purememo only supports unary functions. However if your function takes multiple arguments, just pack them into a tuple before shipping them to be memoized:

```elm
fn = (+)
memoized = purememo identity <| \(x, y) -> fn x y
```

Remember that a tuple of comparables is still comparable, so it will all work out in the end.

### Non-comparable values

Since the memoization is backed by a `Dict`, the keys need to be comparable. In the previous examples, the memoized function already takes a comparable type, `Float`, as its argument, which is why we used `identity` as the first. If the type is not comparable, simply make it so with a getter function as the first argument to `purememo`.

```elm
type alias Restaurant =
  { id : Int
  , menu : List String
  }

numItems restaurant = length restaurant.menu

memoized = purememo .id numItems
```

### Recursive and other beastly functions

In the previous examples, the functions we memoized were blissfully unaware of the fact that they were being memoized. `purememo` just made it work. Sometimes your function needs to be aware of its memoization though, and needs access to the state. In this case, you can use `purememoExplicit`.

Instead of taking a `f : a -> b` like `purememo`, `purememoExplicit` takes a

```elm
f : a d -> b
```

Where `d` is the memoization state

```elm

memofac : Memo Int Int Int
memofac =
  let
    fac n d =  -- note that this takes both the value and the memoization dict
      if n == 0 then 0
      else if n == 1 then 1
      else n * (fst <| Purememo.apply memofac d (n - 1))
  in
    purememoExplicit identity fac

-- memofac only works one level deep, so we have to build up the values incrementally.
factorial n =
    Purememo.thread memofac Dict.empty [1..n]
    |> snd
    |> Dict.get n
    |> Maybe.withDefault 0  -- This will never actually happen
```

TODO: more explanation

## Similar solutions

There are some other packages which deal with memoization:

- [elm-lazy](https://github.com/maxsnew/lazy), which natively (statefully) memoizes zero-arity functions (thunks)
- [elm-memo](https://github.com/jvoigtlaender/elm-memo), which allows a batch of lazy evaluations to be specified up-front, seamlessly returning the memoized value when possible. (This is backed by elm-lazy, hence is also stateful)

The particular motivation for this package is that `elm-memo` works well when you know what values your function will take beforehand, but it doesn't allow you to use the results of subsequent unknown computations later on. Additionally, you can't manage your backing state, cleaning up unneeded values, etc.

In contrast, `purememo` takes the pure approach. Each purememo calculation returns the result along with a dict which represents the updated memoization state. You have to keep track of this dict and pass it into your memoized function for future calculations.


## TODO

- Clean up and standardize the interface. Probably `apply memoized d n` will become `apply memoized (n, d)`
- Make piping stuff around easier
- Figure out how to do truly recursive memoization (e.g. https://wiki.haskell.org/Memoization)
- More functions on `Memo`
- More tests
- Cooler/more relevant examples
