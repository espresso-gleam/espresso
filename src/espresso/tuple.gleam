pub fn apply1(func: fn(a) -> r, args: #(a)) {
  func(args.0)
}

pub fn apply2(func: fn(a, b) -> r, args: #(a, b)) {
  func(args.0, args.1)
}

pub fn apply3(func: fn(a, b, c) -> r, args: #(a, b, c)) {
  func(args.0, args.1, args.2)
}

pub fn apply4(func: fn(a, b, c, d) -> r, args: #(a, b, c, d)) {
  func(args.0, args.1, args.2, args.3)
}
