package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Canonical report evidence for source compiled by the native test runner. */
final class NativeCompiledTestRunnerExampleTest {
  private static final String MANIFEST = """
      schema: 1
      package:
        name: "pkg"
        version: "1.0.0"
        profile: "bootstrap-1"
      targets:
        - kind: "deployable"
          name: "test"
          root: "src/Test.w"
          module: "pkg.test"
          sources:
            - "src/Test.w"
          test: true
      dependencies: []
      capabilities: []
      """;
  private static final String TWO_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/Test.w\"");
  private static final String THREE_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/Test.w\"");
  private static final String FOUR_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n      - \"src/Test.w\"");
  private static final String FIVE_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n"
          + "      - \"src/D.w\"\n      - \"src/Test.w\"");
  private static final String PASSING = """
      module pkg.test;
      classical class SourceTest {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING = PASSING.replace("assert(true);", "assert(false);");
  private static final String IMPORTED = """
      module pkg.helper;
      classical class Helper {
        public const long ANSWER = 7;
      }
      """;
  private static final String IMPORTED_TWO = """
      module pkg.second;
      classical class Second {
        public const long SECOND = 11;
      }
      """;
  private static final String IMPORTED_THREE = """
      module pkg.third;
      classical class Third {
        public const long THIRD = 13;
      }
      """;
  private static final String IMPORTED_FOUR = """
      module pkg.fourth;
      classical class Fourth {
        public const long FOURTH = 17;
      }
      """;
  private static final String IMPORTING = """
      module pkg.test;
      import pkg.helper;
      classical class SourceTest {
        entry void main() {
          assert(true);
        }
      }
      """;

  @Test
  void compiledSourcesProduceCanonicalArtifactReports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    assertCanonicalReport(runner, PASSING, 0);
    assertCanonicalReport(runner, FAILING, 1);
  }

  @Test
  void compilesTheManifestRootWithItsLocalImport() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/Test.w", IMPORTING));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "Test.w", IMPORTING), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(TWO_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(TWO_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void compilesTheManifestRootWithTwoLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.helper;
        import pkg.second;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(THREE_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(THREE_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void compilesTheManifestRootWithThreeLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.helper;
        import pkg.second;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "C.w", IMPORTED_THREE,
            "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(FOUR_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(FOUR_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void compilesTheManifestRootWithFourLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.fourth;
        import pkg.helper;
        import pkg.second;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/D.w", IMPORTED_FOUR),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "C.w", IMPORTED_THREE,
            "D.w", IMPORTED_FOUR, "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(FIVE_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(FIVE_SOURCE_MANIFEST, sources, new byte[0])));
  }

  private static void assertCanonicalReport(
      Program runner, String source, int expectedFailures) throws Exception {
    Program expectedProgram = new WheelerCompiler().compileModuleFiles(
        Map.of("Test.w", source), "pkg.test");
    byte[] expectedArtifact = new BytecodeWriter().write(expectedProgram);
    byte[] compiledReport = execute(runner, descriptor(source, new byte[0]));
    byte[] artifactReport = execute(runner, descriptor(source, expectedArtifact));

    assertArrayEquals(artifactReport, compiledReport);
    assertEquals(expectedFailures, compiledReport[36]);
  }

  private static byte[] descriptor(String source, byte[] artifact) {
    return descriptor(
        MANIFEST,
        List.of(new NativeTestSourcePlan.Source("src/Test.w", source)),
        artifact);
  }

  private static byte[] descriptor(
      String manifest, List<NativeTestSourcePlan.Source> sources, byte[] artifact) {
    byte[] plan = NativeTestSourcePlan.write(sources);
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0).putShort((short) 1).array());
    writeShortText(input, "pkg");
    writeShortText(input, "1.0.0");
    writeShortText(input, "test");
    writeBytes(input, manifest.getBytes(StandardCharsets.UTF_8));
    writeBytes(input, NativeTestManifestInput.emptyLock(manifest));
    writeBytes(input, plan);
    input.write(1);
    writeShortText(input, "test::source");
    writeBytes(input, artifact);
    return input.toByteArray();
  }

  private static void writeShortText(ByteArrayOutputStream output, String text) {
    byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeBytes(ByteArrayOutputStream output, byte[] bytes) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(bytes.length).array());
    output.writeBytes(bytes);
  }

  private static byte[] execute(Program runner, byte[] input) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner, input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }
}
