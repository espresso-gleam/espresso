import gleam/json.{array, int, null, object, string}
import gleam/option.{None, Option}

pub type Cat {
  Cat(name: String, lives: Int, flaws: Option(String), nicknames: List(String))
}

pub fn new(name: String) -> Cat {
  Cat(name, 9, None, [])
}

pub fn encode(cat: Cat) {
  object([
    #("name", string(cat.name)),
    #("lives", int(cat.lives)),
    #("flaws", null()),
    #("nicknames", array(cat.nicknames, of: string)),
  ])
}
