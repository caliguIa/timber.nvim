(
  [
    (let_declaration)
    (const_item)
    (assignment_expression)
    (return_expression)
    (expression_statement)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(function_item
  parameters: (parameters) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(closure_expression
  parameters: (closure_parameters) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(if_expression
  condition: (_) @log_container
  consequence: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(
  (match_expression
    value: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(match_block
  (match_arm
    pattern: (match_pattern) @log_container
    value: (block) @block
    (#make-logable-range! @block "inner" 1 -1)
  )
)

(for_expression
  pattern: (_) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(for_expression
  value: (_) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(while_expression
  condition: (_) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(
  (call_expression
    arguments: (arguments) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (struct_pattern) @log_container
  (#make-logable-range! @log_container "outer")
)
