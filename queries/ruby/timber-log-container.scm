(
  [
    (assignment)
    (operator_assignment)
    (binary)
    (element_reference)
    (hash)
    (if_modifier)
    (unless_modifier)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(method
  parameters: (method_parameters) @log_container
  body: (body_statement) @a
  (#make-logable-range! @a "inner")
)

(singleton_method
  parameters: (method_parameters) @log_container
  body: (body_statement) @a
  (#make-logable-range! @a "inner")
)

(block
  parameters: (block_parameters) @log_container
  body: (block_body) @a
  (#make-logable-range! @a "inner")
)

(do_block
  parameters: (block_parameters) @log_container
  body: (_) @a
  (#make-logable-range! @a "inner")
)

(lambda
  parameters: (lambda_parameters) @log_container
  body: (
    block
      body: (block_body) @a
  )
  (#make-logable-range! @a "inner")
)

(if
  condition: (_) @log_container
  consequence: (then) @a
  (#make-logable-range! @a "inner")
)

(if
  alternative: (elsif
    condition: (_) @log_container
    consequence: (then) @a
    (#make-logable-range! @a "inner" 1 -1)
  )
)

(unless
  condition: (_) @log_container
  consequence: (then) @a
  (#make-logable-range! @a "inner")
)

(for
  pattern: (identifier) @log_container
  body: (do) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(for
  value: (_) @log_container
  body: (do) @a
  (#make-logable-range! @a "inner")
  (#make-logable-range! @a "inner" 1 -1)
)

(while
  condition: (_) @log_container
  body: (do) @a
  (#make-logable-range! @a "inner")
)

(until
  condition: (_) @log_container
  body: (do) @a
  (#make-logable-range! @a "inner")
)

(call
  arguments: (argument_list) @log_container
  (#make-logable-range! @log_container "outer")
)

(yield
  (argument_list) @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (call
    receiver: [
      (call)
      (identifier)
    ]
    method: (identifier)
    !arguments
  ) @log_container
  (#make-logable-range! @log_container "outer")
)
