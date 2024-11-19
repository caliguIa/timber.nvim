(
 (identifier) @log_target
 (#not-match? @log_target "^_")
 (#not-field-of-parent? @log_target call_expression function)
 (#not-field-of-parent? @log_target scoped_identifier path)
 (#not-field-of-parent? @log_target scoped_identifier name)
 (#not-field-of-parent? @log_target scoped_type_identifier path)
 (#not-field-of-parent? @log_target scoped_type_identifier name)
 (#not-field-of-parent? @log_target tuple_struct_pattern type)
 (#not-field-of-parent? @log_target macro_invocation macro)
)

(
 (field_expression) @log_target
 (#not-field-of-parent? @log_target call_expression function)
)

(shorthand_field_identifier) @log_target
