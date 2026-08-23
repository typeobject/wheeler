package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import java.util.Map;

/** Compares physical native entry compilation with stage 0 and executes the result. */
final class NativeCompilerPhysicalEntryAssertions {
  private NativeCompilerPhysicalEntryAssertions() {}

  static void assertPhysicalEntry(
      List<String> dependencies,
      Map<String, String> sources,
      String root,
      String rootModule) throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependencies, root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, rootModule));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }
}
