(
  (identifier) @log_target
  (#not-field-of-parent? @log_target call target)
  (#not-field-of-parent? @log_target dot left)
  (#not-field-of-parent? @log_target dot right)
  (#not-lua-match? @log_target "^_")
)

(dot
  left: (identifier) @log_target
  right: (identifier)
)

(access_call) @log_target

; Struct access
(call
  target: (dot
    left: [
      (identifier)
      (call)
    ]
    right: (identifier)
  ) @log_target
)
