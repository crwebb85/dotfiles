;; extends

;------------------------------------------------------------------------------
; function M.is_dict() ... end
  (function_declaration
    name: (dot_index_expression
      field: (_) @function_declaration_name.inner
    )
  )

;local is_dict = function() ... end
local_declaration: (variable_declaration
    (assignment_statement
      (variable_list
        name: (identifier) @function_declaration_name.inner )
      (expression_list
        value: (function_definition))
    )
)

; M.is_dict = function() ... end
(assignment_statement
    (variable_list
      name: (dot_index_expression
          field: (_) @function_declaration_name.inner))
    (expression_list
      value: (function_definition))
)

; local function is_dict() ... end
local_declaration: (function_declaration
    name: (identifier) @function_declaration_name.inner
)

;------------------------------------------------------------------------------

