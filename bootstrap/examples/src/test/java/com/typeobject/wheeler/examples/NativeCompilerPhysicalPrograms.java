package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.examples.NativeCompilerArchiveClosureProgram.PhysicalModule;
import java.util.List;

/** Builds focused programs over selected physical compiler products. */
final class NativeCompilerPhysicalPrograms {
  private NativeCompilerPhysicalPrograms() {}

  static Program comparable(PhysicalModule module) throws Exception {
    return NativeCompilerArchiveClosureProgram.program(
        /* compilePhysicalProducts= */ true,
        List.of(module),
        List.of());
  }

  static Program callable(PhysicalModule module) throws Exception {
    return callable(List.of(module));
  }

  static Program callable(List<PhysicalModule> modules) throws Exception {
    return NativeCompilerArchiveClosureProgram.program(
        /* compilePhysicalProducts= */ true,
        List.of(),
        modules);
  }

  static Program metadata() throws Exception {
    return NativeCompilerArchiveClosureProgram.program(
        /* compilePhysicalProducts= */ false,
        NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES,
        NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES);
  }
}
