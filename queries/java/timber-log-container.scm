(
  (expression_statement) @log_container
  (#make-logable-range! @log_container "outer")
)

; Variable declarations and assignments
(
  (local_variable_declaration) @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (assignment_expression) @log_container
  (#not-has-parent? @log_container local_variable_declaration)
  (#make-logable-range! @log_container "outer")
)

; Method calls
(
  (method_invocation
    arguments: (argument_list) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; Method declarations
(
  (method_declaration
    parameters: (formal_parameters) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Constructor declarations
(
  (constructor_declaration
    parameters: (formal_parameters) @log_container
    body: (constructor_body) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; If statements
(
  (if_statement
    condition: (parenthesized_expression) @log_container
    consequence: (block) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; Else-if statements
(
  (if_statement
    alternative: (if_statement
      condition: (parenthesized_expression) @log_container
      consequence: (block) @a
    )
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; For loops
(
  (for_statement
    init: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (for_statement
    condition: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (for_statement
    update: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Enhanced for loops
(
  (enhanced_for_statement
    name: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (enhanced_for_statement
    value: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)


; While loops
(
  (while_statement
    condition: (parenthesized_expression) @log_container
    body: (block) @a
  ) @b
  (#make-logable-range! @b "before")
  (#make-logable-range! @a "inner" 1 -1)
)

; Do-while loops
(
  (do_statement
    body: (block) @a
    condition: (parenthesized_expression) @log_container
  ) @b
  (#make-logable-range! @a "inner")
  (#make-logable-range! @b "after")
)

(
  (lambda_expression
    parameters: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (try_statement
    (catch_clause
      (catch_formal_parameter) @log_container
      body: (block) @a
    )
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (try_with_resources_statement
    resources: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)
