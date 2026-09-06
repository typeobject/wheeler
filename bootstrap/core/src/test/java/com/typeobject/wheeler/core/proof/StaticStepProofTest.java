package com.typeobject.wheeler.core.proof;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.EnumSet;
import java.util.List;
import org.junit.jupiter.api.Test;

/** A local instruction count cannot certify transitions in another function body. */
final class StaticStepProofTest {
  @Test
  void rejectsTheTwoInstructionInverseCallCertificateThroughTheCompleteArtifact() {
    Program valid = inverseCall(1, 2);
    byte[] artifact = new BytecodeWriter().write(valid);
    Program decoded = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(decoded));
    var machine = new VirtualMachine(decoded);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(4, machine.snapshot().sequence());
    assertEquals(0, machine.global("value"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    Program forged = inverseCall(0, 2);
    BytecodeException direct = assertThrows(BytecodeException.class,
        () -> BytecodeVerifier.verify(forged));
    assertTrue(direct.getMessage().contains("not a straight-line function"));
    assertThrows(BytecodeException.class, () -> new BytecodeWriter().write(forged));
    ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(proofOffset(artifact) + 4 + 12, 0);
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
  }

  @Test
  void keepsTheInstructionCountAndRuntimeCeilingIndependent() {
    for (long bound : List.of(2L, 16L)) {
      Program program = inverseCall(1, bound);
      byte[] artifact = new BytecodeWriter().write(program);
      assertArrayEquals(artifact, new BytecodeWriter().write(new BytecodeReader().read(artifact)));
    }
    for (long bound : List.of(1L, 17L, Long.MAX_VALUE)) {
      assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(inverseCall(1, bound)));
    }
    for (long bound : List.of(0L, -1L, Long.MIN_VALUE)) {
      assertThrows(IllegalArgumentException.class, () -> inverseCall(1, bound));
    }
    byte[] valid = new BytecodeWriter().write(inverseCall(1, 2));
    for (long bound : List.of(0L, -1L, Long.MIN_VALUE, Long.MAX_VALUE)) {
      byte[] malformed = valid.clone();
      ByteBuffer.wrap(malformed).order(ByteOrder.LITTLE_ENDIAN)
          .putLong(proofOffset(malformed) + 4 + 16, bound);
      assertThrows(BytecodeException.class, () -> new BytecodeReader().read(malformed));
    }
  }

  @Test
  void accountsForEveryCurrentOpcodeWithoutAnImplicitAdmissionPath() {
    var control = EnumSet.of(Opcode.CALL, Opcode.UNCALL, Opcode.CALL_VALUE, Opcode.CALL_VOID,
        Opcode.CALL_RESULT_SLOT, Opcode.UNCALL_RESULT_SLOT, Opcode.JUMP, Opcode.JUMP_IF_ZERO);
    assertEquals(75, Opcode.values().length);
    for (Opcode opcode : Opcode.values()) {
      assertEquals(!control.contains(opcode), StaticStepRule.admits(opcode), opcode.name());
    }
  }

  private static Program inverseCall(int subject, long bound) {
    var main = new FunctionBody(0, "main", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.UNCALL, 1), Instruction.of(Opcode.HALT)), List.of());
    var callee = new FunctionBody(1, "increment", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    return new Program("StaticSteps", ProgramKind.CLASSICAL, 0,
        List.of(new Global("value", 1)), List.of(), List.of(), List.of(), List.of(),
        List.of(main, callee),
        List.of(new ProofCertificate(0, "bounded", ProofRule.STATIC_STEP_BOUND, subject, bound)),
        List.of(), List.of(), List.of(), 16, 16);
  }

  private static int proofOffset(byte[] artifact) {
    var bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    for (int directory = 40; directory < artifact.length; directory += 32) {
      if (bytes.getInt(directory) == 10) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing proof section");
  }
}
