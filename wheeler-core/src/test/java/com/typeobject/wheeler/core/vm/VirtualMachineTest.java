package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.ProgramFixtures;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Disassembler;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import org.junit.jupiter.api.Test;

class VirtualMachineTest {
  @Test
  void callsForwardAndInverseBodies() {
    VirtualMachine machine = new VirtualMachine(ProgramFixtures.counter());

    for (int i = 0; i < 7; i++) {
      machine.step();
    }
    assertEquals(2, machine.global("count"));

    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(0, machine.global("count"));
  }

  @Test
  void rewindRestoresExactInitialMachineState() {
    VirtualMachine machine = new VirtualMachine(ProgramFixtures.counter());
    MachineSnapshot initial = machine.snapshot();
    machine.run();

    while (machine.historySize() > 0) {
      machine.rewindOne();
    }

    assertEquals(initial, machine.snapshot());
    assertThrows(VmTrap.class, machine::rewindOne);
  }

  @Test
  void loggedWriteRestoresDestroyedValue() {
    Program program = singleFunction(
        List.of(
            Instruction.of(Opcode.SET_LOGGED, 0, 99),
            Instruction.of(Opcode.HALT)));
    VirtualMachine machine = new VirtualMachine(program);

    machine.step();
    assertEquals(99, machine.global("value"));
    machine.rewindOne();
    assertEquals(7, machine.global("value"));
  }

  @Test
  void commitCreatesARewindHorizon() {
    Program program = singleFunction(
        List.of(
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.COMMIT),
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.HALT)));
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();

    machine.rewindOne();
    machine.rewindOne();
    assertEquals(8, machine.global("value"));
    assertThrows(VmTrap.class, machine::rewindOne);
  }

  @Test
  void historyExhaustionTrapsBeforeTheNextMutation() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        false,
        List.of(
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program(
        "Bounded",
        0,
        List.of(new Global("value", 7)),
        List.of(main),
        1,
        10);
    VirtualMachine machine = new VirtualMachine(program);

    machine.step();
    assertThrows(VmTrap.class, machine::step);

    assertEquals(8, machine.global("value"));
    assertEquals(MachineStatus.TRAPPED, machine.status());
  }

  @Test
  void overflowTrapsWithoutMutatingData() {
    Program program = new Program(
        "Overflow",
        0,
        List.of(new Global("value", Long.MAX_VALUE)),
        List.of(new FunctionBody(
            0,
            "main",
            false,
            0,
            List.of(),
            false,
            List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.HALT)),
            List.of())));
    VirtualMachine machine = new VirtualMachine(program);

    assertThrows(VmTrap.class, machine::step);
    assertEquals(Long.MAX_VALUE, machine.global("value"));
    assertEquals(0, machine.historySize());
  }

  @Test
  void typedLocalsAndBoundedControlFlowRoundTripAndRewind() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.BOOLEAN,
            ValueType.SIGNED),
        false,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.LOCAL_CONST, 1, 5),
            Instruction.of(Opcode.LOCAL_CONST, 2, 1),
            Instruction.of(Opcode.LOCAL_LT, 3, 0, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 3, 10),
            Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 4, 0),
            Instruction.of(Opcode.LOCAL_ADD, 4, 4, 0),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 4),
            Instruction.of(Opcode.LOCAL_ADD, 0, 0, 2),
            Instruction.of(Opcode.JUMP, 3),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program source = new Program(
        "LocalLoop",
        0,
        List.of(new Global("sum", 0)),
        List.of(main),
        100,
        100);
    byte[] artifact = new BytecodeWriter().write(source);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(5, decoded.function(0).localCount());
    assertTrue(new Disassembler().disassemble(decoded).contains(
        "locals=[signed, signed, signed, boolean, signed]"));
    VirtualMachine machine = new VirtualMachine(decoded);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(10, machine.global("sum"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void valueCallTransfersParametersResultAndRewindsFrames() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED),
        false,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 4),
            Instruction.of(Opcode.LOCAL_CONST, 1, 5),
            Instruction.of(Opcode.CALL_VALUE, 1, 0, 2, 2),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 2),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody add = new FunctionBody(
        1,
        "add",
        false,
        2,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED),
        true,
        List.of(
            Instruction.of(Opcode.LOCAL_ADD, 2, 0, 1),
            Instruction.of(Opcode.RETURN_VALUE, 2)),
        List.of());
    Program program = new Program(
        "ValueCall",
        0,
        List.of(new Global("result", 0)),
        List.of(main, add),
        100,
        100);
    VirtualMachine machine = new VirtualMachine(program);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(9, machine.global("result"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void generatedArithmeticProgramsRoundTripThroughHistory() {
    Random random = new Random(7);
    for (int sample = 0; sample < 100; sample++) {
      List<Instruction> instructions = new ArrayList<>();
      for (int i = 0; i < 25; i++) {
        long value = random.nextInt(1_000);
        instructions.add(Instruction.of(
            random.nextBoolean() ? Opcode.ADD_CONST : Opcode.XOR_CONST, 0, value));
      }
      instructions.add(Instruction.of(Opcode.HALT));
      VirtualMachine machine = new VirtualMachine(singleFunction(instructions));
      MachineSnapshot initial = machine.snapshot();
      machine.run();
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  private static Program singleFunction(List<Instruction> instructions) {
    return new Program(
        "Test",
        0,
        List.of(new Global("value", 7)),
        List.of(new FunctionBody(
            0, "main", false, 0, List.of(), false, instructions, List.of())));
  }
}
