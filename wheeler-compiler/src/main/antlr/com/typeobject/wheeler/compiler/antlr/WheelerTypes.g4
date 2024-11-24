lexer grammar WheelerTypes;

@header {
package com.typeobject.wheeler.compiler.antlr;
}

// Classical primitive types
BOOLEAN: 'boolean';
BYTE: 'byte';
SHORT: 'short';
INT: 'int';
LONG: 'long';
FLOAT: 'float';
DOUBLE: 'double';
CHAR: 'char';
VOID: 'void';

// Quantum types
QUBIT_T: 'qubit';
QUREG_T: 'qureg';
STATE_T: 'state';
ORACLE_T: 'oracle';

// Container types
ARRAY: 'array';
LIST: 'list';
MAP: 'map';
SET: 'set';

// Special types
HIST_T: 'hist';      // Historical type
REV_T: 'rev';        // Reversible type
PURE_T: 'pure';      // Pure type

// Type parameters
TYPE_PARAM: [A-Z];