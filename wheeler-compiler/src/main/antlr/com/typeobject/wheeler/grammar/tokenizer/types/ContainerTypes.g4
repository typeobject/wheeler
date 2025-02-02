// Defines collection and container types
lexer grammar ContainerTypes;

// Basic containers
ARRAY       : 'array';           // Fixed-size sequence
LIST        : 'list';            // Dynamic sequence
SET         : 'set';             // Unique elements
MAP         : 'map';             // Key-value pairs

// Special collections
VECTOR      : 'vector';          // Mathematical vector
MATRIX      : 'matrix';          // Mathematical matrix
TUPLE       : 'tuple';           // Fixed heterogeneous sequence

// Generic type parameters
TYPE_PARAM  : [A-Z];             // Single letter type parameter

// Type bounds
EXTENDS     : 'extends';         // Upper bound
SUPER       : 'super';           // Lower bound