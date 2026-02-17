;; extends


;------------------------------------------------------------------------------
; Add textobjects @cast.outer and @cast.inner for inner and outer variable casts
(cast_expression
  (
    "(" @cast.outer
    .
    type: (_)  @cast.inner
    .
    ")" @cast.outer 
  ) 
)

;------------------------------------------------------------------------------
;text object to select function name

(method_declaration
    name: (_) @function_declaration_name.inner)

(constructor_declaration
    name: (_) @function_declaration_name.inner)


