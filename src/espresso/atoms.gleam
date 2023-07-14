import gleam/dynamic

pub type ElementAtom {
  Raw
  Text
  Element
}

@external(erlang, "espresso_atoms", "decode_atom")
pub fn decode(a: dynamic.Dynamic) -> Result(
  ElementAtom,
  List(dynamic.DecodeError),
)
