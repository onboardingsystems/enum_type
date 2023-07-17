# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import: [:ecto],
  locals_without_parens: [
    defenum: :*,
    value: :*,
    default: 1,
  ]
]
