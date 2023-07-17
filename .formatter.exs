# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ecto],
  locals_without_parens: [
    defenum: :*,
    value: :*,
    default: 1
  ],
  export: [
    locals_without_parens: [value: :*, default: 1]
  ]
]
