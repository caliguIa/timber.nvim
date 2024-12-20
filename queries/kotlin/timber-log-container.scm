(
  [
    (property_declaration)
    (assignment)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (call_expression
    (call_suffix
      (value_arguments) @log_container
    )
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (function_declaration
    (function_value_parameters) @log_container
    (function_body) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (if_expression
    condition: (_) @log_container
    consequence: (control_structure_body) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

(
  (if_expression
    alternative: (
      (control_structure_body
        (if_expression
          condition: (parenthesized_expression) @log_container
          consequence: (control_structure_body) @a
        )
      )
    )
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (for_statement
    (_) @log_container
    (control_structure_body) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (while_statement
    (_) @log_container
    (control_structure_body) @a
  ) @b
  (#make-logable-range! @b "before")
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (do_while_statement
    (control_structure_body) @a
    (_) @log_container
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "after")
)

(
  (when_expression
    (when_subject) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (when_entry
    (when_condition) @log_container
    (control_structure_body) @a
  )
  ; Match a block {
  (#match? @a "^\\{")
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (lambda_literal
    (lambda_parameters) @log_container
    (statements) @a
  )
  (#make-logable-range! @a "inner")
)

(try_expression
  (catch_block
    .
    (_) @log_container
    (statements) @a
  )
  (#make-logable-range! @a "inner")
)
