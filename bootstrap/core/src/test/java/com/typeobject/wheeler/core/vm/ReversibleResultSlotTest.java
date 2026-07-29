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
