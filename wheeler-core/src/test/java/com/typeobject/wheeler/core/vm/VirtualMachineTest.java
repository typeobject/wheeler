package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.ProgramFixtures;
import com.typeobject.wheeler.core.bytecode.ArrayType;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Disassembler;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.SliceType;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.bytecode.VariantType;
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
  void commitBlocksRewindButNotLaterInverseExecution() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(
            Instruction.of(Opcode.CALL, 1),
            Instruction.of(Opcode.COMMIT),
            Instruction.of(Opcode.UNCALL, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody increment = new FunctionBody(
        1,
        "increment",
        false,
        0,
        List.of(),
        null,
        List.of(
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.RETURN)),
        List.of(
            Instruction.of(Opcode.SUB_CONST, 0, 1),
            Instruction.of(Opcode.RETURN)));
    VirtualMachine machine = new VirtualMachine(new Program(
        "BarrierInverse", 0, List.of(new Global("value", 7)), List.of(main, increment)));

    machine.run();

    assertEquals(7, machine.global("value"));
    for (int step = 0; step < 4; step++) {
      machine.rewindOne();
    }
    assertEquals(8, machine.global("value"));
    assertThrows(VmTrap.class, machine::rewindOne);
  }

  @Test
  void checkpointRewindAndFreshExecutionAgreeWithUninterruptedExecution() {
    Program program = singleFunction(List.of(
        Instruction.of(Opcode.CHECKPOINT),
        Instruction.of(Opcode.ADD_CONST, 0, 5),
        Instruction.of(Opcode.HALT)));
    VirtualMachine uninterrupted = new VirtualMachine(program);
    uninterrupted.run();
    MachineSnapshot expected = uninterrupted.snapshot();

    VirtualMachine replayed = new VirtualMachine(program);
    replayed.run();
    while (replayed.historySize() > 0) {
      replayed.rewindOne();
    }
    replayed.run();

    assertEquals(expected, replayed.snapshot());
  }

  @Test
  void historyExhaustionTrapsBeforeTheNextMutation() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
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
            null,
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
        null,
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
  void immutableRecordConstructionAccessEqualityAndRewind() {
    RecordType point = new RecordType(
        0,
        "Point",
        List.of(
            new RecordType.Field("x", ValueType.SIGNED),
            new RecordType.Field("visible", ValueType.BOOLEAN)));
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED,
            ValueType.BOOLEAN,
            ValueType.record(0),
            ValueType.SIGNED,
            ValueType.BOOLEAN,
            ValueType.record(0),
            ValueType.BOOLEAN),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 7),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.RECORD_NEW, 2, 0, 0, 2),
            Instruction.of(Opcode.RECORD_GET, 3, 2, 0),
            Instruction.of(Opcode.RECORD_GET, 4, 2, 1),
            Instruction.of(Opcode.RECORD_NEW, 5, 0, 0, 2),
            Instruction.of(Opcode.LOCAL_EQ, 6, 2, 5),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 3),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program(
        "Records",
        com.typeobject.wheeler.core.bytecode.ProgramKind.CLASSICAL,
        0,
        List.of(new Global("result", 0)),
        List.of(point),
        List.of(),
        List.of(),
        List.of(),
        List.of(main),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        100,
        100);
    VirtualMachine machine = new VirtualMachine(program);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(7, machine.global("result"));
    assertEquals(1, machine.snapshot().records().size());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void taggedVariantConstructionSelectionEqualityAndRewind() {
    VariantType option = new VariantType(
        0,
        "Option",
        List.of(
            new VariantType.Case("None", List.of()),
            new VariantType.Case(
                "Some", List.of(new RecordType.Field("value", ValueType.SIGNED)))));
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED,
            ValueType.variant(0),
            ValueType.BOOLEAN,
            ValueType.SIGNED,
            ValueType.variant(0),
            ValueType.BOOLEAN),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 7),
            Instruction.of(Opcode.VARIANT_NEW, 1, 0, 1, 0, 1),
            Instruction.of(Opcode.VARIANT_TAG_EQ, 2, 1, 1),
            Instruction.of(Opcode.VARIANT_GET, 3, 1, 1, 0),
            Instruction.of(Opcode.VARIANT_NEW, 4, 0, 1, 0, 1),
            Instruction.of(Opcode.LOCAL_EQ, 5, 1, 4),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = Program.classical(
        "Variants", 0, List.of(), List.of(), List.of(option),
        List.of(), List.of(), List.of(main), List.of());
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(1, machine.snapshot().variants().size());
    assertEquals(List.of(7L), machine.snapshot().variants().getFirst().fields());
    assertEquals(1, machine.snapshot().frames().getFirst().local(2));
    assertEquals(7, machine.snapshot().frames().getFirst().local(3));
    assertEquals(1, machine.snapshot().frames().getFirst().local(5));
    for (int step = 0; step < 6; step++) {
      machine.rewindOne();
    }
    assertTrue(machine.snapshot().variants().isEmpty());
  }

  @Test
  void fixedArrayConstructionIndexEqualityBoundsAndRewind() {
    ArrayType triple = new ArrayType(0, ValueType.SIGNED, 3);
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.array(0),
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.array(0),
            ValueType.BOOLEAN),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 3),
            Instruction.of(Opcode.LOCAL_CONST, 1, 5),
            Instruction.of(Opcode.LOCAL_CONST, 2, 7),
            Instruction.of(Opcode.ARRAY_NEW, 3, 0, 0, 3),
            Instruction.of(Opcode.LOCAL_CONST, 4, 1),
            Instruction.of(Opcode.ARRAY_GET, 5, 3, 4),
            Instruction.of(Opcode.ARRAY_NEW, 6, 0, 0, 3),
            Instruction.of(Opcode.LOCAL_EQ, 7, 3, 6),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = Program.classical(
        "Arrays", 0, List.of(), List.of(), List.of(), List.of(triple),
        List.of(), List.of(main), List.of());
    VirtualMachine machine = new VirtualMachine(program);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(1, machine.snapshot().arrays().size());
    assertEquals(List.of(3L, 5L, 7L), machine.snapshot().arrays().getFirst().elements());
    assertEquals(5, machine.snapshot().frames().getFirst().local(5));
    assertEquals(1, machine.snapshot().frames().getFirst().local(7));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    FunctionBody outOfBounds = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED,
            ValueType.array(0), ValueType.SIGNED, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 3),
            Instruction.of(Opcode.LOCAL_CONST, 1, 5),
            Instruction.of(Opcode.LOCAL_CONST, 2, 7),
            Instruction.of(Opcode.ARRAY_NEW, 3, 0, 0, 3),
            Instruction.of(Opcode.LOCAL_CONST, 4, 3),
            Instruction.of(Opcode.ARRAY_GET, 5, 3, 4),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine trapped = new VirtualMachine(Program.classical(
        "Bounds", 0, List.of(), List.of(), List.of(), List.of(triple),
        List.of(), List.of(outOfBounds), List.of()));
    assertThrows(VmTrap.class, trapped::run);
    assertEquals(MachineStatus.TRAPPED, trapped.status());
    assertEquals(1, trapped.snapshot().arrays().size());
  }

  @Test
  void borrowedSliceChecksRangeIndexAndRewinds() {
    ArrayType values = new ArrayType(0, ValueType.SIGNED, 4);
    SliceType slice = new SliceType(0, ValueType.SIGNED);
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED,
            ValueType.array(0), ValueType.SIGNED, ValueType.SIGNED,
            ValueType.slice(0), ValueType.SIGNED, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 2),
            Instruction.of(Opcode.LOCAL_CONST, 1, 4),
            Instruction.of(Opcode.LOCAL_CONST, 2, 6),
            Instruction.of(Opcode.LOCAL_CONST, 3, 8),
            Instruction.of(Opcode.ARRAY_NEW, 4, 0, 0, 4),
            Instruction.of(Opcode.LOCAL_CONST, 5, 1),
            Instruction.of(Opcode.LOCAL_CONST, 6, 2),
            Instruction.of(Opcode.SLICE_NEW, 7, 0, 4, 5, 6),
            Instruction.of(Opcode.LOCAL_CONST, 8, 1),
            Instruction.of(Opcode.SLICE_GET, 9, 7, 8),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = Program.classical(
        "Slices",
        0,
        List.of(),
        List.of(),
        List.of(),
        List.of(values),
        List.of(slice),
        List.of(main),
        List.of());
    VirtualMachine machine = new VirtualMachine(program);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(1, machine.snapshot().slices().size());
    assertEquals(6, machine.snapshot().frames().getFirst().local(9));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    FunctionBody invalid = new FunctionBody(
        0,
        "main",
        false,
        0,
        main.localTypes(),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 2),
            Instruction.of(Opcode.LOCAL_CONST, 1, 4),
            Instruction.of(Opcode.LOCAL_CONST, 2, 6),
            Instruction.of(Opcode.LOCAL_CONST, 3, 8),
            Instruction.of(Opcode.ARRAY_NEW, 4, 0, 0, 4),
            Instruction.of(Opcode.LOCAL_CONST, 5, 3),
            Instruction.of(Opcode.LOCAL_CONST, 6, 2),
            Instruction.of(Opcode.SLICE_NEW, 7, 0, 4, 5, 6),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine trapped = new VirtualMachine(Program.classical(
        "SliceBounds",
        0,
        List.of(),
        List.of(),
        List.of(),
        List.of(values),
        List.of(slice),
        List.of(invalid),
        List.of()));
    assertThrows(VmTrap.class, trapped::run);
    assertTrue(trapped.snapshot().slices().isEmpty());
  }

  @Test
  void valueCallTransfersParametersResultAndRewindsFrames() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED),
        null,
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
        ValueType.SIGNED,
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
  void ownedRegionMutationDropAndRewindRestoreExactState() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.WORDS,
            ValueType.SIGNED,
            ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 16, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 2),
            Instruction.of(Opcode.WORDS_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.LOCAL_CONST, 4, 5),
            Instruction.of(Opcode.WORDS_SET, 2, 3, 4),
            Instruction.of(Opcode.WORDS_GET, 4, 2, 3),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 4),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = Program.classical(
        "Owned", 0, List.of(new Global("result", 0)),
        List.of(), List.of(), List.of(), List.of(), List.of(main), List.of());
    VirtualMachine machine = new VirtualMachine(program);
    MachineSnapshot initial = machine.snapshot();

    machine.run();

    assertEquals(5, machine.global("result"));
    assertTrue(machine.snapshot().regions().getFirst().dropped());
    assertTrue(machine.snapshot().buffers().getFirst().dropped());
    assertTrue(machine.snapshot().buffers().getFirst().elements().isEmpty());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void byteBuffersEnforceElementRangeBeforeMutation() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.BYTES,
            ValueType.SIGNED,
            ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.BYTES_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.LOCAL_CONST, 4, 256),
            Instruction.of(Opcode.BYTES_SET, 2, 3, 4),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(Program.classical(
        "ByteRange", 0, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(main), List.of()));
    for (int step = 0; step < 5; step++) {
      machine.step();
    }

    assertThrows(VmTrap.class, machine::step);
    assertEquals(BufferKind.BYTES, machine.snapshot().buffers().getFirst().kind());
    assertEquals(0, machine.snapshot().buffers().getFirst().elements().getFirst());
  }

  @Test
  void utf8ValidationReturnsFalseAndCountingTrapsOnMalformedBytes() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.BYTES,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.BOOLEAN,
            ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 2, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 2),
            Instruction.of(Opcode.BYTES_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.LOCAL_CONST, 4, 192),
            Instruction.of(Opcode.BYTES_SET, 2, 3, 4),
            Instruction.of(Opcode.LOCAL_CONST, 3, 1),
            Instruction.of(Opcode.LOCAL_CONST, 4, 128),
            Instruction.of(Opcode.BYTES_SET, 2, 3, 4),
            Instruction.of(Opcode.UTF8_VALID, 5, 2),
            Instruction.of(Opcode.UTF8_COUNT, 6, 2),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(Program.classical(
        "MalformedUtf8", 0, List.of(),
        List.of(), List.of(), List.of(), List.of(), List.of(main), List.of()));
    for (int step = 0; step < 10; step++) {
      machine.step();
    }

    assertEquals(0, machine.snapshot().frames().getFirst().locals().get(5));
    assertThrows(VmTrap.class, machine::step);
    assertEquals(0, machine.snapshot().frames().getFirst().locals().get(6));
  }

  @Test
  void utf8FreezeMovesOwnershipEnforcesKindAndRewindsExactly() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.BYTES,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.UTF8,
            ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.BYTES_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.LOCAL_CONST, 4, 65),
            Instruction.of(Opcode.BYTES_SET, 2, 3, 4),
            Instruction.of(Opcode.UTF8_FREEZE, 5, 2),
            Instruction.of(Opcode.UTF8_COUNT, 6, 5),
            Instruction.of(Opcode.BUFFER_DROP, 5),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(Program.classical(
        "FrozenUtf8", 0, List.of(),
        List.of(), List.of(), List.of(), List.of(), List.of(main), List.of()));
    MachineSnapshot initial = machine.snapshot();

    for (int step = 0; step < 7; step++) {
      machine.step();
    }
    assertEquals(BufferKind.UTF8, machine.snapshot().buffers().getFirst().kind());
    assertEquals(0, machine.snapshot().frames().getFirst().locals().get(2));
    assertEquals(1, machine.snapshot().frames().getFirst().locals().get(5));

    machine.rewindOne();
    assertEquals(BufferKind.BYTES, machine.snapshot().buffers().getFirst().kind());
    assertEquals(1, machine.snapshot().frames().getFirst().locals().get(2));
    assertEquals(0, machine.snapshot().frames().getFirst().locals().get(5));

    machine.run();
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void regionExhaustionTrapsBeforeAllocationMutation() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.REGION, ValueType.SIGNED, ValueType.WORDS),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 2),
            Instruction.of(Opcode.WORDS_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(Program.classical(
        "Exhausted", 0, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(main), List.of()));
    machine.step();
    machine.step();

    assertThrows(VmTrap.class, machine::step);
    assertEquals(0, machine.snapshot().regions().getFirst().usedBytes());
    assertTrue(machine.snapshot().buffers().isEmpty());

    FunctionBody objectLimited = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.REGION, ValueType.SIGNED, ValueType.WORDS, ValueType.WORDS),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 16, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.WORDS_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.WORDS_ALLOC, 3, 0, 1),
            Instruction.of(Opcode.BUFFER_DROP, 3),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine objectMachine = new VirtualMachine(Program.classical(
        "ObjectExhausted", 0, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(objectLimited), List.of()));
    objectMachine.step();
    objectMachine.step();
    objectMachine.step();

    assertThrows(VmTrap.class, objectMachine::step);
    assertEquals(1, objectMachine.snapshot().regions().getFirst().liveObjects());
    assertEquals(1, objectMachine.snapshot().buffers().size());
  }

  @Test
  void regionDropWithLiveBufferTrapsBeforeMutation() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.REGION, ValueType.SIGNED, ValueType.WORDS),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.WORDS_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.HALT)),
        List.of());
    VirtualMachine machine = new VirtualMachine(Program.classical(
        "LiveBuffer", 0, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(main), List.of()));
    machine.step();
    machine.step();
    machine.step();

    assertThrows(VmTrap.class, machine::step);
    assertEquals(1, machine.snapshot().regions().getFirst().liveObjects());
    assertFalse(machine.snapshot().buffers().getFirst().dropped());
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
            0, "main", false, 0, List.of(), null, instructions, List.of())));
  }
}
