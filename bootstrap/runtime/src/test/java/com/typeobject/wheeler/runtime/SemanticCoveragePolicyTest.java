package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Exercises content-identified semantic coverage exclusions and thresholds. */
final class SemanticCoveragePolicyTest {
  @Test
  void everyExclusionAndThresholdChangesVisiblePolicyAndEvaluationIdentity() {
    SemanticCoverage coverage = coverage();
    SemanticCoveragePolicy baseline = new SemanticCoveragePolicy(Set.of(), Set.of(), 2, 1);
    SemanticCoveragePolicy excluded = new SemanticCoveragePolicy(
        Set.of(), Set.of("ADD_CONST"), 1, 1);
    SemanticCoveragePolicy understated = new SemanticCoveragePolicy(Set.of(), Set.of(), 2, 2);

    SemanticCoveragePolicy.Evaluation accepted = baseline.evaluate(coverage);
    SemanticCoveragePolicy.Evaluation filtered = excluded.evaluate(coverage);
    SemanticCoveragePolicy.Evaluation failed = understated.evaluate(coverage);
    assertTrue(accepted.passed());
    assertTrue(filtered.passed());
    assertFalse(failed.passed());
    assertEquals(2, accepted.includedPoints());
    assertEquals(1, filtered.includedPoints());
    assertEquals(1, filtered.excludedPoints());
    assertNotEquals(baseline.identity(), excluded.identity());
    assertNotEquals(baseline.identity(), understated.identity());
    assertNotEquals(accepted.identity(), filtered.identity());
    assertNotEquals(accepted.identity(), failed.identity());
    assertTrue(filtered.canonicalReport().contains("\"excluded_opcodes\":[\"ADD_CONST\"]"));
    assertTrue(failed.canonicalReport().contains("\"minimum_hits_per_point\":2"));
    assertTrue(failed.canonicalReport().contains("\"passed\":false"));
  }

  @Test
  void policyIdentityIgnoresCallerSetOrderButNotSemanticAxes() {
    HashSet<String> first = new HashSet<>(List.of("inverse", "rewind_forward"));
    HashSet<String> second = new HashSet<>(List.of("rewind_forward", "inverse"));
    SemanticCoveragePolicy left = new SemanticCoveragePolicy(
        first, Set.of("HALT", "ADD_CONST"), 0, 0);
    SemanticCoveragePolicy right = new SemanticCoveragePolicy(
        second, Set.of("ADD_CONST", "HALT"), 0, 0);
    assertEquals(left.identity(), right.identity());
    assertEquals(
        left.evaluate(coverage()).canonicalReport(),
        right.evaluate(coverage()).canonicalReport());
  }

  @Test
  void evaluationNeverMutatesTheUnderlyingSemanticReport() {
    SemanticCoverage coverage = coverage();
    String report = coverage.canonicalReport();
    String identity = coverage.identity();
    new SemanticCoveragePolicy(Set.of("forward"), Set.of(), 0, 0).evaluate(coverage);
    assertEquals(report, coverage.canonicalReport());
    assertEquals(identity, coverage.identity());
  }

  @Test
  void malformedNamesAndUnboundedThresholdsFailBeforeEvaluation() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoveragePolicy(Set.of(" bad"), Set.of(), 0, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoveragePolicy(Set.of(), Set.of(), -1, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoveragePolicy(Set.of(), Set.of(), 0, 1_000_000_001L));
  }

  private static SemanticCoverage coverage() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program(
        "CoveragePolicy", 0, List.of(new Global("value", 0)), List.of(main));
    SemanticCoverage coverage = new SemanticCoverage();
    new VirtualMachine(program, coverage).run();
    return coverage;
  }
}
