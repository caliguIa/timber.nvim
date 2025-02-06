; Variable declarations
(
  (declaration) @log_container
  (#make-logable-range! @log_container "outer")
)

; Assignment expressions
(
  (expression_statement
    ([
      (assignment_expression)
      (update_expression)
      (parameter_pack_expansion)
    ]) @log_container
  )
  (#make-logable-range! @log_container "outer")
)

; Function calls
(
  (call_expression
    arguments: (argument_list) @log_container)
  (#make-logable-range! @log_container "outer")
)

; Function declarations with parameters
(
  (function_definition
    declarator: (function_declarator
      parameters: (parameter_list) @log_container
    )
    body: (compound_statement) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Class method declarations
(
  (field_declaration
    declarator: (function_declarator
      parameters: (parameter_list) @log_container))
)

; If statements
(
  (if_statement
    condition: (condition_clause) @log_container
    consequence: (compound_statement) @a
  ) @b
  (#not-has-parent? @b else_clause)
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; If statements with single statement body
(
  (if_statement
    condition: (condition_clause) @log_container
    consequence: (_) @a
  ) @b
  (#not-match? @a "^\\{")
  (#make-logable-range! @b "before")
)

; Else-If statements
(
  (if_statement
    condition: (condition_clause) @log_container
    consequence: (compound_statement) @a
  ) @b
  (#has-parent? @b else_clause)
  (#make-logable-range! @a "inner" 1 -1)
)

; Traditional for loops
(
  (for_statement
    initializer: (_) @log_container
    body: (compound_statement) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (for_statement
    condition: (_) @log_container
    body: (compound_statement) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

(
  (for_statement
    update: (_) @log_container
    body: (compound_statement) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; While loops
(
  (while_statement
    condition: (condition_clause) @log_container
    body: (compound_statement) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; Do-while loops
(
  (do_statement
    body: (compound_statement) @a
    condition: (parenthesized_expression) @log_container
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "after")
)

; Try-catch blocks
(
  (try_statement
    body: (_)
    (catch_clause
      parameters: (parameter_list) @log_container
      body: (compound_statement) @a
    )
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Lambda expressions
(
  (lambda_expression
    captures: (lambda_capture_specifier) @log_container
    body: (compound_statement) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)


; Lambda expressions
(
  (lambda_expression
    declarator: (lambda_declarator
      parameters: (parameter_list) @log_container
    )
    body: (compound_statement) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)
