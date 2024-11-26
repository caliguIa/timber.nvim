(
  (identifier) @log_target
  (#not-field-of-ancestor? @log_target call function)
  (#not-field-of-parent? @log_target keyword_argument name)
  (#not-field-of-parent? @log_target attribute attribute)
  (#not-field-of-parent? @log_target subscript subscript)
)

(
  (attribute) @log_target
  (#not-field-of-ancestor? @log_target call function)
)

(
  (subscript) @log_target
  (#not-field-of-ancestor? @log_target call function)
)
