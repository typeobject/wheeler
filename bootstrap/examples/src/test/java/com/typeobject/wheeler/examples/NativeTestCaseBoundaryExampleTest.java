package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeTestRunnerInput.discoveredDescriptors;
import static com.typeobject.wheeler.examples.NativeTestRunnerInput.execute;
import static com.typeobject.wheeler.examples.NativeTestSourceFixtures.MANIFEST;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.NativeTestReportOracle.ReportCase;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Complete terminal-case execution with bounded host batches, not reduced source inputs. */
final class NativeTestCaseBoundaryExampleTest {
  private static final String RUNNER = "%064x".formatted(1);

  private record Fixture(List<NativeTestSourcePlan.Source> sources, List<ReportCase> cases) {}

  @Test
  void admitsTwoHundredFiftyFiveDiscoveredCasesAndRejectsTheNext() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    byte[] report = execute(runner, metadataOnly(discoveredSource(255)));
    assertEquals(255, Byte.toUnsignedInt(report[32]));
    assertEquals(0, report[33]);
    assertRejected(runner, metadataOnly(discoveredSource(256)));
  }

  @Test
  void admitsTwoHundredFiftyFiveParameterRowsAndRejectsTheNext() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    byte[] report = execute(runner, metadataOnly(parameterRows(255)));
    assertEquals(255, Byte.toUnsignedInt(report[32]));
    assertEquals(0, report[33]);
    assertRejected(runner, metadataOnly(parameterRows(256)));
  }

  @Test
  void comparesACompleteNativeReportWithIndependentStageZeroExecution() throws Exception {
    Fixture fixture = fixture(1);
    byte[] actual = execute(NativeCoverageRunExampleTest.nativeTestRunner(),
        discoveredDescriptors(MANIFEST, fixture.sources(), List.of()));
    assertArrayEquals(NativeTestReportOracle.summary(RUNNER, fixture.cases()), actual);
  }

  @ParameterizedTest(name = "executes terminal case shard {0}/4")
  @ValueSource(ints = {0, 1, 2, 3})
  @Timeout(value = 2, unit = TimeUnit.MINUTES)
  void executesEveryTerminalCaseThroughDisjointIdentityShards(int shardIndex) throws Exception {
    Fixture fixture = fixture(255);
    List<List<ReportCase>> partitions = new ArrayList<>();
    for (int index = 0; index < 4; index++) {
      partitions.add(new ArrayList<>());
    }
    for (ReportCase testcase : fixture.cases()) {
      byte[] identity = HexFormat.of().parseHex(testcase.caseIdentity());
      // The canonical hexadecimal identity modulo four is its final two bits.
      partitions.get(Byte.toUnsignedInt(identity[31]) % 4).add(testcase);
    }
    assertEquals(255, partitions.stream().mapToInt(List::size).sum());
    assertTrue(partitions.stream().noneMatch(List::isEmpty));

    byte[] input = discoveredDescriptors(MANIFEST, fixture.sources(), List.of());
    input[0] = (byte) shardIndex;
    input[2] = 4;
    byte[] actual = execute(NativeCoverageRunExampleTest.nativeTestRunner(), input);
    List<ReportCase> selected = partitions.get(shardIndex);
    assertArrayEquals(NativeTestReportOracle.summary(RUNNER, selected), actual);
    assertEquals(selected.size(), Byte.toUnsignedInt(actual[32]));
    assertEquals(selected.size(), Byte.toUnsignedInt(actual[34]));
    assertEquals(0, actual[36]);
  }

  private static Fixture fixture(int count) throws Exception {
    String source = discoveredSource(count);
    var sources = List.of(new NativeTestSourcePlan.Source("src/Test.w", source));
    var cases = new WheelerCompiler().compilePackageTests(
        Map.of("Test.w", source), Map.of(), "pkg.test");
    assertEquals(count, cases.size());
    assertEquals("pkg.test::case000", cases.getFirst().name());
    assertEquals("pkg.test::case%03d".formatted(count - 1), cases.getLast().name());

    // Each fixture body is one assertion. Stage 0 supplies the independent
    // entry artifact and execution. Native selection still compiles every case.
    Program reference = new WheelerCompiler().compileModuleFiles(Map.of("Test.w", """
        module pkg.test;
        classical class BoundedTests {
          entry void main() { assert(true); }
        }
        """), "pkg.test");
    var coverage = new SemanticCoverage();
    var execution = new WheelerRuntime().executeObserved(reference, coverage);
    assertEquals(1, coverage.successfulAssertions());
    String executionIdentity = NativeTestReportOracle.executionIdentity(execution);
    String artifactIdentity = sha256(new BytecodeWriter().write(reference));
    String manifestIdentity = new PackageManifestParser().parse(MANIFEST).identity();
    String sourceIdentity = sha256(NativeTestSourcePlan.write(sources));
    var identities = new HashSet<String>();
    var expected = new ArrayList<ReportCase>();
    for (var testcase : cases) {
      String name = "test::" + testcase.name().substring("pkg.test::".length());
      String identity = NativeTestReportOracle.caseIdentity(manifestIdentity, sourceIdentity, name);
      assertTrue(identities.add(identity), name);
      expected.add(new ReportCase("pkg", "1.0.0", name, identity, sourceIdentity,
          artifactIdentity, 0, "", "", coverage.successfulAssertions(), execution.workflowSteps(),
          executionIdentity, coverage.identity()));
    }
    return new Fixture(sources, List.copyOf(expected));
  }

  private static String sha256(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }

  private static void assertRejected(Program runner, byte[] input) {
    var rejected = VirtualMachine.withBinaryInput(runner, input, 39);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(rejected));
    assertArrayEquals(new byte[39], rejected.hostOutput());
  }

  private static String discoveredSource(int count) {
    StringBuilder source = new StringBuilder("""
        module pkg.test;
        classical class BoundedTests {
        """);
    for (int index = 0; index < count; index++) {
      source.append("  test void case")
          .append(index / 100)
          .append(index / 10 % 10)
          .append(index % 10)
          .append("() { assert(true); }\n");
    }
    return source.append("}\n").toString();
  }

  private static String parameterRows(int count) {
    StringBuilder source = new StringBuilder("""
        module pkg.test;
        classical class BoundedRows {
          test void rows(long input) cases(
        """);
    for (int index = 0; index < count; index++) {
      if (0 < index) {
        source.append(", ");
      }
      source.append(index);
    }
    return source.append(") { assert(true); }\n}\n").toString();
  }

  private static byte[] metadataOnly(String source) {
    byte[] input = discoveredDescriptors(MANIFEST,
        List.of(new NativeTestSourcePlan.Source("src/Test.w", source)), List.of());
    input[input.length - 1] = (byte) 252;
    return input;
  }
}
