package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

/** Position-independent x86-64 lowering for one validated scalar AOT program. */
public final class ScalarAotMachine {
  public static final int EXECUTION_TRAP_STATUS = 126;

  private ScalarAotMachine() {}

  /** Emits owned machine code entered with the Linux process stack in RSP. */
  public static byte[] lower(ScalarAotProgram scalar) {
    X86 code = new X86();
    int[] functionOffsets = new int[scalar.program().functions().size()];
    IoLayout io = scalar.usesDynamicApplicationIo()
        ? IoLayout.create(scalar.entry().localCount()) : null;
    ArrayList<CallPatch> calls = new ArrayList<>();
    int entryJump = -1;
    if (functionOffsets.length > 1) {
      code.bytes(0xe9);
      entryJump = code.reserveInt();
    }
    for (FunctionBody function : scalar.program().functions()) {
      functionOffsets[function.id()] = code.position();
      if (function.id() == scalar.entry().id()) {
        emitEntry(code, function, calls, io);
      } else {
        emitHelper(code, function, calls, io);
      }
    }
    for (CallPatch call : calls) {
      code.patchRelativeInt(call.displacement(), functionOffsets[call.target()]);
    }
    if (entryJump >= 0) {
      code.patchRelativeInt(entryJump, functionOffsets[scalar.entry().id()]);
    }
    return code.finish();
  }

  private static void emitEntry(
      X86 code,
      FunctionBody entry,
      ArrayList<CallPatch> calls,
      IoLayout io) {
    int globalSlot = entry.localCount();
    int frameBytes = io == null ? frameBytes(globalSlot + 1) : io.frameBytes();
    code.stack(-frameBytes);
    code.bytes(0x31, 0xc0);
    code.storeRax(globalSlot);
    ArrayList<Integer> prologueTraps = new ArrayList<>();
    if (io != null) {
      code.storeRax(io.outputLengthSlot());
      code.readInput(io, prologueTraps);
      code.zeroOutput(io);
      code.leaRax(io.inputLengthSlot() * Long.BYTES);
      code.storeRax(0);
      code.leaRax(io.outputLengthSlot() * Long.BYTES);
      code.storeRax(1);
    } else if (entry.parameterCount() == 1) {
      code.moveImmediateToRax(1);
      code.storeRax(0);
    }
    FunctionPatches patches = emitBody(code, entry, globalSlot, calls, io);
    patches.traps().addAll(prologueTraps);

    code.loadRax(globalSlot);
    code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    patches.traps().add(code.reserveInt());
    code.bytes(0x48, 0x83, 0xf8, 124, 0x0f, 0x8f);
    patches.traps().add(code.reserveInt());
    if (io != null) {
      code.writeOutput(io, patches.traps());
      code.loadRax(globalSlot);
    }
    code.stack(frameBytes);
    code.bytes(0x89, 0xc7, 0xe9);
    int successJump = code.reserveInt();
    int trap = code.position();
    code.stack(frameBytes);
    code.bytes(0xbf);
    code.integer(EXECUTION_TRAP_STATUS);
    int end = code.position();
    patchFunction(code, patches, trap);
    code.patchRelativeInt(successJump, end);
  }

  private static void emitHelper(
      X86 code,
      FunctionBody helper,
      ArrayList<CallPatch> calls,
      IoLayout io) {
    int frameBytes = frameBytes(helper.localCount());
    code.stack(-frameBytes);
    for (int parameter = 0; parameter < helper.parameterCount(); parameter++) {
      code.storeArgument(parameter);
    }
    FunctionPatches patches = emitBody(code, helper, -1, calls, io);

    Instruction returned = helper.forward().getLast();
    if (returned.opcode() == Opcode.RETURN_VALUE) {
      code.loadRax(Math.toIntExact(returned.operands().get(0)));
    } else {
      code.bytes(0x31, 0xc0);
    }
    code.bytes(0x31, 0xd2);
    code.stack(frameBytes);
    code.bytes(0xc3);
    int trap = code.position();
    code.bytes(0xba);
    code.integer(1);
    code.stack(frameBytes);
    code.bytes(0xc3);
    patchFunction(code, patches, trap);
  }

