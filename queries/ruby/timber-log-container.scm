[
 (assignment)
 (operator_assignment)
 (binary)
 (element_reference)
 (hash)
 (if_modifier)
 (unless_modifier)
] @log_container

(method
  parameters: (method_parameters) @log_container
  body: (body_statement) @logable_range
)

(singleton_method
  parameters: (method_parameters) @log_container
  body: (body_statement) @logable_range
)

(block
  parameters: (block_parameters) @log_container
  body: (block_body) @logable_range
)

(do_block
  parameters: (block_parameters) @log_container
  body: (_) @logable_range
)

(lambda
  parameters: (lambda_parameters) @log_container
  body: (
    block
      body: (block_body) @logable_range
  )
)

(if
  condition: (_) @log_container
  consequence: (then) @logable_range (#adjust-range! @logable_range 1 -1)
)

(if
  alternative: (elsif
    condition: (_) @log_container
    consequence: (then) @logable_range (#adjust-range! @logable_range 1 -1)
  )
)

(unless
  condition: (_) @log_container
  consequence: (then) @logable_range (#adjust-range! @logable_range 1 -1)
)

(for
  pattern: (identifier) @log_container
  body: (do) @logable_range (#adjust-range! @logable_range 1 -1)
)

(for
  value: (_) @log_container
  body: (do) @logable_range (#adjust-range! @logable_range 1 -1)
)

(while
  condition: (_) @log_container
  body: (do) @logable_range (#adjust-range! @logable_range 1 -1)
)

(until
  condition: (_) @log_container
  body: (do) @logable_range (#adjust-range! @logable_range 1 -1)
)

(call
  arguments: (argument_list) @log_container
)

(yield
  (argument_list) @log_container
)

; Calls without arguments
(call
  receiver: [
    (call)
    (identifier)
  ]
  method: (identifier)
  !arguments
) @log_container
