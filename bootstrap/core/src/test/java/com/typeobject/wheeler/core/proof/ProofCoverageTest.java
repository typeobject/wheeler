package com.typeobject.wheeler.core.proof;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exercises separate proof lookup, obligation, rule, acceptance, and rejection evidence. */
final class ProofCoverageTest {
  @Test
  void acceptedAndRejectedCertificatesRetainDifferentNominalStages() {
    Program program = program();
    ProofCoverage coverage = new ProofCoverage();
    ProofKernel.verify(program, new ProofCertificate(
        0, "inverse", ProofRule.GENERATED_INVERSE, 0, -1), coverage);
    assertThrows(
        BytecodeException.class,
        () -> ProofKernel.verify(program, new ProofCertificate(
            1, "short", ProofRule.STATIC_STEP_BOUND, 0, 1), coverage));

    String report = coverage.canonicalReport();
    assertTrue(report.contains("\"stage\":\"LOOKUP\""));
    assertTrue(report.contains("\"stage\":\"OBLIGATION\""));
    assertTrue(report.contains("\"stage\":\"RULE_EXECUTION\""));
    assertTrue(report.contains("\"stage\":\"ACCEPTANCE\""));
    assertTrue(report.contains("\"stage\":\"REJECTION\""));
    assertTrue(report.contains("\"rule\":\"GENERATED_INVERSE\""));
    assertTrue(report.contains("\"rule\":\"STATIC_STEP_BOUND\""));
  }

  @Test
  void observationOrderIsExactAndCoverageIsDeterministic() {
    ProofCertificate certificate = new ProofCertificate(
        0, "inverse", ProofRule.GENERATED_INVERSE, 0, -1);
    List<ProofObserver.Observation> observations = new ArrayList<>();
    ProofKernel.verify(program(), certificate, observations::add);
    assertEquals(
        List.of(
            ProofObserver.Stage.LOOKUP,
            ProofObserver.Stage.OBLIGATION,
            ProofObserver.Stage.RULE_EXECUTION,
            ProofObserver.Stage.ACCEPTANCE),
        observations.stream().map(ProofObserver.Observation::stage).toList());
    assertEquals(List.of(0L, 1L, 2L, 3L),
        observations.stream().map(ProofObserver.Observation::sequence).toList());

    ProofCoverage first = new ProofCoverage();
    ProofCoverage second = new ProofCoverage();
    ProofKernel.verify(program(), certificate, first);
    ProofKernel.verify(program(), certificate, second);
    assertEquals(first.canonicalReport(), second.canonicalReport());
    assertEquals(first.identity(), second.identity());
    ProofCoverage rejected = new ProofCoverage();
    assertThrows(
        BytecodeException.class,
        () -> ProofKernel.verify(program(), new ProofCertificate(
            1, "short", ProofRule.STATIC_STEP_BOUND, 0, 1), rejected));
    assertNotEquals(first.identity(), rejected.identity());
  }

  private static Program program() {
    FunctionBody function = new FunctionBody(
        0,
        "update",
        true,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    return new Program(
        "ProofCoverage", 0, List.of(new Global("value", 0)), List.of(function));
  }
}
