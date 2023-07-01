//// Experimental module used to render functions
//// into an io list and turn that list into a string
//// 
//// This module is experimental and may change or be removed
//// 

import gleam/string_builder.{StringBuilder, append, append_builder}
import gleam/list

pub type Attributes =
  List(#(String, String))

pub type Element {
  Text(text: String)
  Element(tag_name: String, attributes: Attributes, children: Children)
}

type Children =
  List(Element)

pub fn new(
  tag_name: String,
  attributes: Attributes,
  children: Children,
) -> Element {
  Element(tag_name: tag_name, attributes: attributes, children: children)
}

pub fn render(element: Element) -> StringBuilder {
  case element {
    Text(text) ->
      string_builder.new()
      |> append(text)
    Element(tag_name, attributes, children) -> {
      string_builder.new()
      |> append("<" <> tag_name)
      |> render_attributes(attributes)
      |> append(">")
      |> render_children(children)
      |> append("</" <> tag_name <> ">")
    }
  }
}

fn render_children(builder: StringBuilder, children: Children) -> StringBuilder {
  list.fold(
    children,
    builder,
    fn(builder, child) { append_builder(builder, render(child)) },
  )
}

fn render_attributes(builder: StringBuilder, attributes: Attributes) {
  list.fold(
    attributes,
    builder,
    fn(builder, attribute) {
      let #(key, value) = attribute

      append(builder, " " <> key <> "=\"" <> value <> "\"")
    },
  )
}

pub fn doctype() -> StringBuilder {
  string_builder.from_string("<!DOCTYPE html>")
}

/// Renders an HTML element into a string of HTML
/// 
/// # Examples
/// 
/// ```gleam
/// ```
pub fn to_string(dom: Element) -> String {
  dom
  |> render()
  |> string_builder.prepend_builder(doctype())
  |> string_builder.to_string()
}

/// Creates a new HTML element with the given tag name
pub fn t(name: String) {
  Element(name, [], [])
}

/// Adds an attribute of name+value to an HTML element
pub fn a(el: Element, name: String, value: String) -> Element {
  case el {
    Element(tag_name, attributes, children) ->
      Element(tag_name, [#(name, value), ..attributes], children)
    txt -> txt
  }
}

/// Adds children to an element
pub fn c(el: Element, new_children: Children) -> Element {
  case el {
    Element(tag_name, attributes, children) ->
      Element(tag_name, attributes, list.append(children, new_children))
    txt -> txt
  }
}

/// Adds a text node to an element
pub fn txt(text: String) -> Element {
  Text(text)
}
