package com.typeobject.wheeler.compiler.ast.quantum.gates;

public enum GateType {
    CUSTOM,    // For custom-defined gates
    H,         // Hadamard
    X,         // Pauli-X
    Y,         // Pauli-Y
    Z,         // Pauli-Z
    CNOT,      // Controlled-NOT
    TOFFOLI,   // Toffoli gate
    PHASE,     // Phase gate
    ROTATE     // Rotation gate
}