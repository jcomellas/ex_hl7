locals_without_parens = [
  # Segment definition
  segment: 2,
  field: 2,
  # Composite field definition
  composite: 1,
  component: 2,
]

[
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
