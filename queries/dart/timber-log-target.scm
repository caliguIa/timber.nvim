(
  (identifier) @log_target
  (#not-has-parent? @log_target unconditional_assignable_selector)
)

(
  (identifier) @identifier
  .
  (selector
    (unconditional_assignable_selector)
  )*
  .
  (selector
    (unconditional_assignable_selector)
  ) @last_selector
  (#make-log-target-range! @identifier @last_selector)
)
