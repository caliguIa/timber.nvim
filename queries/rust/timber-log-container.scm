[
  (let_declaration)
  (const_item)
  (assignment_expression)
  (return_expression)
  (expression_statement)
] @log_container

(function_item
  parameters: (parameters) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(closure_expression
  parameters: (closure_parameters) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(if_expression
  condition: (_) @log_container
  consequence: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(match_expression
  value: (_) @log_container
)

(match_block
  (match_arm
    pattern: (match_pattern) @log_container
    value: (block) @logable_range (#adjust-range! @logable_range 1 -1)
  )
)

(for_expression
  pattern: (_) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(for_expression
  value: (_) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(while_expression
  condition: (_) @log_container
  body: (block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(call_expression
  arguments: (arguments) @log_container
)

(struct_pattern) @log_container
