package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for noninstrumenting typed transition coverage. */
class SemanticCoverageTest {
  @Test
  void collectionPreservesStateAndKeepsExecutionAndRewindDistinct() {
    Program program = reversibleProgram(0);
    SemanticCoverage coverage = new SemanticCoverage();
    VirtualMachine observed = new VirtualMachine(program, coverage);
    VirtualMachine plain = new VirtualMachine(program);
    var initial = observed.snapshot();

    observed.run();
    plain.run();

    assertEquals(plain.snapshot(), observed.snapshot());
    while (observed.historySize() > 0) {
      observed.rewindOne();
      plain.rewindOne();
    }
    assertEquals(initial, observed.snapshot());
    assertEquals(plain.snapshot(), observed.snapshot());
    String report = coverage.canonicalReport();
    assertTrue(report.contains("\"direction\":\"forward\""));
    assertTrue(report.contains("\"branch\":\"taken\""));
    assertTrue(report.contains("\"direction\":\"inverse\""));
    assertTrue(report.contains("\"direction\":\"rewind_forward\""));
    assertTrue(report.contains("\"direction\":\"rewind_inverse\""));
    assertEquals(1, coverage.successfulAssertions());

    SemanticCoverage repeated = new SemanticCoverage();
    VirtualMachine rerun = new VirtualMachine(program, repeated);
    rerun.run();
    while (rerun.historySize() > 0) {
      rerun.rewindOne();
    }
    assertEquals(report, repeated.canonicalReport());
    assertEquals(coverage.identity(), repeated.identity());

    SemanticCoverage fallthrough = new SemanticCoverage();
    new VirtualMachine(reversibleProgram(1), fallthrough).run();
    assertTrue(fallthrough.canonicalReport().contains("\"branch\":\"fallthrough\""));
  }

  private static Program reversibleProgram(long condition) {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.BOOLEAN),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, condition),
            Instruction.of(Opcode.JUMP_IF_ZERO, 0, 3),
            Instruction.of(Opcode.NOP),
            Instruction.of(Opcode.UNCALL, 1),
            Instruction.of(Opcode.EXPECT_EQ, 0, -1),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody update = new FunctionBody(
        1,
        "update",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    return new Program("Coverage", 0, List.of(new Global("value", 0)), List.of(main, update));
  }
}
