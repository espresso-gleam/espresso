import cowboy/cowboy.{
  Route, RouterRoute, ServiceRoute, StaticRoute, WebsocketRoute,
}
import espresso/ordered_map.{OrderedMap}
import espresso/request.{Request}
import espresso/response.{Response}
import espresso/service.{Middleware, Service}
import espresso/static.{Static}
import espresso/websocket.{Websocket}
import gleam/http
import gleam/list
import gleam/option.{None, Some}

pub type Method {
  ALL
  GET
  POST
  PATCH
  PUT
  DELETE
  HEAD
  OPTIONS
}

pub type Handler(req, assigns, session, res) {
  ServiceHandler(OrderedMap(Method, Service(req, assigns, session, res)))
  RouterHandler(Router(req, assigns, session, res))
  StaticHandler(String, Static)
  WebsocketHandler(Websocket)
}

pub type Router(req, assigns, session, res) {
  Router(
    middleware: Middleware(req, assigns, session, res, req, res),
    handlers: OrderedMap(String, Handler(req, assigns, session, res)),
    not_found: Service(req, assigns, session, res),
  )
}

/// Instantiates a new router. This is usually the starting point for route
/// definitions unless you want to override the types of the req, res, middleware or
/// not_found handler.
/// 
/// # Examples
/// 
/// ```gleam
/// import espresso/router
/// 
/// router.new()
/// |> get("/", fn(_req: Request(BitString)) { send(200, "Success") })
/// ```
pub fn new() {
  Router(
    middleware: fn(x) { x },
    handlers: ordered_map.new(),
    not_found: fn(_req) { response.new(404) },
  )
}

/// Sets the middleware for a router. This is a function that wraps all the router handlers under it.
/// Currently it doesn't support more than one but that may work in the future.
/// 
/// # Examples
/// 
/// ```gleam
/// import espresso/router.{get, delete}
/// import espresso/request.{Request}
/// import espresso/service.{Service}
/// 
/// router.new()
/// |> router.router(
///  "/api",
///  router.new()
///  |> router.middleware(fn(next: Service(BitString, BitBuilder)) {
///    fn(req: Request(BitString)) {
///      let auth = request.get_header(req, "authorization")
///      case auth {
///        Ok("Basic OnN1cGVyc2VjcmV0") -> next(req)
///        _ -> send(401, "Unauthorized")
///      }
///    }
///  })
///  |> get("/things", fn(_req: Request(BitString)) { send(200, "Things") })
///  |> delete("/things", fn(_req: Request(BitString)) { send(204, "") }),
/// )
/// 
/// ```
/// 
pub fn middleware(
  router: Router(req, assigns, session, res),
  middleware: Middleware(req, assigns, session, res, req, res),
) {
  Router(..router, middleware: middleware)
}

