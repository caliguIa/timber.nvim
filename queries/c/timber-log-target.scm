; Basic identifiers (variables) that are not part of other expressions
(
  (identifier) @log_target
  (#not-has-parent? @log_target field_expression)
  (#not-has-parent? @log_target field_designator)
  (#not-has-parent? @log_target subscript_expression)
  (#not-field-of-parent? @log_target call_expression function)
)

; Field access through arrow operator (->)
(field_expression
  argument: (identifier) @log_target
)

;; Field access through dot operator (.)
(field_expression
  argument: (identifier) @log_target
)
;
;; Array subscript expressions

(subscript_expression
  argument: (identifier) @log_target
)

;
; Capture full field and subscript expressions
(
 ([
  (field_expression)
  (subscript_expression)
 ]) @log_target
 (#not-field-of-ancestor? @log_target call_expression function)
)
