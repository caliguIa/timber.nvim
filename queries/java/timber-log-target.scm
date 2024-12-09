; Basic identifiers that aren't part of member access or array access
(
  (identifier) @log_target
  (#not-has-parent? @log_target member_select)
  (#not-has-parent? @log_target array_access)
  (#not-has-parent? @log_target field_access)
  (#not-field-of-parent? @log_target method_invocation name)
  (#not-eq? @log_target "_")
)

; Support logging a link while method chaining
(method_invocation) @log_target


; Field access (similar to Lua's dot notation)
(
  (field_access
    object: (identifier) @log_target
  ) @parent
  (#not-field-of-ancestor? @parent method_invocation name)
)

; Array access
(
  (array_access
    array: (identifier) @log_target
  ) @parent
  (#not-field-of-ancestor? @parent method_invocation name)
)

; Capture full member chains and array accesses when they're not method calls
(
  ([
    (field_access)
    (array_access)
  ]) @log_target
  (#not-field-of-ancestor? @log_target method_invocation name)
)

; Handle this keyword references
(
  (this) @log_target
)
