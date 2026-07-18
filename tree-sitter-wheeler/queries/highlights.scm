; Wheeler semantic highlighting captures for editors; these do not define validity.
(line_comment) @comment
(block_comment) @comment

["classical" "quantum" "hybrid" "module" "import" "class" "record" "variant" "enum" "const" "case" "match" "theorem" "proves" "inverse" "adjoint" "equivalent" "steps" "state" "qreg" "new" "void"] @keyword
["long" "boolean" "region" "words" "bytes" "longmap" "utf8"] @type.builtin
["entry" "rev" "coherent" "unitary" "reverse" "assert" "if" "else" "while" "for" "limit" "break" "continue" "return"] @keyword.control
(visibility_modifier) @keyword.modifier
(method_modifier) @keyword.modifier

(class_declaration name: (identifier) @type)
(record_declaration name: (identifier) @type)
(variant_declaration name: (identifier) @type)
(enum_declaration name: (identifier) @type)
(match_case type: (identifier) @type)
(type_identifier) @type
(qualified_type) @type
(method_declaration name: (identifier) @function.method)
(theorem_declaration name: (identifier) @function)
(theorem_declaration subject: (identifier) @function.method)
(theorem_declaration related_subject: (identifier) @function.method)
(call_expression function: (identifier) @function.call)
(call_expression function: (qualified_function) @function.call)
(coherent_apply_statement method: (identifier) @function.call)

(record_component name: (identifier) @property)
(variant_case_declaration name: (identifier) @constant)
(enum_case name: (identifier) @constant)
(constant_declaration name: (identifier) @constant)
(match_case case: (identifier) @constant)
(field_expression field: (identifier) @property)
(state_declaration name: (identifier) @variable.member)
(qreg_declaration name: (identifier) @variable.member)

(boolean_literal) @constant.builtin.boolean
(integer_literal) @number
(number_literal) @number
(ascii_literal) @string
