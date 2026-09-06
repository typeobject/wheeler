package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.proof.ProofRule;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

/** Otherwise valid artifacts with an independently retargetable static certificate. */
final class StaticStepProofArtifacts {
  private StaticStepProofArtifacts() {}

  static byte[] artifact(Opcode opcode) {
    List<ValueType> locals = List.of();
    var body = new ArrayList<Instruction>();
    FunctionBody callee;
    switch (opcode) {
      case CALL, UNCALL, CALL_VOID, JUMP, JUMP_IF_ZERO -> {
        callee = new FunctionBody(0, "increment", false, 0, List.of(), null,
            List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
            opcode == Opcode.CALL_VOID ? List.of()
                : List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
        switch (opcode) {
          case JUMP -> body.add(Instruction.of(opcode, 1));
          case JUMP_IF_ZERO -> {
            locals = List.of(ValueType.BOOLEAN);
            body.add(Instruction.of(Opcode.LOCAL_CONST, 0, 1));
            body.add(Instruction.of(opcode, 0, 2));
          }
          case CALL_VOID -> body.add(Instruction.of(opcode, 0, 0, 0));
          default -> body.add(Instruction.of(opcode, 0));
        }
      }
      case CALL_VALUE -> {
        locals = List.of(ValueType.SIGNED);
        callee = new FunctionBody(0, "value", false, 0, locals, ValueType.SIGNED,
            List.of(Instruction.of(Opcode.LOCAL_CONST, 0, 7), Instruction.of(Opcode.RETURN_VALUE, 0)),
            List.of());
        body.add(Instruction.of(opcode, 0, 0, 0, 0));
      }
      case CALL_RESULT_SLOT, UNCALL_RESULT_SLOT -> {
        locals = List.of(ValueType.BOOLEAN, ValueType.SIGNED);
        var result = List.of(Instruction.of(Opcode.RESULT_FILL_CONSTANT, 0, 7),
            Instruction.of(Opcode.RETURN_RESULT_SLOT, 0));
        callee = new FunctionBody(0, "slot", false, 0, locals, ValueType.SIGNED, true, result, result);
        if (opcode == Opcode.UNCALL_RESULT_SLOT) {
          body.add(Instruction.of(Opcode.LOCAL_CONST, 0, 1));
          body.add(Instruction.of(Opcode.LOCAL_CONST, 1, 7));
        }
        body.add(Instruction.of(opcode, 0, 0, 0, 0));
      }
      default -> throw new IllegalArgumentException("not a control fixture: " + opcode);
    }
    body.add(Instruction.of(Opcode.RETURN));
    var subject = new FunctionBody(1, "subject", false, 0, locals, null, body, List.of());
    var entry = new FunctionBody(2, "main", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.CALL_VOID, 1, 0, 0), Instruction.of(Opcode.HALT)), List.of());
    var proof = new ProofCertificate(0, "bounded", ProofRule.STATIC_STEP_BOUND, 0, body.size());
    var program = Program.classical("StaticSteps", 2, List.of(new Global("value", 1)),
        List.of(), List.of(), List.of(), List.of(), List.of(callee, subject, entry), List.of(proof));
    return new BytecodeWriter().write(program);
  }

  static byte[] retarget(byte[] artifact, int subject) {
    byte[] changed = artifact.clone();
    ByteBuffer.wrap(changed).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(proofOffset(changed) + 4 + 12, subject);
    return changed;
  }

  static int proofOffset(byte[] artifact) {
    var bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    for (int directory = 40; directory < artifact.length; directory += 32) {
      if (bytes.getInt(directory) == 10) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing proof section");
  }
}
