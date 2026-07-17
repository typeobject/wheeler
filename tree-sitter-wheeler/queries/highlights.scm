(line_comment) @comment
(block_comment) @comment

["classical" "quantum" "hybrid" "class" "state" "qreg" "new" "void"] @keyword
["entry" "rev" "coherent" "unitary" "reverse" "assert"] @keyword.control
(visibility_modifier) @keyword.modifier
(method_modifier) @keyword.modifier

(class_declaration name: (identifier) @type)
(method_declaration name: (identifier) @function.method)
(call_expression function: (identifier) @function.call)
(coherent_apply_statement method: (identifier) @function.call)

(state_declaration name: (identifier) @variable.member)
(qreg_declaration name: (identifier) @variable.member)
(qubit_reference register: (identifier) @variable)

(integer_literal) @number
(number_literal) @number
