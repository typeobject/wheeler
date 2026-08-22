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
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Source-to-native evidence for Wheeler-owned transition collection and reduction. */
final class NativeCoverageRunExampleTest {
  private static final String SUBJECT = """
      classical class CoverageSubject {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING_SUBJECT = """
      classical class FailingSubject {
        entry void main() {
          assert(false);
        }
      }
      """;
  private static final String GLOBAL_SUBJECT = """
      classical class GlobalSubject {
        state long first = 7;
        state long second = -4;

        entry void main() {}
      }
      """;
  private static final String UNSUPPORTED_SUBJECT = """
      classical class UnsupportedCoverageSubject {
        entry void main() {
          long value = 1;
          assert(value == 1);
        }
      }
      """;
  private static final byte[] EXPECTED = ("""
      {"points":[{"branch":"none","count":1,"direction":"forward","function":0,"instruction":0,"opcode":"LOCAL_CONST"},{"branch":"none","count":1,"direction":"forward","function":0,"instruction":1,"opcode":"EXPECT_TRUE"},{"branch":"none","count":1,"direction":"forward","function":0,"instruction":2,"opcode":"HALT"}],"profile":"wheeler-transition-coverage-1"}
      """).getBytes(StandardCharsets.UTF_8);

  @Test
  void nativeCompilerAndVmPublishCoverageWithoutHostTransitionRows() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(), SUBJECT);
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner(), artifact, 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(3, machine.global("transitionCount"));
    assertEquals(EXPECTED.length, machine.global("reportLength"));
    assertEquals(0, machine.global("finalGlobal"));
    assertArrayEquals(EXPECTED, machine.hostOutput());
  }

  @Test
  void nativeCoverageIdentityMatchesStageZero() throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    digest.update("wheeler-transition-coverage-1\0".getBytes(StandardCharsets.UTF_8));
    byte[] expected = digest.digest(EXPECTED);
    VirtualMachine machine = VirtualMachine.withBinaryInput(coverageIdentity(), EXPECTED, 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expected, machine.hostOutput());

    VirtualMachine oversized = VirtualMachine.withBinaryInput(
        coverageIdentity(), new byte[32_769], 32);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(oversized));
    assertArrayEquals(new byte[32], oversized.hostOutput());
  }

  @Test
  void nativeOneCaseRunnerPublishesStageZeroReportIdentity() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(), SUBJECT);
    VirtualMachine machine = VirtualMachine.withBinaryInput(oneCaseRunner(), artifact, 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expectedOneCaseReport(artifact), machine.hostOutput());

    byte[] failingArtifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(), FAILING_SUBJECT);
    VirtualMachine failure = VirtualMachine.withBinaryInput(
        oneCaseRunner(), failingArtifact, 32);
    CompilerMachineRunner.runWithoutRewindHistory(failure);
    assertArrayEquals(expectedFailedOneCaseReport(failingArtifact), failure.hostOutput());
  }

  @Test
  void nativeTwoCaseRunnerSortsOppositeCompletionOrder() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] passing = NativeModuleCompilerHarness.compile(compiler, List.of(), SUBJECT);
    byte[] failing = NativeModuleCompilerHarness.compile(compiler, List.of(), FAILING_SUBJECT);
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(passing.length).array());
    input.writeBytes(passing);
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(failing.length).array());
    input.writeBytes(failing);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        twoCaseRunner(), input.toByteArray(), 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expectedTwoCaseReport(passing, failing), machine.hostOutput());

    byte[] truncated = java.util.Arrays.copyOf(input.toByteArray(), input.size() - 1);
    VirtualMachine invalid = VirtualMachine.withBinaryInput(twoCaseRunner(), truncated, 32);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[32], invalid.hostOutput());
  }

  @Test
  void nativeArtifactExecutionIdentityMatchesStageZero() throws Exception {
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compile(GLOBAL_SUBJECT));
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        artifactExecutionIdentity(), artifact, 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);

    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    digestField(digest, "wheeler.test-execution/1");
    digestField(digest, "GlobalSubject");
    digestField(digest, "CLASSICAL");
    digestInteger(digest, 2);
    digestField(digest, "first");
    digestInteger(digest, 7);
    digestField(digest, "second");
    digestInteger(digest, -4);
    digestInteger(digest, 0);
    digestInteger(digest, 0);
    digestInteger(digest, 0);
    digestInteger(digest, 0);
    assertArrayEquals(digest.digest(), machine.hostOutput());
  }

  @Test
  void nativeArtifactMetadataProjectsProgramAndGlobalNames() throws Exception {
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compile(GLOBAL_SUBJECT));
    VirtualMachine machine = VirtualMachine.withBinaryInput(artifactMetadata(), artifact, 4096);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    ByteBuffer result = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    assertEquals("GlobalSubject", readText(result));
    assertEquals(0, Byte.toUnsignedInt(result.get()));
    assertEquals(2, Byte.toUnsignedInt(result.get()));
    assertEquals("first", readText(result));
    assertEquals("second", readText(result));
    assertEquals(0, result.remaining());

    artifact[0] ^= 1;
    VirtualMachine invalid = VirtualMachine.withBinaryInput(artifactMetadata(), artifact, 4096);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[4096], invalid.hostOutput());
  }

  @Test
  void nativeTestExecutionClassifiesValuesAndVerifierErrors() throws Exception {
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compile(GLOBAL_SUBJECT));
    VirtualMachine success = VirtualMachine.withBinaryInput(artifactRunner(), artifact, 89);
    CompilerMachineRunner.runWithoutRewindHistory(success);
    ByteBuffer successOutput = ByteBuffer.wrap(success.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    assertEquals(0, successOutput.get());
    assertEquals(1, successOutput.getLong());
    assertEquals(2, successOutput.getLong());
    assertEquals(7, successOutput.getLong());
    assertEquals(-4, successOutput.getLong());
    while (successOutput.position() < 81) {
      assertEquals(0, successOutput.getLong());
    }
    assertEquals(0, successOutput.getLong());

    artifact[0] ^= 1;
    VirtualMachine failure = VirtualMachine.withBinaryInput(artifactRunner(), artifact, 89);
    CompilerMachineRunner.runWithoutRewindHistory(failure);
    ByteBuffer failureOutput = ByteBuffer.wrap(failure.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    assertEquals(1, failureOutput.get());
    while (failureOutput.hasRemaining()) {
      assertEquals(0, failureOutput.getLong());
    }
  }

  @Test
  void unsupportedNativeTracePublishesNoPartialReport() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(), UNSUPPORTED_SUBJECT);
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner(), artifact, 32_768);

    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));

    assertEquals(0, machine.global("reportLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  private static Program coverageIdentity() throws Exception {
    var modules = new LinkedHashMap<String, String>();
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put(
        "TestCoverageIdentity.w",
        RuntimeSources.read("runtime/testing/TestCoverageIdentity.w"));
    modules.put(
        "NativeTestCoverageIdentity.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestCoverageIdentity.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.native_test_coverage_identity");
  }

  private static byte[] expectedTwoCaseReport(byte[] passing, byte[] failing) throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 2);
    digestCasePrefix(report, failing, 2, 3);
    digestField(report, "FAIL");
    digestField(report, "WTEST003");
    digestField(report, "native test assertion failed");
    digestInteger(report, 1);
    digestInteger(report, 0);
    digestField(report, "");
    digestField(report, "");
    digestCasePrefix(report, passing, 4, 5);
    digestField(report, "PASS");
    digestField(report, "");
    digestField(report, "");
    digestInteger(report, 1);
    digestInteger(report, 0);
    digestField(report, passExecutionIdentity());
    digestField(report, passCoverageIdentity());
    return report.digest();
  }

  private static byte[] expectedFailedOneCaseReport(byte[] artifact) throws Exception {
    MessageDigest report = reportPrefix();
    digestField(report, HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(artifact)));
    digestField(report, "FAIL");
    digestField(report, "WTEST003");
    digestField(report, "native test assertion failed");
    digestInteger(report, 1);
    digestInteger(report, 0);
    digestField(report, "");
    digestField(report, "");
    return report.digest();
  }

  private static byte[] expectedOneCaseReport(byte[] artifact) throws Exception {
    MessageDigest report = reportPrefix();
    digestField(report, HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(artifact)));
    digestField(report, "PASS");
    digestField(report, "");
    digestField(report, "");
    digestInteger(report, 1);
    digestInteger(report, 0);
    digestField(report, passExecutionIdentity());
    digestField(report, passCoverageIdentity());
    return report.digest();
  }

  private static String passExecutionIdentity() throws Exception {
    MessageDigest execution = MessageDigest.getInstance("SHA-256");
    digestField(execution, "wheeler.test-execution/1");
    digestField(execution, "CoverageSubject");
    digestField(execution, "CLASSICAL");
    digestInteger(execution, 0);
    digestInteger(execution, 0);
    digestInteger(execution, 0);
    digestInteger(execution, 0);
    digestInteger(execution, 0);
    return HexFormat.of().formatHex(execution.digest());
  }

  private static String passCoverageIdentity() throws Exception {
    MessageDigest coverage = MessageDigest.getInstance("SHA-256");
    coverage.update("wheeler-transition-coverage-1\0".getBytes(StandardCharsets.UTF_8));
    return HexFormat.of().formatHex(coverage.digest(EXPECTED));
  }

  private static void digestCasePrefix(
      MessageDigest report, byte[] artifact, int caseValue, int sourceValue) throws Exception {
    digestField(report, "pkg");
    digestField(report, "1");
    digestField(report, "test");
    digestField(report, "%064x".formatted(caseValue));
    digestField(report, "%064x".formatted(sourceValue));
    digestField(report, HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(artifact)));
  }

  private static MessageDigest reportPrefix() throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 1);
    digestField(report, "pkg");
    digestField(report, "1");
    digestField(report, "test");
    digestField(report, "%064x".formatted(2));
    digestField(report, "%064x".formatted(3));
    return report;
  }

  private static Program twoCaseRunner() throws Exception {
    var modules = testRunnerModules();
    modules.put(
        "NativeTwoCaseTestRunner.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeTwoCaseTestRunner.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.runners.native_two_case_test_runner");
  }

  private static Program oneCaseRunner() throws Exception {
    var modules = testRunnerModules();
    modules.put(
        "NativeOneCaseTestRunner.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeOneCaseTestRunner.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.runners.native_one_case_test_runner");
  }

  private static LinkedHashMap<String, String> testRunnerModules() throws Exception {
    var modules = runtimeModules();
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put("BootstrapCoverageFragments.w",
        RuntimeSources.read("runtime/BootstrapCoverageFragments.w"));
    modules.put("CoverageReducer.w", RuntimeSources.read("runtime/CoverageReducer.w"));
    for (String source : List.of(
        "TestArtifactMetadata", "TestExecutionIdentity", "TestArtifactExecutionIdentity",
        "TestCoverageIdentity", "TestReportIdentity", "TestArtifactReport")) {
      modules.put(source + ".w", RuntimeSources.read("runtime/testing/" + source + ".w"));
    }
    return modules;
  }

  private static Program artifactExecutionIdentity() throws Exception {
    var modules = runtimeModules();
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put(
        "TestArtifactMetadata.w",
        RuntimeSources.read("runtime/testing/TestArtifactMetadata.w"));
    modules.put(
        "TestExecutionIdentity.w",
        RuntimeSources.read("runtime/testing/TestExecutionIdentity.w"));
    modules.put(
        "TestArtifactExecutionIdentity.w",
        RuntimeSources.read("runtime/testing/TestArtifactExecutionIdentity.w"));
    modules.put(
        "NativeTestArtifactExecutionIdentity.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestArtifactExecutionIdentity.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.native_test_artifact_execution_identity");
  }

  private static Program artifactMetadata() throws Exception {
    var modules = runtimeModules();
    modules.put(
        "TestArtifactMetadata.w",
        RuntimeSources.read("runtime/testing/TestArtifactMetadata.w"));
    modules.put(
        "NativeTestArtifactMetadata.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestArtifactMetadata.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.native_test_artifact_metadata");
  }

  private static void digestField(MessageDigest digest, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    digestInteger(digest, bytes.length);
    digest.update(bytes);
  }

  private static void digestInteger(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(8).putLong(value).array());
  }

  private static String readText(ByteBuffer input) {
    int length = Short.toUnsignedInt(input.getShort());
    byte[] value = new byte[length];
    input.get(value);
    return new String(value, StandardCharsets.UTF_8);
  }

  private static Program artifactRunner() throws Exception {
    var modules = runtimeModules();
    modules.put(
        "NativeTestArtifactRun.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestArtifactRun.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.native_test_artifact_run");
  }

  private static Program runner() throws Exception {
    var modules = runtimeModules();
    modules.put(
        "BootstrapCoverageFragments.w",
        RuntimeSources.read("runtime/BootstrapCoverageFragments.w"));
    modules.put("CoverageReducer.w", RuntimeSources.read("runtime/CoverageReducer.w"));
    modules.put(
        "NativeCoverageRun.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/runtime/NativeCoverageRun.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.runtime.native_coverage_run");
  }

  private static LinkedHashMap<String, String> runtimeModules() throws Exception {
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    CoreSources.addBinaryClosure(modules);
    modules.put(
        "AggregateInterpreter.w",
        RuntimeSources.read("runtime/AggregateInterpreter.w"));
    modules.put(
        "ArtifactExecution.w",
        RuntimeSources.read("runtime/ArtifactExecution.w"));
    modules.put("Interpreter.w", RuntimeSources.read("runtime/Interpreter.w"));
    modules.put("MapInterpreter.w", RuntimeSources.read("runtime/MapInterpreter.w"));
    modules.put("ResultSlots.w", RuntimeSources.read("runtime/ResultSlots.w"));
    modules.put("StorageInterpreter.w", RuntimeSources.read("runtime/StorageInterpreter.w"));
    modules.put("Utf8Interpreter.w", RuntimeSources.read("runtime/Utf8Interpreter.w"));
    return modules;
  }
}
