package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Compares physical native entry compilation with stage 0 and executes the result. */
final class NativeCompilerPhysicalEntryAssertions {
  private NativeCompilerPhysicalEntryAssertions() {}

  /** Uses the current physical closure rather than a copied import list. */
  static void assertCompilerEntry(String root) throws Exception {
    var header = SourceModuleInspection.inspect(root.getBytes(StandardCharsets.UTF_8));
    Map<String, String> sources = new TreeMap<>();
    for (String imported : header.imports()) {
      sources.putAll(CompilerSources.moduleClosure(imported));
    }
    List<String> dependencies = List.copyOf(sources.values());
    sources.put("Entry.w", root);
    assertPhysicalEntry(dependencies, sources, root, header.name());
  }

  static void assertPhysicalEntry(
      List<String> dependencies,
      Map<String, String> sources,
      String root,
      String rootModule) throws Exception {
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, rootModule));
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependencies, root);
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }
}
