package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
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
      module pkg.pass;
      classical class CoverageSubject {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING_SUBJECT = """
      module pkg.fail;
      classical class FailingSubject {
        entry void main() {
          assert(false);
        }
      }
      """;
  private static final String RUNTIME_FAILURE_SUBJECT = """
      module pkg.runtime;
      classical class RuntimeFailureSubject {
        entry void main() {
          long index = 0;
          while (index < 5000) limit 5000 {
            index += 1;
          }
        }
      }
      """;
  private static final String TEST_MANIFEST = """
      schema: 1
      package:
        name: "pkg"
        version: "1.0.0"
        profile: "bootstrap-1"
      targets:
        - kind: "deployable"
          name: "test"
          root: "src/Pass.w"
          module: "pkg.pass"
          sources:
            - "src/Fail.w"
            - "src/Pass.w"
            - "src/Runtime.w"
          test: true
      dependencies: []
      capabilities: []
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
  void nativeRunnerReducesTransportDescriptors() throws Exception {
    assertEquals(
        TEST_MANIFEST,
        new PackageManifestParser().parse(TEST_MANIFEST).canonicalText());
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] passing = NativeModuleCompilerHarness.compile(compiler, List.of(), SUBJECT);
    byte[] failing = NativeModuleCompilerHarness.compile(compiler, List.of(), FAILING_SUBJECT);
    byte[] runtimeFailure = NativeModuleCompilerHarness.compile(
        compiler, List.of(), RUNTIME_FAILURE_SUBJECT);
    byte[] input = twoCaseInput(0, 1, SUBJECT, passing, FAILING_SUBJECT, failing);
    VirtualMachine machine = VirtualMachine.withBinaryInput(nativeTestRunner(), input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expectedTwoCaseReport(passing, failing), machine.hostOutput());
    assertArrayEquals(
        expectedThreeCaseReport(passing, failing, runtimeFailure),
        executeTests(threeCaseInput(passing, failing, runtimeFailure)));
    assertArrayEquals(expectedEmptyReport(), executeTests(emptyCaseInput()));

    byte[] truncated = java.util.Arrays.copyOf(input, input.length - 1);
    VirtualMachine invalid = VirtualMachine.withBinaryInput(nativeTestRunner(), truncated, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());

    byte[] overLimit = input.clone();
    overLimit[
        31
            + TEST_MANIFEST.getBytes(StandardCharsets.UTF_8).length
            + testLock().length
            + targetSourcePlan().length] = 65;
    VirtualMachine invalidCount = VirtualMachine.withBinaryInput(nativeTestRunner(), overLimit, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidCount));
    assertArrayEquals(new byte[39], invalidCount.hostOutput());

    byte[] missingPackage = input.clone();
    missingPackage[4] = 0;
    VirtualMachine invalidMetadata = VirtualMachine.withBinaryInput(
        nativeTestRunner(), missingPackage, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidMetadata));
    assertArrayEquals(new byte[39], invalidMetadata.hostOutput());

    byte[] wrongVersion = input.clone();
    wrongVersion[9] = (byte) '2';
    VirtualMachine invalidVersion = VirtualMachine.withBinaryInput(
        nativeTestRunner(), wrongVersion, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidVersion));
    assertArrayEquals(new byte[39], invalidVersion.hostOutput());

    byte[] wrongManifest = input.clone();
    wrongManifest[23 + TEST_MANIFEST.indexOf("pkg")] = (byte) 'q';
    VirtualMachine invalidManifest = VirtualMachine.withBinaryInput(
        nativeTestRunner(), wrongManifest, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidManifest));
    assertArrayEquals(new byte[39], invalidManifest.hostOutput());

    int lockStart = 27 + TEST_MANIFEST.getBytes(StandardCharsets.UTF_8).length;
    byte[] wrongLockRoot = input.clone();
    wrongLockRoot[lockStart + 17] = wrongLockRoot[lockStart + 17] == '0' ? (byte) '1' : (byte) '0';
    VirtualMachine invalidLock = VirtualMachine.withBinaryInput(
        nativeTestRunner(), wrongLockRoot, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidLock));
    assertArrayEquals(new byte[39], invalidLock.hostOutput());

    for (byte[] invalidSelection : List.of(
        NativeTestManifestInput.replace(
            input, TEST_MANIFEST, "src/Pass.w", "src/Xass.w"),
        NativeTestManifestInput.replace(
            input, TEST_MANIFEST, "deployable", "xxxloyable"))) {
      VirtualMachine invalidTarget = VirtualMachine.withBinaryInput(
          nativeTestRunner(), invalidSelection, 39);
      assertThrows(
          VmTrap.class,
          () -> CompilerMachineRunner.runWithoutRewindHistory(invalidTarget));
      assertArrayEquals(new byte[39], invalidTarget.hostOutput());
    }

    int sourcePlanStart = lockStart + testLock().length + 4;
    byte[] emptySourcePlan = input.clone();
    emptySourcePlan[sourcePlanStart + 3] = 0;
    VirtualMachine invalidSourceCount = VirtualMachine.withBinaryInput(
        nativeTestRunner(), emptySourcePlan, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidSourceCount));
    assertArrayEquals(new byte[39], invalidSourceCount.hostOutput());

    byte[] absoluteSourcePath = input.clone();
    absoluteSourcePath[sourcePlanStart + 8] = (byte) '/';
    VirtualMachine invalidSourcePath = VirtualMachine.withBinaryInput(
        nativeTestRunner(), absoluteSourcePath, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidSourcePath));
    assertArrayEquals(new byte[39], invalidSourcePath.hostOutput());

    byte[] unselectedSourcePath = input.clone();
    unselectedSourcePath[sourcePlanStart + 8] = (byte) 'x';
    VirtualMachine invalidSourceSelection = VirtualMachine.withBinaryInput(
        nativeTestRunner(), unselectedSourcePath, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidSourceSelection));
    assertArrayEquals(new byte[39], invalidSourceSelection.hostOutput());

    byte[] mismatchedRootModule = input.clone();
    int passSource = NativeTestSourcePlan.payloadOffset(targetSourcePlan(), "src/Pass.w");
    mismatchedRootModule[sourcePlanStart + passSource + "module pkg.".length()] = (byte) 'x';
    VirtualMachine invalidRootModule = VirtualMachine.withBinaryInput(
        nativeTestRunner(), mismatchedRootModule, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidRootModule));
    assertArrayEquals(new byte[39], invalidRootModule.hostOutput());

    byte[] malformedSourceModule = input.clone();
    malformedSourceModule[sourcePlanStart + 22 + "module pkg".length()] = (byte) '/';
    VirtualMachine invalidSourceModule = VirtualMachine.withBinaryInput(
        nativeTestRunner(), malformedSourceModule, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidSourceModule));
    assertArrayEquals(new byte[39], invalidSourceModule.hostOutput());

    byte[] duplicateSourceModule = input.clone();
    byte[] passModuleSuffix = "pass".getBytes(StandardCharsets.UTF_8);
    System.arraycopy(
        passModuleSuffix,
        0,
        duplicateSourceModule,
        sourcePlanStart + 22 + "module pkg.".length(),
        passModuleSuffix.length);
    VirtualMachine invalidModuleSet = VirtualMachine.withBinaryInput(
        nativeTestRunner(), duplicateSourceModule, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidModuleSet));
    assertArrayEquals(new byte[39], invalidModuleSet.hostOutput());

    String importedSubject = SUBJECT.replace(
        "module pkg.pass;\n",
        "module pkg.pass;\nimport pkg.fail;\n");
    assertArrayEquals(
        expectedEmptyReport(),
        executeTests(descriptorHeader(
            0, 1, 0, targetSourcePlan(importedSubject)).toByteArray()));
    String importingFailingSubject = FAILING_SUBJECT.replace(
        "module pkg.fail;\n",
        "module pkg.fail;\nimport pkg.pass;\n");
    byte[] cyclicImports = descriptorHeader(
        0, 1, 0, targetSourcePlan(importingFailingSubject, importedSubject)).toByteArray();
    VirtualMachine invalidCycle = VirtualMachine.withBinaryInput(
        nativeTestRunner(), cyclicImports, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidCycle));
    assertArrayEquals(new byte[39], invalidCycle.hostOutput());

    for (String invalidSubject : List.of(
        importedSubject.replace("import pkg.fail;", "import pkg.xail;"),
        importedSubject.replace("import pkg.fail;", "import pkg.fail;\nimport pkg.fail;"),
        importedSubject.replace(
            "import pkg.fail;",
            "import pkg.runtime;\nimport pkg.fail;"))) {
      byte[] invalidImports = descriptorHeader(
          0, 1, 0, targetSourcePlan(invalidSubject)).toByteArray();
      VirtualMachine invalidImport = VirtualMachine.withBinaryInput(
          nativeTestRunner(), invalidImports, 39);
      assertThrows(
          VmTrap.class,
          () -> CompilerMachineRunner.runWithoutRewindHistory(invalidImport));
      assertArrayEquals(new byte[39], invalidImport.hostOutput());
    }

    byte[] malformedSource = input.clone();
    malformedSource[sourcePlanStart + 22] = (byte) 0xff;
    VirtualMachine invalidSourceText = VirtualMachine.withBinaryInput(
        nativeTestRunner(), malformedSource, 39);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(invalidSourceText));
    assertArrayEquals(new byte[39], invalidSourceText.hostOutput());

    for (byte[] invalidCases : List.of(
        invalidCaseInput(passing, failing, true),
        invalidCaseInput(passing, failing, false))) {
      VirtualMachine invalidDescriptors = VirtualMachine.withBinaryInput(
          nativeTestRunner(), invalidCases, 39);
      assertThrows(
          VmTrap.class,
          () -> CompilerMachineRunner.runWithoutRewindHistory(invalidDescriptors));
      assertArrayEquals(new byte[39], invalidDescriptors.hostOutput());
    }

    int shardCount = 257;
    int passingShard = caseShard(SUBJECT, shardCount);
    int failingShard = caseShard(FAILING_SUBJECT, shardCount);
    int runtimeShard = caseShard(RUNTIME_FAILURE_SUBJECT, shardCount);
    assertNotEquals(passingShard, failingShard);
    assertNotEquals(passingShard, runtimeShard);
    assertNotEquals(failingShard, runtimeShard);
    int emptyShard = NativeTestShards.firstUnused(
        shardCount, passingShard, failingShard, runtimeShard);

    byte[] invalidFailing = failing.clone();
    invalidFailing[0] ^= 1;
    assertArrayEquals(
        expectedSelectedReport(passing, SUBJECT, true),
        executeTests(twoCaseInput(
            passingShard, shardCount, SUBJECT, passing, FAILING_SUBJECT, invalidFailing)));
    assertArrayEquals(
        expectedSelectedReport(failing, FAILING_SUBJECT, false),
        executeTests(twoCaseInput(
            failingShard, shardCount, SUBJECT, passing, FAILING_SUBJECT, failing)));
    assertArrayEquals(
        expectedSelectedReport(
            runtimeFailure,
            RUNTIME_FAILURE_SUBJECT,
            false,
            "WTEST005",
            "native artifact execution failed",
            0),
        executeTests(twoCaseInput(
            runtimeShard,
            shardCount,
            SUBJECT,
            passing,
            RUNTIME_FAILURE_SUBJECT,
            runtimeFailure)));
    assertArrayEquals(
        expectedSelectedReport(
            invalidFailing,
            FAILING_SUBJECT,
            false,
            "WTEST004",
            "native artifact verification failed",
            0),
        executeTests(twoCaseInput(
            failingShard,
            shardCount,
            SUBJECT,
            passing,
            FAILING_SUBJECT,
            invalidFailing)));
    byte[] invalidPassing = passing.clone();
    invalidPassing[0] ^= 1;
    assertArrayEquals(
        expectedEmptyReport(),
        executeTests(twoCaseInput(
            emptyShard,
            shardCount,
            SUBJECT,
            invalidPassing,
            FAILING_SUBJECT,
            invalidFailing)));
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

  private static byte[] twoCaseInput(
      int shardIndex,
      int shardCount,
      String passingSource,
      byte[] passing,
      String failingSource,
      byte[] failing) {
    ByteArrayOutputStream input = descriptorHeader(shardIndex, shardCount, 2);
    if (caseName(passingSource).compareTo(caseName(failingSource)) < 0) {
      writeCaseInput(input, caseName(passingSource), passing);
      writeCaseInput(input, caseName(failingSource), failing);
    } else {
      writeCaseInput(input, caseName(failingSource), failing);
      writeCaseInput(input, caseName(passingSource), passing);
    }
    return input.toByteArray();
  }

  private static byte[] threeCaseInput(
      byte[] passing, byte[] failing, byte[] runtimeFailure) {
    ByteArrayOutputStream input = descriptorHeader(0, 1, 3);
    writeCaseInput(input, caseName(FAILING_SUBJECT), failing);
    writeCaseInput(input, caseName(SUBJECT), passing);
    writeCaseInput(input, caseName(RUNTIME_FAILURE_SUBJECT), runtimeFailure);
    return input.toByteArray();
  }

  private static byte[] emptyCaseInput() {
    return descriptorHeader(0, 1, 0).toByteArray();
  }

  private static byte[] invalidCaseInput(
      byte[] passing, byte[] failing, boolean duplicate) {
    ByteArrayOutputStream input = descriptorHeader(0, 1, 2);
    if (duplicate) {
      writeCaseInput(input, "test::same", passing);
      writeCaseInput(input, "test::same", failing);
    } else {
      writeCaseInput(input, caseName(SUBJECT), passing);
      writeCaseInput(input, caseName(FAILING_SUBJECT), failing);
    }
    return input.toByteArray();
  }

  private static ByteArrayOutputStream descriptorHeader(
      int shardIndex, int shardCount, int caseCount) {
    return descriptorHeader(shardIndex, shardCount, caseCount, targetSourcePlan());
  }

  private static ByteArrayOutputStream descriptorHeader(
      int shardIndex, int shardCount, int caseCount, byte[] sourcePlan) {
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) shardIndex).putShort((short) shardCount).array());
    writeShortText(input, "pkg");
    writeShortText(input, "1.0.0");
    writeShortText(input, "test");
    byte[] manifest = TEST_MANIFEST.getBytes(StandardCharsets.UTF_8);
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(manifest.length).array());
    input.writeBytes(manifest);
    byte[] lock = testLock();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(lock.length).array());
    input.writeBytes(lock);
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(sourcePlan.length).array());
    input.writeBytes(sourcePlan);
    input.write(caseCount);
    return input;
  }

  private static byte[] testLock() {
    return NativeTestManifestInput.emptyLock(TEST_MANIFEST);
  }

  private static void writeShortText(ByteArrayOutputStream output, String value) {
    byte[] encoded = value.getBytes(StandardCharsets.UTF_8);
    output.write(encoded.length);
    output.writeBytes(encoded);
  }

  private static void writeCaseInput(
      ByteArrayOutputStream output, String caseName, byte[] artifact) {
    writeShortText(output, caseName);
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(artifact.length).array());
    output.writeBytes(artifact);
  }

  private static String caseName(String source) {
    if (source.equals(SUBJECT)) {
      return "test::pass";
    }
    if (source.equals(FAILING_SUBJECT)) {
      return "test::fail";
    }
    return "test::runtime";
  }

  private static byte[] targetSourcePlan() {
    return targetSourcePlan(SUBJECT);
  }

  private static byte[] targetSourcePlan(String passSource) {
    return targetSourcePlan(FAILING_SUBJECT, passSource);
  }

  private static byte[] targetSourcePlan(String failSource, String passSource) {
    return NativeTestSourcePlan.write(List.of(
        new NativeTestSourcePlan.Source("src/Fail.w", failSource),
        new NativeTestSourcePlan.Source("src/Pass.w", passSource),
        new NativeTestSourcePlan.Source("src/Runtime.w", RUNTIME_FAILURE_SUBJECT)));
  }

  private static byte[] executeTests(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(nativeTestRunner(), input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static byte[] expectedEmptyReport() throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 0);
    return withSummary(report.digest(), 0, 0);
  }

  private static byte[] expectedSelectedReport(
      byte[] artifact, String source, boolean passing) throws Exception {
    return expectedSelectedReport(
        artifact,
        source,
        passing,
        passing ? "" : "WTEST003",
        passing ? "" : "native test assertion failed",
        1);
  }

  private static byte[] expectedSelectedReport(
      byte[] artifact,
      String source,
      boolean passing,
      String diagnosticCode,
      String diagnosticMessage,
      int assertionCount)
      throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 1);
    digestCasePrefix(report, artifact, source);
    if (passing) {
      digestField(report, "PASS");
      digestField(report, "");
      digestField(report, "");
      digestInteger(report, 1);
      digestInteger(report, 0);
      digestField(report, passExecutionIdentity());
      digestField(report, passCoverageIdentity());
    } else {
      digestField(report, "FAIL");
      digestField(report, diagnosticCode);
      digestField(report, diagnosticMessage);
      digestInteger(report, assertionCount);
      digestInteger(report, 0);
      digestField(report, "");
      digestField(report, "");
    }
    return withSummary(report.digest(), 1, passing ? 1 : 0);
  }

  private static byte[] expectedTwoCaseReport(byte[] passing, byte[] failing) throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 2);
    digestFailedCase(
        report, failing, FAILING_SUBJECT, "WTEST003", "native test assertion failed", 1);
    digestPassingCase(report, passing);
    return withSummary(report.digest(), 2, 1);
  }

  private static byte[] expectedThreeCaseReport(
      byte[] passing, byte[] failing, byte[] runtimeFailure) throws Exception {
    MessageDigest report = MessageDigest.getInstance("SHA-256");
    digestField(report, "wheeler.test-report/2");
    digestField(report, "%064x".formatted(1));
    digestInteger(report, 3);
    digestFailedCase(
        report, failing, FAILING_SUBJECT, "WTEST003", "native test assertion failed", 1);
    digestPassingCase(report, passing);
    digestFailedCase(
        report,
        runtimeFailure,
        RUNTIME_FAILURE_SUBJECT,
        "WTEST005",
        "native artifact execution failed",
        0);
    return withSummary(report.digest(), 3, 1);
  }

  private static void digestPassingCase(MessageDigest report, byte[] artifact)
      throws Exception {
    digestCasePrefix(report, artifact, SUBJECT);
    digestField(report, "PASS");
    digestField(report, "");
    digestField(report, "");
    digestInteger(report, 1);
    digestInteger(report, 0);
    digestField(report, passExecutionIdentity());
    digestField(report, passCoverageIdentity());
  }

  private static void digestFailedCase(
      MessageDigest report,
      byte[] artifact,
      String source,
      String code,
      String message,
      int assertions)
      throws Exception {
    digestCasePrefix(report, artifact, source);
    digestField(report, "FAIL");
    digestField(report, code);
    digestField(report, message);
    digestInteger(report, assertions);
    digestInteger(report, 0);
    digestField(report, "");
    digestField(report, "");
  }

  private static byte[] withSummary(byte[] identity, int selected, int passed) {
    return ByteBuffer.allocate(39).order(ByteOrder.LITTLE_ENDIAN)
        .put(identity)
        .putShort((short) selected)
        .putShort((short) passed)
        .putShort((short) (selected - passed))
        .put((byte) (selected == passed ? 1 : 0))
        .array();
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
      MessageDigest report, byte[] artifact, String source) throws Exception {
    String sourceIdentity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(targetSourcePlan()));
    String caseName = caseName(source);
    digestField(report, "pkg");
    digestField(report, "1.0.0");
    digestField(report, caseName);
    digestField(report, derivedCaseIdentity(sourceIdentity, caseName));
    digestField(report, sourceIdentity);
    digestField(report, HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(artifact)));
  }

  private static int caseShard(String source, int shardCount) throws Exception {
    String sourceIdentity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(targetSourcePlan()));
    String identity = derivedCaseIdentity(sourceIdentity, caseName(source));
    return new BigInteger(identity, 16).mod(BigInteger.valueOf(shardCount)).intValueExact();
  }

  private static String derivedCaseIdentity(String sourceIdentity, String caseName)
      throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    digestField(digest, "wheeler.test-case/1");
    digestField(digest, HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(
            TEST_MANIFEST.getBytes(StandardCharsets.UTF_8))));
    digestField(digest, caseName);
    digestField(digest, sourceIdentity);
    return HexFormat.of().formatHex(digest.digest());
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

  static Program nativeTestRunner() throws Exception {
    return NativeTestRunnerProgram.program();
  }

  private static Program oneCaseRunner() throws Exception {
    var modules = runtimeModules();
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put(
        "BootstrapCoverageFragments.w",
        RuntimeSources.read("runtime/BootstrapCoverageFragments.w"));
    modules.put("CoverageReducer.w", RuntimeSources.read("runtime/CoverageReducer.w"));
    for (String source : List.of(
        "TestArtifactExecutionIdentity", "TestCoverageIdentity",
        "TestExecutionIdentity", "TestIdentityText", "TestReportIdentity", "TestArtifactReport")) {
      modules.put(source + ".w", RuntimeSources.read("runtime/testing/" + source + ".w"));
    }
    modules.put(
        "NativeOneCaseTestRunner.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeOneCaseTestRunner.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.runners.native_one_case_test_runner");
  }

  private static Program artifactExecutionIdentity() throws Exception {
    var modules = runtimeModules();
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
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
    modules.put("ArtifactMetadata.w", RuntimeSources.read("runtime/ArtifactMetadata.w"));
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
