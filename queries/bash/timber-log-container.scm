(
  (variable_assignment) @log_container
  (#make-logable-range! @log_container "outer")
)

; my_function foo, bar
(
  (command
    name: (_)
    argument: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; If statements
(
  (if_statement
    condition: (_) @log_container
    . (_) @a
  ) @b
  (#make-logable-range! @a "inner")
  (#make-logable-range! @b "before")
)

; Elif statements
(
  (elif_clause
    (_) @log_container
    . (_) @a
  )
  (#make-logable-range! @a "inner")
)

; Case statements
(
  (case_statement
    value: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (case_item
    value: (_) @log_container
    . (_) @a
  )
  (#make-logable-range! @a "inner")
)

; For loops
(
  (for_statement
    variable: (_) @log_container
    body: (_) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

(
  (for_statement
    value: (_) @log_container
    body: (_) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

(
  (c_style_for_statement
    initializer: (_) @log_container
    body: (do_group) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (c_style_for_statement
    condition: (_) @log_container
    body: (do_group) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

(
  (c_style_for_statement
    update: (_) @log_container
    body: (do_group) @a
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "before")
)

; While loops
(
  (while_statement
    condition: (_) @log_container
    body: (do_group) @a
  ) @b
  (#make-logable-range! @b "before")
  (#make-logable-range! @a "inner" 1 -1)
)
