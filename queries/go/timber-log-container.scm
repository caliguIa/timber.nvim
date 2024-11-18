[
  (var_declaration)
  (short_var_declaration)
  (assignment_statement)
  (return_statement)
  (defer_statement)
] @log_container

(function_declaration
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(method_declaration
  receiver: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(method_declaration
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(func_literal
  parameters: (parameter_list
    (parameter_declaration) @log_container
  )
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(if_statement
  condition: (_) @log_container
  consequence: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(for_statement
  (_) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(call_expression
  arguments: (argument_list) @log_container
)

(expression_switch_statement
  value: (_) @log_container
)

(expression_case
  value: (expression_list) @log_container
  (_) @logable_range
)

(select_statement
  (communication_case
    communication: (_) @log_container
    (_) @logable_range
  )
)
