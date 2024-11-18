(
  (identifier) @log_target
  (#not-eq? @log_target "_")
  (#not-field-of-parent? @log_target call_expression function)
  (#not-field-of-ancestor? @log_target parameter_declaration type)
)

(
  (selector_expression) @log_target
  (#not-field-of-ancestor? @log_target call_expression function)
)
