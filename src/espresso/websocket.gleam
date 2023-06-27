//// Types used for interacting with cowboy websockets
//// 
//// https://ninenines.eu/docs/en/cowboy/2.6/manual/cowboy_websocket/

/// Frames represent four common types of responses
/// 
/// Reply: A normal response
/// Ping: is normally used for heartbeats
/// Pong: is normally used for responding to heartbeats
/// Close: is used to close the connection
/// 
/// The inner string of the types is the message that the client socket will receive
pub type Frame {
  Reply(String)
  Ping(String)
  Pong(String)
  Close(String)
}

/// Websocket is a function that takes a string and returns a Frame
/// 
/// The string is the message that the client socket will receive
/// and the Frame is the response that the server will send.
pub type Websocket =
  fn(String) -> Frame
