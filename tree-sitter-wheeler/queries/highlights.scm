(line_comment) @comment
(block_comment) @comment

["classical" "quantum" "hybrid" "class" "record" "variant" "case" "match" "state" "qreg" "new" "void"] @keyword
["long" "boolean"] @type.builtin
["entry" "rev" "coherent" "unitary" "reverse" "assert" "if" "else" "while" "for" "limit" "break" "continue" "return"] @keyword.control
(visibility_modifier) @keyword.modifier
(method_modifier) @keyword.modifier

(class_declaration name: (identifier) @type)
(record_declaration name: (identifier) @type)
(variant_declaration name: (identifier) @type)
(match_case type: (identifier) @type)
(type_identifier) @type
(method_declaration name: (identifier) @function.method)
(call_expression function: (identifier) @function.call)
(coherent_apply_statement method: (identifier) @function.call)

(record_component name: (identifier) @property)
(variant_case_declaration name: (identifier) @constant)
(match_case case: (identifier) @constant)
(field_expression field: (identifier) @property)
(state_declaration name: (identifier) @variable.member)
(qreg_declaration name: (identifier) @variable.member)

(boolean_literal) @constant.builtin.boolean
(integer_literal) @number
(number_literal) @number
