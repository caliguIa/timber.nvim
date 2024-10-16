; identifier is the log target

; const idenifier = foo
(lexical_declaration
  (variable_declarator
    name: (identifier) @log_target
  )
) @container

; const { identifier: foo } = bar
(lexical_declaration
  (variable_declarator
    name: (object_pattern
      (pair_pattern
        value: (identifier) @log_target
      )
    )
  )
) @container

; const { identifier } = foo
(lexical_declaration
  (variable_declarator
    name: (object_pattern
      (shorthand_property_identifier_pattern) @log_target
    )
  )
) @container

; const [identifier] = foo
(lexical_declaration
  (variable_declarator
    name: (array_pattern
      (identifier) @log_target
    )
  )
) @container

; function foo(identifier: T)
(formal_parameters
  ([
    (required_parameter
      pattern: (identifier) @log_target)
    (optional_parameter
      pattern: (identifier) @log_target)
  ])
) @container

; function foo(identifier: T)
(formal_parameters
  (required_parameter
    pattern: (object_pattern
      (shorthand_property_identifier_pattern) @log_target
    )
  )
) @container

; catch(error) {}
(
 (catch_clause
    parameter: (identifier) @log_target
    body: (statement_block) @container
  )
  (#set! log_placement "inner")
)
