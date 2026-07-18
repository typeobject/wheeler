(line_comment) @comment
(block_comment) @comment

["classical" "quantum" "hybrid" "class" "state" "qreg" "new" "void"] @keyword
["long" "boolean"] @type.builtin
["entry" "rev" "coherent" "unitary" "reverse" "assert" "if" "else" "while" "for" "limit" "break" "continue" "return"] @keyword.control
(visibility_modifier) @keyword.modifier
(method_modifier) @keyword.modifier

(class_declaration name: (identifier) @type)
(method_declaration name: (identifier) @function.method)
(call_expression function: (identifier) @function.call)
(coherent_apply_statement method: (identifier) @function.call)

(state_declaration name: (identifier) @variable.member)
(qreg_declaration name: (identifier) @variable.member)
(qubit_reference register: (identifier) @variable)

(boolean_literal) @constant.builtin.boolean
(integer_literal) @number
(number_literal) @number
