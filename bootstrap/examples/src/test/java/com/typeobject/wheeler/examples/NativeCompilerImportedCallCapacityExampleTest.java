package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for imported calls at the bounded helper-body ceiling. */
final class NativeCompilerImportedCallCapacityExampleTest {
  @Test
  void compilesSixtyFourCallsAcrossSevenOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    List<Owner> owners = List.of(
        new Owner("alpha", "Alpha", 4),
        new Owner("beta", "Beta", 3),
        new Owner("delta", "Delta", 3),
        new Owner("epsilon", "Epsilon", 3),
        new Owner("eta", "Eta", 3),
        new Owner("gamma", "Gamma", 3),
        new Owner("zeta", "Zeta", 3));
    List<String> dependencySources = owners.stream()
        .map(NativeCompilerImportedCallCapacityExampleTest::ownerSource)
        .toList();
    String root = rootSource(owners, 64);

    Map<String, String> sources = new LinkedHashMap<>();
    for (int owner = 0; owner < owners.size(); owner += 1) {
      sources.put(owners.get(owner).className() + ".w", dependencySources.get(owner));
    }
    sources.put("UseCalls.w", root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        sources, "example.use_calls");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, dependencySources, root));
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(
            compiler,
            List.of(
                dependencySources.get(6),
                dependencySources.get(5),
                dependencySources.get(4),
                dependencySources.get(3),
                dependencySources.get(2),
                dependencySources.get(1),
                dependencySources.get(0)),
            root));

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals(24, decoded.functions().size());
    assertEquals(256, decoded.functions().get(22).localCount());
    assertEquals("example.use_calls::accepted", decoded.functions().get(22).name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        dependencySources,
        rootSource(owners, 65));
  }

  private static String ownerSource(Owner owner) {
    StringBuilder source = new StringBuilder("module example.")
        .append(owner.module())
        .append(";\nclassical class ")
        .append(owner.className())
        .append(" {\n");
    for (int helper = 0; helper < owner.helperCount(); helper += 1) {
      source.append("  public boolean ")
          .append(owner.module())
          .append(helper)
          .append("(long value) {\n    return value == ")
          .append(helper)
          .append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
  }

  private static String rootSource(List<Owner> owners, int callCount) {
    StringBuilder source = new StringBuilder("module example.use_calls;\n");
    for (Owner owner : owners) {
      source.append("import example.").append(owner.module()).append(";\n");
    }
    source.append("classical class UseCalls {\n")
        .append("  public boolean accepted(long value) {\n");
    for (int call = 0; call + 1 < callCount; call += 1) {
      Owner owner = owners.get(call % owners.size());
      int helper = call % owner.helperCount();
      source.append("    if (")
          .append(owner.module())
          .append(helper)
          .append("(value)) { return ")
          .append(call % 2 == 0)
          .append("; }\n");
    }
    Owner last = owners.get((callCount - 1) % owners.size());
    int lastHelper = (callCount - 1) % last.helperCount();
    return source.append("    return ")
        .append(last.module())
        .append(lastHelper)
        .append("(value);\n  }\n}\n")
        .toString();
  }

  private record Owner(String module, String className, int helperCount) {}
}
