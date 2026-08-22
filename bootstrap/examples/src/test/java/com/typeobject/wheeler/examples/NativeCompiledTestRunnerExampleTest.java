package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
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
  private static final String SIX_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n"
          + "      - \"src/D.w\"\n      - \"src/E.w\"\n      - \"src/Test.w\"");
  private static final String SEVEN_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n"
          + "      - \"src/D.w\"\n      - \"src/E.w\"\n      - \"src/F.w\"\n"
          + "      - \"src/Test.w\"");
  private static final String EIGHT_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n"
          + "      - \"src/D.w\"\n      - \"src/E.w\"\n      - \"src/F.w\"\n"
          + "      - \"src/G.w\"\n      - \"src/Test.w\"");
  private static final String NINE_SOURCE_MANIFEST = MANIFEST.replace(
      "      - \"src/Test.w\"",
      "      - \"src/A.w\"\n      - \"src/B.w\"\n      - \"src/C.w\"\n"
          + "      - \"src/D.w\"\n      - \"src/E.w\"\n      - \"src/F.w\"\n"
          + "      - \"src/G.w\"\n      - \"src/H.w\"\n      - \"src/Test.w\"");
  private static final String PASSING = """
      module pkg.test;
      classical class SourceTest {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING = PASSING.replace("assert(true);", "assert(false);");
  private static final String DECLARED_TEST = """
      module pkg.test;
      classical class DeclaredTest {
        test void passes() {
          assert(true);
        }
      }
      """;
  private static final String DECLARED_TESTS = """
      module pkg.test;
      classical class DeclaredTests {
        test void beta() {
          assert(true);
        }
        test void alpha() {
          assert(true);
        }
      }
      """;
  private static final String PARAMETERIZED_TESTS = """
      module pkg.test;
      classical class ParameterizedTests {
        test void longs(long input) cases(-1, 0, 2) {
          assert(true);
        }
        test void flags(boolean input) cases(false, true) {
          assert(true);
        }
      }
      """;
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
  private static final String IMPORTED_FIVE = """
      module pkg.fifth;
      classical class Fifth {
        public const long FIFTH = 19;
      }
      """;
  private static final String IMPORTED_SIX = """
      module pkg.sixth;
      classical class Sixth {
        public const long SIXTH = 23;
      }
      """;
  private static final String IMPORTED_SEVEN = """
      module pkg.seventh;
      classical class Seventh {
        public const long SEVENTH = 29;
      }
      """;
  private static final String IMPORTED_EIGHT = """
      module pkg.eighth;
      classical class Eighth {
        public const long EIGHTH = 31;
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
  void discoversCanonicalLongAndBooleanParameterRows() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var testCases = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", PARAMETERIZED_TESTS), Map.of(), "pkg.test");
    var artifacts = testCases.stream()
        .map(testcase -> new NamedArtifact(
            "test::" + testcase.name().substring(testcase.name().lastIndexOf("::") + 2),
            new BytecodeWriter().write(testcase.program())))
        .toList();
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", PARAMETERIZED_TESTS));
    byte[] report = execute(runner, descriptors(MANIFEST, sources, artifacts));

    assertEquals(5, report[32]);
    assertEquals(5, report[34]);
  }

  @Test
  void rejectsArtifactsWithTheWrongParameterRow() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var testCases = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", PARAMETERIZED_TESTS), Map.of(), "pkg.test");
    var artifacts = new java.util.ArrayList<NamedArtifact>();
    for (int index = 0; index < testCases.size(); index++) {
      int artifactIndex = index;
      if (index == 0) {
        artifactIndex = 1;
      } else if (index == 1) {
        artifactIndex = 0;
      }
      var testcase = testCases.get(index);
      artifacts.add(new NamedArtifact(
          "test::" + testcase.name().substring(testcase.name().lastIndexOf("::") + 2),
          new BytecodeWriter().write(testCases.get(artifactIndex).program())));
    }
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", PARAMETERIZED_TESTS));
    VirtualMachine invalid = VirtualMachine.withBinaryInput(
        runner, descriptors(MANIFEST, sources, artifacts), 39);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());
  }

  @Test
  void rejectsDuplicateNativeParameterRows() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var testCases = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", PARAMETERIZED_TESTS), Map.of(), "pkg.test");
    var artifacts = testCases.stream()
        .map(testcase -> new NamedArtifact(
            "test::" + testcase.name().substring(testcase.name().lastIndexOf("::") + 2),
            new BytecodeWriter().write(testcase.program())))
        .toList();
    String duplicateRows = PARAMETERIZED_TESTS.replace(
        "cases(false, true)", "cases(false, false)");
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", duplicateRows));

    VirtualMachine invalid = VirtualMachine.withBinaryInput(
        runner, descriptors(MANIFEST, sources, artifacts), 39);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());
  }

  @Test
  void rejectsArtifactProgramsOutsideTheRootModule() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String foreignSource = DECLARED_TEST.replace("module pkg.test;", "module pkg.other;");
    byte[] foreignArtifact = new BytecodeWriter().write(new WheelerCompiler()
        .compilePackageTests(Map.of("Test.w", foreignSource), Map.of(), "pkg.other")
        .getFirst().program());
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", DECLARED_TEST));
    VirtualMachine invalid = VirtualMachine.withBinaryInput(
        runner, descriptor(MANIFEST, sources, foreignArtifact, "test::passes"), 39);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());
  }

  @Test
  void discoversOneParameterlessRootTestNatively() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var testCase = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", DECLARED_TEST), Map.of(), "pkg.test").getFirst();
    byte[] artifact = new BytecodeWriter().write(testCase.program());
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", DECLARED_TEST));
    byte[] report = execute(runner, descriptor(MANIFEST, sources, artifact, "test::passes"));

    assertEquals(1, report[32]);
    assertEquals(1, report[34]);
    VirtualMachine invalid = VirtualMachine.withBinaryInput(
        runner, descriptor(MANIFEST, sources, artifact, "test::other"), 39);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());
  }

  @Test
  void discoversMultipleRootTestsInCanonicalDescriptorOrder() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    var testCases = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", DECLARED_TESTS), Map.of(), "pkg.test");
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", DECLARED_TESTS));
    byte[] report = execute(runner, descriptors(MANIFEST, sources, List.of(
        new NamedArtifact("test::alpha", new BytecodeWriter().write(testCases.get(0).program())),
        new NamedArtifact("test::beta", new BytecodeWriter().write(testCases.get(1).program())))));

    assertEquals(2, report[32]);
    assertEquals(2, report[34]);
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

  @Test
  void compilesTheManifestRootWithFiveLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.fifth;
        import pkg.fourth;
        import pkg.helper;
        import pkg.second;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/D.w", IMPORTED_FOUR),
        new NativeTestSourcePlan.Source("src/E.w", IMPORTED_FIVE),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "C.w", IMPORTED_THREE,
            "D.w", IMPORTED_FOUR, "E.w", IMPORTED_FIVE, "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(SIX_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(SIX_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void compilesTheManifestRootWithSixLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.fifth;
        import pkg.fourth;
        import pkg.helper;
        import pkg.second;
        import pkg.sixth;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/D.w", IMPORTED_FOUR),
        new NativeTestSourcePlan.Source("src/E.w", IMPORTED_FIVE),
        new NativeTestSourcePlan.Source("src/F.w", IMPORTED_SIX),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "C.w", IMPORTED_THREE,
            "D.w", IMPORTED_FOUR, "E.w", IMPORTED_FIVE, "F.w", IMPORTED_SIX,
            "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(SEVEN_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(SEVEN_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void compilesTheManifestRootWithSevenLocalImports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.fifth;
        import pkg.fourth;
        import pkg.helper;
        import pkg.second;
        import pkg.seventh;
        import pkg.sixth;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/D.w", IMPORTED_FOUR),
        new NativeTestSourcePlan.Source("src/E.w", IMPORTED_FIVE),
        new NativeTestSourcePlan.Source("src/F.w", IMPORTED_SIX),
        new NativeTestSourcePlan.Source("src/G.w", IMPORTED_SEVEN),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("A.w", IMPORTED, "B.w", IMPORTED_TWO, "C.w", IMPORTED_THREE,
            "D.w", IMPORTED_FOUR, "E.w", IMPORTED_FIVE, "F.w", IMPORTED_SIX,
            "G.w", IMPORTED_SEVEN, "Test.w", root), "pkg.test"));

    assertArrayEquals(
        execute(runner, descriptor(EIGHT_SOURCE_MANIFEST, sources, artifact)),
        execute(runner, descriptor(EIGHT_SOURCE_MANIFEST, sources, new byte[0])));
  }

  @Test
  void rejectsCallerNamedNativeEntryCases() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    byte[] input = descriptor(PASSING, new byte[0]);
    input[input.length - 5] = (byte) 'x';
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner, input, 39);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[39], machine.hostOutput());
  }

  @Test
  void rejectsSourceCountsBeyondTheFixedCompilerProfile() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String root = IMPORTING.replace("import pkg.helper;", """
        import pkg.eighth;
        import pkg.fifth;
        import pkg.fourth;
        import pkg.helper;
        import pkg.second;
        import pkg.seventh;
        import pkg.sixth;
        import pkg.third;""");
    var sources = List.of(
        new NativeTestSourcePlan.Source("src/A.w", IMPORTED),
        new NativeTestSourcePlan.Source("src/B.w", IMPORTED_TWO),
        new NativeTestSourcePlan.Source("src/C.w", IMPORTED_THREE),
        new NativeTestSourcePlan.Source("src/D.w", IMPORTED_FOUR),
        new NativeTestSourcePlan.Source("src/E.w", IMPORTED_FIVE),
        new NativeTestSourcePlan.Source("src/F.w", IMPORTED_SIX),
        new NativeTestSourcePlan.Source("src/G.w", IMPORTED_SEVEN),
        new NativeTestSourcePlan.Source("src/H.w", IMPORTED_EIGHT),
        new NativeTestSourcePlan.Source("src/Test.w", root));
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        runner, descriptor(NINE_SOURCE_MANIFEST, sources, new byte[0]), 39);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[39], machine.hostOutput());
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
    return descriptor(manifest, sources, artifact, "test::entry");
  }

  private static byte[] descriptor(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      byte[] artifact,
      String caseName) {
    return descriptors(manifest, sources, List.of(new NamedArtifact(caseName, artifact)));
  }

  private static byte[] descriptors(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      List<NamedArtifact> cases) {
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
    input.write(cases.size());
    for (NamedArtifact testcase : cases) {
      writeShortText(input, testcase.name());
      writeBytes(input, testcase.artifact());
    }
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

  private record NamedArtifact(String name, byte[] artifact) {}

  private static byte[] execute(Program runner, byte[] input) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner, input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }
}
