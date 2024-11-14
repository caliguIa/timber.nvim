(call
  target: (identifier) @function_name
  (arguments) @log_container
  (do_block) @logable_range (#adjust-range! @logable_range 1 -1)
  (#any-of? @function_name "def" "defp" "defmacro" "if" "unless" "for" "with")
)

(call
  target: (identifier) @function_name
  (arguments)
  (#any-of? @function_name "case" "cond")
) @log_container

; Every expression under a do block is a potential log container
(call
  target: (identifier) @function_name
  (do_block
    (_) @log_container
  )
  (#any-of? @function_name "def" "defp" "defmacro" "if" "unless" "for")
)

; Every expression under an else block is a potential log container
(call
  target: (identifier) @function_name
  (do_block
    (else_block
      (_) @log_container
    )
  )
  (#any-of? @function_name "if" "unless")
)

; Function call
(call
  target: (identifier) @function_name
  (arguments) @log_container
  (#not-any-of? @function_name "def" "defp" "defmacro" "if" "unless" "for" "case" "cond")
  (#not-has-ancestor? @log_container call)
)

; Anonymous function call
(call
  target: (dot
    left: (identifier)
    !right
  )
  (arguments) @log_container
  (#not-has-ancestor? @log_container call)
)

(stab_clause
  left: (arguments) @log_container
  right: (body) @logable_range (#adjust-range! @logable_range 1 -1)
)

; Every expression under the stab clause body
(stab_clause
  right: (body
    (_) @log_container
  )
)

; Pattern matching
(
 (binary_operator
   left: (_)
   "="
   right: (_)
 ) @log_container
 (#not-has-parent? @log_container arguments)
)
