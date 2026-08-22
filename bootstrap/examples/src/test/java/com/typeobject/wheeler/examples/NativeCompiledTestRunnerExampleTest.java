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
  private static final String PASSING = """
      module pkg.test;
      classical class SourceTest {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING = PASSING.replace("assert(true);", "assert(false);");

  @Test
  void compiledSourcesProduceCanonicalArtifactReports() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    assertCanonicalReport(runner, PASSING, 0);
    assertCanonicalReport(runner, FAILING, 1);
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
    byte[] plan = NativeTestSourcePlan.write(List.of(
        new NativeTestSourcePlan.Source("src/Test.w", source)));
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0).putShort((short) 1).array());
    writeShortText(input, "pkg");
    writeShortText(input, "1.0.0");
    writeShortText(input, "test");
    writeBytes(input, MANIFEST.getBytes(StandardCharsets.UTF_8));
    writeBytes(input, NativeTestManifestInput.emptyLock(MANIFEST));
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