fn add_service_handler(
  router: Router(req, assigns, session, res),
  path: String,
  method: Method,
  handler: Service(req, assigns, session, res),
) {
  let handlers =
    ordered_map.update(
      router.handlers,
      path,
      fn(existing_handler) {
        case existing_handler {
          Some(ServiceHandler(routes)) -> {
            let wrapped_handler = router.middleware(handler)
            ServiceHandler(ordered_map.insert(routes, method, wrapped_handler))
          }
          None -> {
            let wrapped_handler = router.middleware(handler)
            ServiceHandler([#(method, wrapped_handler)])
          }
          // this should be an error
          Some(a) -> a
        }
      },
    )
  Router(..router, handlers: handlers)
}

pub fn get(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Service(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  add_service_handler(router, path, GET, handler)
}

pub fn post(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Service(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  add_service_handler(router, path, POST, handler)
}

pub fn put(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Service(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  add_service_handler(router, path, PUT, handler)
}

pub fn patch(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Service(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  add_service_handler(router, path, PATCH, handler)
}

pub fn delete(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Service(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  add_service_handler(router, path, DELETE, handler)
}

/// Adds a websocket handler to a path 
/// 
/// # Example
/// 
/// ```gleam
/// import espresso/router.{websocket}
/// import espresso/websocket.{Websocket}
///
/// pub fn main() {
///  let router =
///    router.new()
///    |> websocket(
///      "/socket",
///      fn(frame) {
///        case frame {
///          "chat:" <> _message -> websocket.Reply("Hello")
///          "ping" -> websocket.Reply("pong")
///          "actual_ping" -> websocket.Ping("")
///          "pong" -> websocket.Pong("")
///          _ -> websocket.Close("")
///        }
///      },
///    )
///
///  start(router)
///}
/// ```
/// 
/// 
pub fn websocket(
  router: Router(req, assigns, session, res),
  path: String,
  handler: Websocket,
) -> Router(req, assigns, session, res) {
  let handlers =
    ordered_map.insert(router.handlers, path, WebsocketHandler(handler))
  Router(..router, handlers: handlers)
}

/// Handles a request for a given path and returns static files
/// Currently only supports File and Directory
/// 
/// # Examples
/// 
/// ```gleam
/// import espresso/router
/// import espreso/static
///
/// // Serves all files in the priv/public directory for any request starting with /public
/// router.new()
/// |> router.static("/public/[...]", static.Dir("priv/public"))
/// 
/// // Serves only the index.html file from the priv/public directory
/// router.new()
/// |> router.static("/", static.File("priv/public/index.html"))
/// ```
/// 
pub fn static(
  router: Router(req, assigns, session, res),
  path: String,
  config: Static,
) -> Router(req, assigns, session, res) {
  let handlers =
    ordered_map.insert(router.handlers, path, StaticHandler(path, config))
  Router(..router, handlers: handlers)
}

pub fn router(
  router: Router(req, assigns, session, res),
  path: String,
  subrouter: Router(req, assigns, session, res),
) -> Router(req, assigns, session, res) {
  Router(..router, handlers: expand(path, router.handlers, subrouter))
}

pub fn expand(
  path: String,
  handlers: OrderedMap(String, Handler(req, assigns, session, res)),
  router: Router(req, assigns, session, res),
) -> OrderedMap(String, Handler(req, assigns, session, res)) {
  ordered_map.fold(
    router.handlers,
    handlers,
    fn(acc, key, value) {
      case value {
        RouterHandler(subrouter) -> {
          expand(path <> key, acc, subrouter)
        }
        ServiceHandler(routes) -> {
          ordered_map.insert(acc, path <> key, ServiceHandler(routes))
        }
        StaticHandler(path, config) -> {
          ordered_map.insert(acc, path <> key, StaticHandler(path, config))
        }
        WebsocketHandler(handler) -> {
          ordered_map.insert(acc, path <> key, WebsocketHandler(handler))
        }
      }
    },
  )
}

pub fn handle(
  router: Router(req, assigns, session, res),
  routes: OrderedMap(Method, Service(req, assigns, session, res)),
) -> Service(req, assigns, session, res) {
  fn(req: Request(req, assigns, session)) -> Response(res) {
    let method = req_to_method(req)
    let handler = ordered_map.get(routes, method)

    case handler {
      Some(handler) -> router.middleware(handler)(req)
      None -> router.not_found(req)
    }
  }
}

pub fn to_routes(
  router: Router(req, assigns, session, res),
) -> OrderedMap(String, Route(req, assigns, session, res)) {
  router.handlers
  |> list.map(fn(route_handler: #(String, Handler(req, assigns, session, res))) {
    let #(path, handler) = route_handler
    let service = case handler {
      ServiceHandler(routes) -> {
        let r = handle(router, routes)
        ServiceRoute(r)
      }
      RouterHandler(router) -> RouterRoute(to_routes(router))
      StaticHandler(path, config) -> StaticRoute(path, config)
      WebsocketHandler(handler) -> {
        WebsocketRoute(handler)
      }
    }
    #(path, service)
  })
}

fn req_to_method(req: Request(body, assigns, session)) {
  case req.method {
    http.Get -> GET
    http.Post -> POST
    http.Patch -> PATCH
    http.Put -> PUT
    http.Delete -> DELETE
    _ -> GET
  }
}
