//// Utility module for dealing with "OrderedMaps" which are lists
//// of key/value pairs that are ordered by the key. It should have
//// a similar interface to Map so you can swap them in and out,
//// though not all the functions are implemented.
//// 
//// Since it is based on lists it will not be as efficient as maps but
//// for our use case we only care about the ordering.

import gleam/list
import gleam/option.{Option}

pub type OrderedMap(a, b) =
  List(#(a, b))

pub fn get(map: OrderedMap(a, b), key: a) -> Option(b) {
  map
  |> list.key_find(key)
  |> option.from_result()
}

pub fn insert(map: OrderedMap(a, b), key: a, value: b) -> OrderedMap(a, b) {
  list.key_set(map, key, value)
}

pub fn update(
  map: OrderedMap(a, b),
  key: a,
  fun: fn(Option(b)) -> b,
) -> OrderedMap(a, b) {
  map
  |> get(key)
  |> fun
  |> insert(map, key, _)
}

pub fn new() -> OrderedMap(a, b) {
  []
}

pub fn fold(
  map: OrderedMap(k, v),
  initial: acc,
  fun: fn(acc, k, v) -> acc,
) -> acc {
  case map {
    [] -> initial
    [#(k, v), ..rest] -> fold(rest, fun(initial, k, v), fun)
  }
}
