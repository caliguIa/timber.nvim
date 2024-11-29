(
  ([
    (lexical_declaration)
    (return_statement)
    (expression_statement)
    (import_statement)
  ]) @log_container
  (#make-logable-range! @log_container "outer")
)

(function_declaration
  parameters: (formal_parameters) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(function_expression
  parameters: (formal_parameters) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(arrow_function
  parameters: (formal_parameters) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(expression_statement
  (call_expression
    function: (identifier)
    arguments: (arguments) @log_container
  ) @a
  (#make-logable-range! @log_container "outer")
)

(try_statement
  handler: (catch_clause
    parameter: (_) @log_container
    body: (statement_block) @body
    (#make-logable-range! @body "inner" 1 -1)
  )
)

(
  (if_statement
    condition: (parenthesized_expression) @log_container
    consequence: (statement_block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

; if statement with single statement body
(
  (if_statement
    condition: (parenthesized_expression) @log_container
    consequence: (_) @body (#not-match? @body "^\\{")
  ) @a
  (#make-logable-range! @a "outer")
)

(
  (switch_statement
    value: (parenthesized_expression) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(switch_statement
  body: (switch_body
    (switch_case
      value: (_) @log_container
      body: (statement_block) @body
      (#make-logable-range! @body "inner" 1 -1)
    )
  )
)

(switch_statement
  body: (switch_body
    (switch_case
      value: (_) @log_container
      body: (_) @body
      (#not-match? @body "^\\{")
      (#make-logable-range! @body "inner")
    )
  )
)

(for_statement
  condition: (_) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(for_statement
  increment: (_) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(for_in_statement
  left: (_) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(for_in_statement
  right: (_) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(
  (while_statement
    condition: (_) @log_container
    body: (statement_block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

(do_statement
  body: (statement_block) @body
  condition: (_) @log_container
  (#make-logable-range! @body "inner" 1 -1)
  (#make-logable-range! @log_container "after")
)

(method_definition
  parameters: (formal_parameters) @log_container
  body: (statement_block) @body
  (#make-logable-range! @body "inner" 1 -1)
)
