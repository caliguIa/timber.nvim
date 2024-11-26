(
  (variable_declaration) @log_container
  (#make-logable-range! @log_container "outer")
)

; Assignment without variable declaration
(
  (assignment_statement) @log_container
  (#not-has-parent? @log_container variable_declaration)
  (#make-logable-range! @log_container "outer")
)

(function_call
  arguments: (arguments) @log_container
  (#make-logable-range! @log_container "outer")
)

(function_declaration
  parameters: (parameters) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(function_definition
  parameters: (parameters) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(if_statement
  condition: (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner")
)

(if_statement
  alternative: (elseif_statement
    condition: (_) @log_container
    consequence: (block) @a
    (#make-logable-range! @a "inner")
  )
)

(for_statement
  clause: (for_generic_clause (variable_list) @log_container)
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(for_statement
  clause: (for_numeric_clause) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(
  (while_statement
    condition: (_) @log_container
    body: (block) @a
  ) @b
  (#make-logable-range! @b "before")
  (#make-logable-range! @a "inner")
)

(
  (repeat_statement
    body: (block) @a
    condition: (_) @log_container
  ) @b
  (#make-logable-range! @a "inner")
  (#make-logable-range! @b "after")
)

