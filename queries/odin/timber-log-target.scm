(
  (identifier) @log_target
  (#not-has-parent? @log_target index_expression)
  (#not-has-parent? @log_target member_expression)
  (#not-has-parent? @log_target type)
  (#not-field-of-parent? @log_target call_expression function)
)

(index_expression) @log_target

(member_expression
  (identifier) @log_target
  (_)
)

(member_expression
  (identifier)
  (identifier)
) @log_target
