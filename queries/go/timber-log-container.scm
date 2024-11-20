(
  [
    (var_declaration)
    (short_var_declaration)
    (assignment_statement)
    (return_statement)
    (defer_statement)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(function_declaration
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(method_declaration
  receiver: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(method_declaration
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(func_literal
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(if_statement
  condition: (_) @log_container
  consequence: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(for_statement
  (_) @log_container
  body: (block) @block
  (#make-logable-range! @block "inner" 1 -1)
)

(
  (call_expression
    arguments: (argument_list) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (expression_switch_statement
    value: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(expression_case
  value: (expression_list) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

(select_statement
  (communication_case
    communication: (_) @log_container
    (_) @a
    (#make-logable-range! @a "inner")
  )
)
