package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Execution coverage for history-independent reversible scalar result slots. */
class ReversibleResultSlotTest {
  @Test
  void fillsAndUnfillsMinusOneAcrossAHistoryCommit() {
    Program program = programWithEntry(List.of(
        Instruction.of(Opcode.LOCAL_CONST, 0, 0),
        Instruction.of(Opcode.LOCAL_CONST, 1, 0),
        Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 0, 0),
        Instruction.of(Opcode.COMMIT),
        Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 0, 0),
        Instruction.of(Opcode.HALT)));
    byte[] artifact = new BytecodeWriter().write(program);
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(List.of(0L, 0L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void preservesAParameterAcrossForwardAndInverseCalls() {
    FunctionBody identity = preservedIdentity();
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 42),
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.COMMIT),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("PreservedResult", 1, List.of(), List.of(identity, entry)));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(List.of(42L, 0L, 0L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void computesAResultAcrossForwardAndInverseCalls() {
    FunctionBody addEight = computedAdd(8);
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 34),
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.COMMIT),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("ComputedResult", 1, List.of(), List.of(addEight, entry)));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(List.of(34L, 0L, 0L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void computesFromTwoSourcesAcrossForwardAndInverseCalls() {
    FunctionBody add = computedSources();
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 34),
            Instruction.of(Opcode.LOCAL_CONST, 1, 8),
            Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 2, 2),
            Instruction.of(Opcode.COMMIT),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 2, 2),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("ComputedSourceResult", 1, List.of(), List.of(add, entry)));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(
        List.of(34L, 8L, 0L, 0L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void trappingComputedResultLeavesBothSlotsVacant() {
    FunctionBody addOne = computedAdd(1);
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, Long.MAX_VALUE),
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("TrappingComputedResult", 1, List.of(), List.of(addOne, entry)));

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertEquals("Arithmetic overflow in RESULT_FILL_BINARY", trap.getMessage());
    assertEquals(2, machine.snapshot().selectedFrames().size());
    assertEquals(
        List.of(Long.MAX_VALUE, 0L, 0L),
        machine.snapshot().selectedFrames().getFirst().locals());
    assertEquals(
        List.of(Long.MAX_VALUE, 0L, 0L),
        machine.snapshot().selectedFrames().getLast().locals());
  }

  @Test
  void wrongHeldComputedResultTrapsBeforeSlotMutation() {
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 34),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 2, 41),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("WrongComputedResult", 1, List.of(), List.of(computedAdd(8), entry)));

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertEquals(
        "Inverse result slot does not hold the expected computed result", trap.getMessage());
    assertEquals(List.of(34L, 1L, 41L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void wrongHeldTwoSourceResultTrapsBeforeSlotMutation() {
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 34),
            Instruction.of(Opcode.LOCAL_CONST, 1, 8),
            Instruction.of(Opcode.LOCAL_CONST, 2, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 41),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 2, 2),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("WrongComputedSources", 1, List.of(), List.of(computedSources(), entry)));

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertEquals(
        "Inverse result slot does not hold the expected computed result", trap.getMessage());
    assertEquals(
        List.of(34L, 8L, 1L, 41L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void wrongHeldSourceTrapsBeforeSlotMutation() {
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 42),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 2, 7),
            Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 1, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(
        new Program("WrongPreservedResult", 1, List.of(), List.of(preservedIdentity(), entry)));

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertEquals("Inverse result slot does not hold the expected source", trap.getMessage());
    assertEquals(List.of(42L, 1L, 7L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void wrongHeldConstantTrapsBeforeSlotMutation() {
    Program program = programWithEntry(List.of(
        Instruction.of(Opcode.LOCAL_CONST, 0, 1),
        Instruction.of(Opcode.LOCAL_CONST, 1, 7),
        Instruction.of(Opcode.UNCALL_RESULT_SLOT, 0, 0, 0, 0),
        Instruction.of(Opcode.HALT)));
    VirtualMachine machine = new VirtualMachine(program);

    VmTrap trap = assertThrows(VmTrap.class, machine::run);

    assertEquals(
        "Inverse result slot does not hold the expected constant", trap.getMessage());
    assertEquals(List.of(1L, 7L), machine.snapshot().selectedFrames().getFirst().locals());
  }

  @Test
  void verifierRejectsAResultTransitionOutsideItsImplicitSlot() {
    FunctionBody malformed = new FunctionBody(
        0,
        "malformed",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 1, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 1, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("MalformedResultSlot", 1, List.of(), List.of(malformed, entry))));

    assertEquals(
        "Invalid forward result slot body: malformed",
        failure.getMessage());
  }

  @Test
  void verifierRejectsAResultSourceThatIsNotAParameter() {
    FunctionBody malformed = new FunctionBody(
        0,
        "malformedSource",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 0, 1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 0, 1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("MalformedResultSource", 1, List.of(), List.of(malformed, entry))));

    assertEquals(
        "malformedSource[0] RESULT_FILL_SOURCE source result source is not a preserved parameter",
        failure.getMessage());
  }

  @Test
  void verifierRejectsAnUnknownResultBinaryOperation() {
    FunctionBody malformed = new FunctionBody(
        0,
        "malformedOperation",
        false,
        1,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_BINARY, 1, 0, Opcode.LOCAL_EQ.code(), 8),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_BINARY, 1, 0, Opcode.LOCAL_EQ.code(), 8),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("MalformedResultOperation", 1, List.of(), List.of(malformed, entry))));

    assertEquals(
        "malformedOperation[0] RESULT_FILL_BINARY operation "
            + "unsupported result binary operation",
        failure.getMessage());
  }

  @Test
  void verifierRejectsARightResultSourceThatIsNotAParameter() {
    Instruction fill = Instruction.of(
        Opcode.RESULT_FILL_BINARY_SOURCES, 2, 0, Opcode.LOCAL_ADD.code(), 2);
    FunctionBody malformed = new FunctionBody(
        0,
        "malformedRightSource",
        false,
        2,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)),
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("MalformedRightResultSource", 1, List.of(), List.of(malformed, entry))));

    assertEquals(
        "malformedRightSource[0] RESULT_FILL_BINARY_SOURCES right_source "
            + "right result source is not a preserved parameter",
        failure.getMessage());
  }

  @Test
  void verifierRejectsDifferentForwardAndInverseResultSources() {
    FunctionBody mismatched = new FunctionBody(
        0,
        "mismatchedSource",
        false,
        2,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 2, 0),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 2, 1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("MismatchedResultSource", 1, List.of(), List.of(mismatched, entry))));

    assertEquals(
        "Result slot relation has no exact inverse: mismatchedSource", failure.getMessage());
  }

  @Test
  void verifierRejectsAnArgumentAliasingItsResultSlot() {
    FunctionBody target = new FunctionBody(
        0,
        "aliased",
        false,
        1,
        List.of(ValueType.BOOLEAN, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 1, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 1, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.CALL_RESULT_SLOT, 0, 0, 1, 0),
            Instruction.of(Opcode.HALT)),
        List.of());

    BytecodeException failure = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(
            new Program("AliasedResultSlot", 1, List.of(), List.of(target, entry))));

    assertEquals(
        "main[2] CALL_RESULT_SLOT result_slot result slot call signature mismatch for aliased",
        failure.getMessage());
  }

  private static FunctionBody computedAdd(long immediate) {
    Instruction fill = Instruction.of(
        Opcode.RESULT_FILL_BINARY, 1, 0, Opcode.LOCAL_ADD.code(), immediate);
    return new FunctionBody(
        0,
        "addEight",
        false,
        1,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)),
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)));
  }

  private static FunctionBody computedSources() {
    Instruction fill = Instruction.of(
        Opcode.RESULT_FILL_BINARY_SOURCES, 2, 0, Opcode.LOCAL_ADD.code(), 1);
    return new FunctionBody(
        0,
        "add",
        false,
        2,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)),
        List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 2)));
  }

  private static FunctionBody preservedIdentity() {
    return new FunctionBody(
        0,
        "identity",
        false,
        1,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 1, 0),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_SOURCE, 1, 0),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 1)));
  }

  private static Program programWithEntry(List<Instruction> entryInstructions) {
    FunctionBody minusOne = new FunctionBody(
        0,
        "minusOne",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.SIGNED),
        ValueType.SIGNED,
        true,
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 0, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)),
        List.of(
            Instruction.of(Opcode.RESULT_FILL_CONSTANT, 0, -1),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0)));
    FunctionBody entry = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        entryInstructions,
        List.of());
    return new Program("ResultSlot", 1, List.of(), List.of(minusOne, entry));
  }
}
