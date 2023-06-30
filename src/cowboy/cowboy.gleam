//// This is a simple wrapper over the erlang cowboy server. It is originall from gleam-lang/cowboy
//// but has been modified to work with espresso.
//// 
//// original source:
//// https://github.com/gleam-lang/cowboy/blob/83e2f20170e4a73e5499238149313f8329a2f41a/src/gleam/http/cowboy.gleam

import espresso/ordered_map.{OrderedMap}
import espresso/request.{Params, Request}
import espresso/response
import espresso/service.{Service}
import espresso/session
import espresso/static.{Static}
import espresso/websocket.{Websocket}
import gleam/dynamic.{Dynamic}
import gleam/erlang/atom
import gleam/erlang/process.{Pid}
import gleam/http.{Header}
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pair
import gleam/result
import gleam/map.{Map}

/// An incoming request that will be handled by the dispatch in gleam_cowboy_native.erl
pub external type CowboyRequest

/// The returned result of cowboy_router:compile
pub external type CowboyRouter

/// A list of routes that will be compiled by cowboy_router:compile
type CowboyRoutes =
  List(#(atom.Atom, List(#(Dynamic, Dynamic, Dynamic))))

/// A Route can either be a service (a function that handles a request and response)
/// or a router which is expanded into a list of services.
pub type Route(req, assigns, session, res) {
  ServiceRoute(Service(req, assigns, session, res))
  RouterRoute(Routes(req, assigns, session, res))
  StaticRoute(String, Static)
  WebsocketRoute(Websocket)
}

/// Routes are the mapping between a path and the route. 
/// For example `/hello` -> `hello_service`
pub type Routes(req, assigns, session, res) =
  OrderedMap(String, Route(req, assigns, session, res))

external type ModuleName

external type CowboyStatic

external type WebsocketModule

external fn erlang_module_name() -> ModuleName =
  "gleam_cowboy_native" "module_name"

external fn erlang_router(CowboyRoutes) -> CowboyRouter =
  "gleam_cowboy_native" "router"

external fn erlang_cowboy_static() -> CowboyStatic =
  "gleam_cowboy_native" "static_module"

external fn erlang_cowboy_websocket() -> WebsocketModule =
  "gleam_websocket_native" "module_name"

/// Takes a list of route structures and compiles them into a cowboy router.
/// 
pub fn router(routes: Routes(req, assigns, session, res)) -> CowboyRouter {
  let underscore = atom.create_from_string("_")

  let cowboy_routes =
    routes
    |> list.map(fn(entry) {
      let #(path, route) = entry
      case route {
        ServiceRoute(service) -> #(
          dynamic.from(path),
          dynamic.from(erlang_module_name()),
          dynamic.from(service_to_handler(service)),
        )
        RouterRoute(routes) -> #(
          dynamic.from(path),
          dynamic.from(router(routes)),
          dynamic.from([]),
        )
        StaticRoute(path, config) -> #(
          dynamic.from(path),
          dynamic.from(erlang_cowboy_static()),
          dynamic.from(config),
        )
        WebsocketRoute(service) -> #(
          dynamic.from(path),
          dynamic.from(erlang_cowboy_websocket()),
          dynamic.from(service),
        )
      }
    })

  let fallback = [
    #(
      dynamic.from(underscore),
      dynamic.from(erlang_module_name()),
      dynamic.from(service_to_handler(fn(_req) { response.send(404, "") })),
    ),
  ]

  erlang_router([#(underscore, list.append(cowboy_routes, fallback))])
}

external fn erlang_start_link(
  router: CowboyRouter,
  port: Int,
) -> Result(Pid, Dynamic) =
  "gleam_cowboy_native" "start_link"

external fn cowboy_reply(
  Int,
  Map(String, Dynamic),
  res,
  CowboyRequest,
) -> CowboyRequest =
  "cowboy_req" "reply"

external fn erlang_get_method(CowboyRequest) -> Dynamic =
  "cowboy_req" "method"

fn get_method(request) -> http.Method {
  request
  |> erlang_get_method
  |> http.method_from_dynamic
  |> result.unwrap(http.Get)
}

external fn erlang_get_headers(CowboyRequest) -> Map(String, String) =
  "cowboy_req" "headers"

fn get_headers(request) -> List(http.Header) {
  request
  |> erlang_get_headers
  |> map.to_list
}

external fn get_body(CowboyRequest) -> #(req, CowboyRequest) =
  "gleam_cowboy_native" "read_entire_body"

external fn erlang_get_scheme(CowboyRequest) -> String =
  "cowboy_req" "scheme"

fn get_scheme(request) -> http.Scheme {
  request
  |> erlang_get_scheme
  |> http.scheme_from_string
  |> result.unwrap(http.Http)
}

external fn erlang_get_query(CowboyRequest) -> String =
  "cowboy_req" "qs"

fn get_query(request) -> Option(String) {
  case erlang_get_query(request) {
    "" -> None
    query -> Some(query)
  }
}

external fn get_path(CowboyRequest) -> String =
  "cowboy_req" "path"

external fn get_host(CowboyRequest) -> String =
  "cowboy_req" "host"

external fn get_port(CowboyRequest) -> Int =
  "cowboy_req" "port"

fn proplist_get_all(input: List(#(a, b)), key: a) -> List(b) {
  list.filter_map(
    input,
    fn(item) {
      case item {
        #(k, v) if k == key -> Ok(v)
        _ -> Error(Nil)
      }
    },
  )
}

// In cowboy all header values are strings except set-cookie, which is a
// list. This list has a special-case in Cowboy so we need to set it
// correctly.
// https://github.com/gleam-lang/cowboy/issues/3
fn cowboy_format_headers(headers: List(Header)) -> Map(String, Dynamic) {
  let set_cookie_headers = proplist_get_all(headers, "set-cookie")
  headers
  |> list.map(pair.map_second(_, dynamic.from))
  |> map.from_list
  |> map.insert("set-cookie", dynamic.from(set_cookie_headers))
}

fn service_to_handler(
  service: Service(req, assigns, session, res),
) -> fn(CowboyRequest, Params) -> CowboyRequest {
  fn(request, params) {
    let #(body, request) = get_body(request)
    let response =
      Request(
        body: body,
        headers: get_headers(request),
        host: get_host(request),
        method: get_method(request),
        path: get_path(request),
        port: Some(get_port(request)),
        query: get_query(request),
        scheme: get_scheme(request),
        params: params,
        assigns: None,
        session: Error(session.Unset),
      )
      |> request.load_session()
      |> service()
    let status = response.status

    let headers = cowboy_format_headers(response.headers)
    let body = response.body
    cowboy_reply(status, headers, body, request)
  }
}

/// Start the cowboy server on the given port.
/// 
pub fn start(router: CowboyRouter, on_port number: Int) -> Result(Pid, Dynamic) {
  erlang_start_link(router, number)
}
