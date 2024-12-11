(
  [
    (var_declaration)
    (variable_declaration)
    (const_declaration)
    (member_expression)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (assignment_statement) @log_container
  (#make-logable-range! @log_container "outer")
)

; Function calls
(
  (call_expression
    argument: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; Function declarations with parameters
(procedure
  (parameters) @log_container
  (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; If statements
(
  (if_statement
    condition: (_) @log_container
    consequence: (block) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; Else if statements
(
  (else_if_clause
    condition: (_) @log_container
    consequence: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; For loops
(for_statement
  initializer: (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(for_statement
  condition: (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(for_statement
  post: (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(for_statement
  (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Switch statements
(
 (switch_statement
    condition: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(switch_case
  condition: (_) @log_container
  (block) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Single statement case
(switch_case
  condition: (_) @log_container
  (_) @a
  (#not-match? @a "^\\{")
  (#make-logable-range! @a "inner")
)
