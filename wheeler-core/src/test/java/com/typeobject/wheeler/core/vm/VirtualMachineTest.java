package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.ProgramFixtures;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
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
            List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.HALT)),
            List.of())));
    VirtualMachine machine = new VirtualMachine(program);

    assertThrows(VmTrap.class, machine::step);
    assertEquals(Long.MAX_VALUE, machine.global("value"));
    assertEquals(0, machine.historySize());
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
        List.of(new FunctionBody(0, "main", false, instructions, List.of())));
  }
}
