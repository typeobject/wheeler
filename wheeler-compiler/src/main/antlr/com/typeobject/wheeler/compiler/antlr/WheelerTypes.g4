// WARNING: Deprecated. This is getting replaced by the new grammar structure.

lexer grammar WheelerTypes;

// Classical primitive types
BOOLEAN_T: 'boolean';
BYTE_T: 'byte';
SHORT_T: 'short';
INT_T: 'int';
LONG_T: 'long';
FLOAT_T: 'float';
DOUBLE_T: 'double';
CHAR_T: 'char';
VOID_T: 'void';

// Container types
ARRAY_T: 'array';
LIST_T: 'list';
MAP_T: 'map';
SET_T: 'set';

// Type parameters
TYPE_PARAM: [A-Z];