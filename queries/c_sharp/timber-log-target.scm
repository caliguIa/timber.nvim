; Basic identifiers that aren't part of member access
(
  (identifier) @log_target
  (#not-has-parent? @log_target member_access_expression)
  (#not-has-parent? @log_target element_access_expression)
  (#not-field-of-parent? @log_target invocation_expression function)
  (#not-eq? @log_target "_")
)

; Support logging a link while method chaining
(invocation_expression) @log_target

; Member access (C#'s dot notation)
(
  (member_access_expression
    expression: (identifier) @log_target
  ) @a
  (#not-field-of-ancestor? @a invocation_expression function)
)

; Array/element access
(
  (element_access_expression
    expression: (identifier) @log_target
  ) @a
  (#not-field-of-ancestor? @a invocation_expression function)
)

; Capture full member chains and element accesses when they're not method calls
(
  ([
    (member_access_expression)
    (element_access_expression)
  ]) @log_target
  (#not-field-of-ancestor? @log_target invocation_expression function)
)