  private static FunctionPatches emitBody(
      X86 code,
      FunctionBody function,
      int globalSlot,
      ArrayList<CallPatch> calls,
      IoLayout io) {
    int[] instructionOffsets = new int[function.forward().size()];
    ArrayList<MachineBranch> branches = new ArrayList<>();
    ArrayList<Integer> traps = new ArrayList<>();
    for (int pc = 0; pc < function.forward().size(); pc++) {
      instructionOffsets[pc] = code.position();
      Instruction instruction = function.forward().get(pc);
      switch (instruction.opcode()) {
        case NOP -> {
          // Canonical NOP has no machine effect.
        }
        case LOCAL_CONST -> {
          code.moveImmediateToRax(instruction.operands().get(1));
          code.storeRax(local(instruction, 0));
        }
        case LOCAL_LOAD_GLOBAL -> {
          code.loadRax(globalSlot);
          code.storeRax(local(instruction, 0));
        }
        case LOCAL_MOVE, BUFFER_BORROW -> {
          int destination = local(instruction, 0);
          code.loadRax(local(instruction, 1));
          code.storeRax(destination);
        }
        case BUFFER_LENGTH -> {
          code.bufferLength(local(instruction, 1));
          code.storeRax(local(instruction, 0));
        }
        case BYTES_GET -> {
          code.inputByte(local(instruction, 1), local(instruction, 2), io, traps);
          code.storeRax(local(instruction, 0));
        }
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
            LOCAL_ROTR32 -> {
          code.loadRax(local(instruction, 1));
          code.loadRcx(local(instruction, 2));
          code.arithmetic(instruction.opcode(), traps);
          code.storeRax(local(instruction, 0));
        }
        case LOCAL_EQ, LOCAL_LT -> {
          code.loadRax(local(instruction, 1));
          code.loadRcx(local(instruction, 2));
          code.comparison(instruction.opcode());
          code.storeRax(local(instruction, 0));
        }
        case JUMP -> {
          code.bytes(0xe9);
          branches.add(new MachineBranch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(0))));
        }
        case JUMP_IF_ZERO -> {
          code.loadRax(local(instruction, 0));
          code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x84);
          branches.add(new MachineBranch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(1))));
        }
        case BYTES_SET -> {
          if (io != null) {
            code.outputByte(
                local(instruction, 0),
                local(instruction, 1),
                local(instruction, 2),
                io,
                traps);
          }
        }
        case OUTPUT_LENGTH -> {
          if (io != null) {
            code.outputLength(
                local(instruction, 0), local(instruction, 1), io, traps);
          }
        }
        case EXPECT_TRUE -> {
          code.loadRax(local(instruction, 0));
          code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x84);
          traps.add(code.reserveInt());
        }
        case LOCAL_LOOP_CHECK -> {
          code.loadRax(local(instruction, 0));
          code.loadRcx(local(instruction, 1));
          code.loopCheck(traps);
          code.storeRax(local(instruction, 0));
        }
        case CALL_VALUE, CALL_VOID -> {
          int argumentBase = Math.toIntExact(instruction.operands().get(1));
          int argumentCount = Math.toIntExact(instruction.operands().get(2));
          for (int argument = 0; argument < argumentCount; argument++) {
            code.loadArgument(argument, argumentBase + argument);
          }
          code.bytes(0xe8);
          calls.add(new CallPatch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(0))));
          code.bytes(0x48, 0x85, 0xd2, 0x0f, 0x85);
          traps.add(code.reserveInt());
          if (instruction.opcode() == Opcode.CALL_VALUE) {
            code.storeRax(local(instruction, 3));
          }
        }
        case LOCAL_STORE_GLOBAL -> {
          code.loadRax(local(instruction, 1));
          code.storeRax(globalSlot);
        }
        case RETURN, RETURN_VALUE, HALT -> {
          // The function epilogue owns its terminal instruction.
        }
        default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
      }
    }
    return new FunctionPatches(instructionOffsets, branches, traps);
  }

  private static void patchFunction(X86 code, FunctionPatches patches, int trap) {
    for (MachineBranch branch : patches.branches()) {
      code.patchRelativeInt(
          branch.displacement(), patches.instructionOffsets()[branch.target()]);
    }
    for (int branch : patches.traps()) {
      code.patchRelativeInt(branch, trap);
    }
  }

  private static int local(Instruction instruction, int operand) {
    return Math.toIntExact(instruction.operands().get(operand));
  }

  private static int frameBytes(int slots) {
    return alignBytes(Math.multiplyExact(slots, Long.BYTES));
  }

  private static int alignBytes(int bytes) {
    return Math.addExact(bytes, 15) & -16;
  }

  private record IoLayout(
      int inputLengthSlot,
      int outputLengthSlot,
      int inputOffset,
      int outputOffset,
      int frameBytes) {
    static IoLayout create(int globalSlot) {
      int inputLengthSlot = globalSlot + 1;
      int outputLengthSlot = globalSlot + 2;
      int inputOffset = ScalarAotMachine.frameBytes(globalSlot + 3);
      int outputOffset = inputOffset + ScalarAotProgram.MAX_INPUT_BYTES;
      int frameBytes = alignBytes(outputOffset + ScalarAotProgram.MAX_OUTPUT_BYTES);
      return new IoLayout(
          inputLengthSlot, outputLengthSlot, inputOffset, outputOffset, frameBytes);
    }

    int inputDataOffset() {
      return inputOffset - inputLengthSlot * Long.BYTES;
    }

    int outputDataOffset() {
      return outputOffset - outputLengthSlot * Long.BYTES;
    }
  }

  private record CallPatch(int displacement, int target) {}

  private record MachineBranch(int displacement, int target) {}

  private record FunctionPatches(
      int[] instructionOffsets,
      ArrayList<MachineBranch> branches,
      ArrayList<Integer> traps) {}

  private record RelativePatch(int displacement, int target) {}

  private static final class X86 {
    private final ByteArrayOutputStream output = new ByteArrayOutputStream(2048);
    private final ArrayList<RelativePatch> relativePatches = new ArrayList<>();

    int position() {
      return output.size();
    }

    void bytes(int... values) {
      for (int value : values) {
        output.write(value);
      }
    }

    int reserveInt() {
      int result = position();
      integer(0);
      return result;
    }

    void integer(int value) {
      for (int shift = 0; shift < Integer.SIZE; shift += Byte.SIZE) {
        output.write(value >>> shift);
      }
    }

    void word(long value) {
      for (int shift = 0; shift < Long.SIZE; shift += Byte.SIZE) {
        output.write((int) (value >>> shift));
      }
    }

    void stack(int delta) {
      bytes(0x48, 0x81, delta < 0 ? 0xec : 0xc4);
      integer(Math.abs(delta));
    }

    void moveImmediateToRax(long value) {
      bytes(0x48, 0xb8);
      word(value);
    }

    void loadRax(int local) {
      bytes(0x48, 0x8b, 0x84, 0x24);
      integer(local * Long.BYTES);
    }

    void loadRcx(int local) {
      bytes(0x48, 0x8b, 0x8c, 0x24);
      integer(local * Long.BYTES);
    }

    void loadR10(int local) {
      bytes(0x4c, 0x8b, 0x94, 0x24);
      integer(local * Long.BYTES);
    }

    void storeRax(int local) {
      bytes(0x48, 0x89, 0x84, 0x24);
      integer(local * Long.BYTES);
    }

    void loadArgument(int argument, int local) {
      switch (argument) {
        case 0 -> bytes(0x48, 0x8b, 0xbc, 0x24);
        case 1 -> bytes(0x48, 0x8b, 0xb4, 0x24);
        case 2 -> bytes(0x48, 0x8b, 0x94, 0x24);
        case 3 -> bytes(0x48, 0x8b, 0x8c, 0x24);
        case 4 -> bytes(0x4c, 0x8b, 0x84, 0x24);
        case 5 -> bytes(0x4c, 0x8b, 0x8c, 0x24);
        default -> throw new IllegalStateException("Validated scalar AOT argument changed");
      }
      integer(local * Long.BYTES);
    }

    void storeArgument(int argument) {
      switch (argument) {
        case 0 -> bytes(0x48, 0x89, 0xbc, 0x24);
        case 1 -> bytes(0x48, 0x89, 0xb4, 0x24);
        case 2 -> bytes(0x48, 0x89, 0x94, 0x24);
        case 3 -> bytes(0x48, 0x89, 0x8c, 0x24);
        case 4 -> bytes(0x4c, 0x89, 0x84, 0x24);
        case 5 -> bytes(0x4c, 0x89, 0x8c, 0x24);
        default -> throw new IllegalStateException("Validated scalar AOT parameter changed");
      }
      integer(argument * Long.BYTES);
    }

    void leaRax(int stackOffset) {
      bytes(0x48, 0x8d, 0x84, 0x24);
      integer(stackOffset);
    }

    void zeroOutput(IoLayout io) {
      bytes(0x48, 0x8d, 0xbc, 0x24);
      integer(io.outputOffset());
      bytes(0x31, 0xc0, 0xb9);
      integer(ScalarAotProgram.MAX_OUTPUT_BYTES / Long.BYTES);
      bytes(0xfc, 0xf3, 0x48, 0xab);
    }

    void readInput(IoLayout io, ArrayList<Integer> traps) {
      bytes(0x31, 0xc0);
      storeRax(io.inputLengthSlot());
      int loop = position();
      loadRax(io.inputLengthSlot());
      bytes(0x48, 0x3d);
      integer(ScalarAotProgram.MAX_INPUT_BYTES);
      bytes(0x0f, 0x84);
      int fullJump = reserveInt();
      bytes(0x48, 0x8d, 0xb4, 0x04);
      integer(io.inputOffset());
      bytes(0xba);
      integer(ScalarAotProgram.MAX_INPUT_BYTES);
      bytes(0x29, 0xc2, 0x31, 0xff, 0x31, 0xc0, 0x0f, 0x05);
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
      traps.add(reserveInt());
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x84);
      int completeJump = reserveInt();
      bytes(0x48, 0x01, 0x84, 0x24);
      integer(io.inputLengthSlot() * Long.BYTES);
      bytes(0xe9);
      int loopJump = reserveInt();
      int full = position();
      bytes(0x31, 0xff);
      leaRsi(io.outputOffset());
      bytes(0xba);
      integer(1);
      bytes(0x31, 0xc0, 0x0f, 0x05, 0x48, 0x85, 0xc0, 0x0f, 0x85);
      traps.add(reserveInt());
      int complete = position();
      patchRelativeInt(fullJump, full);
      patchRelativeInt(completeJump, complete);
      patchRelativeInt(loopJump, loop);
    }

    void bufferLength(int ownerLocal) {
      loadR10(ownerLocal);
      bytes(0x49, 0x8b, 0x02);
    }

    void inputByte(
        int ownerLocal,
        int indexLocal,
        IoLayout io,
        ArrayList<Integer> traps) {
      loadRax(indexLocal);
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
      traps.add(reserveInt());
      loadR10(ownerLocal);
      bytes(0x49, 0x8b, 0x0a, 0x48, 0x39, 0xc8, 0x0f, 0x83);
      traps.add(reserveInt());
      bytes(0x41, 0x0f, 0xb6, 0x84, 0x02);
      integer(io.inputDataOffset());
    }

    void outputByte(
        int ownerLocal,
        int indexLocal,
        int valueLocal,
        IoLayout io,
        ArrayList<Integer> traps) {
      loadRax(indexLocal);
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
      traps.add(reserveInt());
      bytes(0x48, 0x3d);
      integer(ScalarAotProgram.MAX_OUTPUT_BYTES - 1);
      bytes(0x0f, 0x87);
      traps.add(reserveInt());
      loadRcx(valueLocal);
      bytes(0x48, 0x85, 0xc9, 0x0f, 0x88);
      traps.add(reserveInt());
      bytes(0x48, 0x81, 0xf9);
      integer(255);
      bytes(0x0f, 0x87);
      traps.add(reserveInt());
      loadR10(ownerLocal);
      bytes(0x41, 0x88, 0x8c, 0x02);
      integer(io.outputDataOffset());
    }

    void outputLength(
        int ownerLocal,
        int lengthLocal,
        IoLayout io,
        ArrayList<Integer> traps) {
      loadRax(lengthLocal);
      validOutputLength(traps);
      loadR10(ownerLocal);
      bytes(0x49, 0x89, 0x02);
    }

    void writeOutput(IoLayout io, ArrayList<Integer> traps) {
      loadRax(io.outputLengthSlot());
      validOutputLength(traps);
      bytes(0x48, 0x89, 0xc2);
      leaRsi(io.outputOffset());
      bytes(0xbf);
      integer(1);
      bytes(0xb8);
      integer(1);
      bytes(0x0f, 0x05, 0x48, 0x39, 0xd0, 0x0f, 0x85);
      traps.add(reserveInt());
    }

    private void validOutputLength(ArrayList<Integer> traps) {
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x8e);
      traps.add(reserveInt());
      bytes(0x48, 0x3d);
      integer(ScalarAotProgram.MAX_OUTPUT_BYTES);
      bytes(0x0f, 0x8f);
      traps.add(reserveInt());
    }

    private void leaRsi(int stackOffset) {
      bytes(0x48, 0x8d, 0xb4, 0x24);
      integer(stackOffset);
    }

    void arithmetic(Opcode opcode, ArrayList<Integer> traps) {
      switch (opcode) {
        case LOCAL_ADD -> {
          bytes(0x48, 0x01, 0xc8, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_SUB -> {
          bytes(0x48, 0x29, 0xc8, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_MUL -> {
          bytes(0x48, 0x0f, 0xaf, 0xc1, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_DIV, LOCAL_MOD -> division(opcode);
        case LOCAL_AND -> bytes(0x48, 0x21, 0xc8);
        case LOCAL_XOR -> bytes(0x48, 0x31, 0xc8);
        case LOCAL_ROTR32 -> bytes(0xd3, 0xc8);
        default -> throw new IllegalStateException("Validated scalar AOT arithmetic changed");
      }
    }

    void loopCheck(ArrayList<Integer> traps) {
      bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
      traps.add(reserveInt());
      bytes(0x48, 0x85, 0xc9, 0x0f, 0x88);
      traps.add(reserveInt());
      bytes(0x48, 0x39, 0xc8, 0x0f, 0x8d);
      traps.add(reserveInt());
      bytes(0x48, 0x83, 0xc0, 0x01, 0x0f, 0x80);
      traps.add(reserveInt());
    }

    void comparison(Opcode opcode) {
      bytes(0x48, 0x39, 0xc8);
      if (opcode == Opcode.LOCAL_EQ) {
        bytes(0x0f, 0x94, 0xc0);
      } else if (opcode == Opcode.LOCAL_LT) {
        bytes(0x0f, 0x9c, 0xc0);
      } else {
        throw new IllegalStateException("Validated scalar AOT comparison changed");
      }
      bytes(0x48, 0x0f, 0xb6, 0xc0);
    }

    void division(Opcode opcode) {
      bytes(0x48, 0x99, 0x48, 0xf7, 0xf9);
      if (opcode == Opcode.LOCAL_MOD) {
        bytes(0x48, 0x89, 0xd0);
      }
    }

    void patchRelativeInt(int displacementOffset, int target) {
      relativePatches.add(new RelativePatch(displacementOffset, target));
    }

    byte[] finish() {
      byte[] result = output.toByteArray();
      ByteBuffer buffer = ByteBuffer.wrap(result).order(ByteOrder.LITTLE_ENDIAN);
      for (RelativePatch patch : relativePatches) {
        buffer.putInt(
            patch.displacement(),
            patch.target() - patch.displacement() - Integer.BYTES);
      }
      return result;
    }
  }
}
