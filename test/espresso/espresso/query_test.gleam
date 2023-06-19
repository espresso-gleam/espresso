import espresso/espresso/query
import gleam/option.{None, Some}
import gleeunit/should
import espresso/espresso/request

pub fn query_present_test() {
  request.new()
  |> request.set_query([#("something", "test")])
  |> query.get("something")
  |> should.equal(Some("test"))
}

pub fn query_not_present_test() {
  request.new()
  |> request.set_query([])
  |> query.get("something")
  |> should.equal(None)
}
