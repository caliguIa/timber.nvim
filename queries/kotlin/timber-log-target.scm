(
  (simple_identifier) @log_target
  (#not-has-parent? @log_target navigation_suffix)
)

(call_expression) @log_target

(
  (navigation_expression) @log_target
  (#not-has-parent? @log_target call_expression)
)

(this_expression) @log_target
