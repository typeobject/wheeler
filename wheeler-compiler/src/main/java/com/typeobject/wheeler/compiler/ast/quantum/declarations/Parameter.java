package com.typeobject.wheeler.compiler.ast.quantum.declarations;

import com.typeobject.wheeler.compiler.ast.base.Type;

public record Parameter(Type type, String name, boolean isRev) {}
