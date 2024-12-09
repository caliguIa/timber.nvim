; Variable declarations and assignments
(
  (local_declaration_statement) @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (assignment_expression) @log_container
  (#not-has-parent? @log_container local_declaration_statement)
  (#make-logable-range! @log_container "outer")
)

; Method calls
(
  (invocation_expression
    arguments: (argument_list) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; Method declarations
(
  (method_declaration
    parameters: (parameter_list) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Constructor declarations
(
  (constructor_declaration
    parameters: (parameter_list) @log_container
    body: (block) @a
  )
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

; Else-if statements
(
  (if_statement
    alternative: (if_statement
      condition: (_) @log_container
      consequence: (block) @a
    )
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; For loops
(
  (for_statement
    initializer: (_) @log_container
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

(
  (foreach_statement
    left: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (foreach_statement
    right: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)


; While loops
(
  (while_statement
    condition: (_) @log_container
    body: (block) @a
  ) @b
  (#make-logable-range! @b "before")
  (#make-logable-range! @a "inner" 1 -1)
)

; Do-while loops
(
  (do_statement
    body: (block) @a
    condition: (_) @log_container
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "after")
)

; Lambda expressions
(
  (lambda_expression
    parameters: (_) @log_container
    body: (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Try-catch blocks
(
  (try_statement
    (catch_clause
      (catch_declaration) @log_container
      body: (block) @a
    )
  )
  (#make-logable-range! @a "inner" 1 -1)
)

; Function invocations
(
  (invocation_expression
    arguments: (argument_list) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; Switch statements
(
  (switch_statement
    value: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (switch_section
    (constant_pattern) @log_container
    (block) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (switch_section
    (constant_pattern) @log_container
    (_) @a
  )
  ; Not a block
  (#not-match? @a "^\\{")
  (#make-logable-range! @a "inner")
)
