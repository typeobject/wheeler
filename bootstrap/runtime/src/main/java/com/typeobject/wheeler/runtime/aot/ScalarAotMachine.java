package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import java.util.ArrayList;

/** Position-independent x86-64 lowering for one validated scalar AOT program. */
public final class ScalarAotMachine {
  public static final int EXECUTION_TRAP_STATUS = 126;

  private ScalarAotMachine() {}

  /** Emits owned machine code entered with the Linux process stack in RSP. */
  public static byte[] lower(ScalarAotProgram scalar) {
    ScalarAotX86 code = new ScalarAotX86();
    int[] functionOffsets = new int[scalar.program().functions().size()];
    int fuelSlot = scalar.entry().localCount() + scalar.program().globals().size();
    int finalStateSlot = fuelSlot + (scalar.usesBoundedRecursion() ? 1 : 0);
    ScalarAotX86.IoLayout io = scalar.usesDynamicApplicationIo()
        ? ScalarAotX86.IoLayout.create(finalStateSlot)
        : null;
    boolean utf8 = scalar.program().functions().stream()
        .flatMap(function -> function.forward().stream())
        .anyMatch(instruction -> switch (instruction.opcode()) {
          case UTF8_VALID, UTF8_COUNT, UTF8_SCALAR, UTF8_WIDTH -> true;
          default -> false;
        });
    ArrayList<CallPatch> calls = new ArrayList<>();
    int entryJump = -1;
    if (functionOffsets.length > 1 || utf8) {
      code.bytes(0xe9);
      entryJump = code.reserveInt();
    }
    if (utf8) {
      code.installUtf8Decoder(io);
    }
    for (FunctionBody function : scalar.program().functions()) {
      functionOffsets[function.id()] = code.position();
      if (function.id() == scalar.entry().id()) {
        emitEntry(code, scalar, calls, io);
      } else {
        emitHelper(code, function, calls, io, scalar.usesBoundedRecursion());
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
      ScalarAotX86 code,
      ScalarAotProgram scalar,
      ArrayList<CallPatch> calls,
      ScalarAotX86.IoLayout io) {
    FunctionBody entry = scalar.entry();
    int globalBase = entry.localCount();
    int fuelSlot = globalBase + scalar.program().globals().size();
    int callDepthSlot = scalar.usesBoundedRecursion() ? fuelSlot + 1 : -1;
    int frameSlots = fuelSlot + (scalar.usesBoundedRecursion() ? 2 : 1);
    int frameBytes = io == null ? frameBytes(frameSlots) : io.frameBytes();
    code.stack(-frameBytes);
    for (int global = 0; global < scalar.program().globals().size(); global++) {
      code.moveImmediateToRax(scalar.program().globals().get(global).initialValue());
      code.storeRax(globalBase + global);
    }
    code.leaR14(globalBase * Long.BYTES);
    code.moveImmediateToRax(ScalarAotProgram.MAX_EXECUTED_INSTRUCTIONS);
    code.storeRax(fuelSlot);
    code.leaR15(fuelSlot * Long.BYTES);
    if (scalar.usesBoundedRecursion()) {
      code.bytes(0x31, 0xc0);
      code.storeRax(callDepthSlot);
      code.leaR13(callDepthSlot * Long.BYTES);
    }
    ArrayList<Integer> prologueTraps = new ArrayList<>();
    if (io != null) {
      code.bytes(0x31, 0xc0);
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
    FunctionPatches patches = emitBody(
        code, entry, calls, io, scalar.usesBoundedRecursion());
    patches.traps().addAll(prologueTraps);

    code.loadGlobal(0);
    code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    patches.traps().add(code.reserveInt());
    code.bytes(0x48, 0x83, 0xf8, 124, 0x0f, 0x8f);
    patches.traps().add(code.reserveInt());
    if (io != null) {
      code.writeOutput(io, patches.traps());
      code.loadGlobal(0);
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
      ScalarAotX86 code,
      FunctionBody helper,
      ArrayList<CallPatch> calls,
      ScalarAotX86.IoLayout io,
      boolean boundedRecursion) {
    int frameBytes = frameBytes(helper.localCount());
    code.stack(-frameBytes);
    for (int parameter = 0; parameter < helper.parameterCount(); parameter++) {
      code.storeArgument(parameter, frameBytes);
    }
    FunctionPatches patches = emitBody(code, helper, calls, io, boundedRecursion);

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
      ScalarAotX86 code,
      FunctionBody function,
      ArrayList<CallPatch> calls,
      ScalarAotX86.IoLayout io,
      boolean boundedRecursion) {
    int[] instructionOffsets = new int[function.forward().size()];
    ArrayList<MachineBranch> branches = new ArrayList<>();
    ArrayList<Integer> traps = new ArrayList<>();
    for (int pc = 0; pc < function.forward().size(); pc++) {
      instructionOffsets[pc] = code.position();
      code.consumeFuel(traps);
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
          code.loadGlobal(Math.toIntExact(instruction.operands().get(1)));
          code.storeRax(local(instruction, 0));
        }
        case ADD_CONST, SUB_CONST, XOR_CONST -> {
          code.updateGlobal(
              instruction.opcode(),
              Math.toIntExact(instruction.operands().get(0)),
              instruction.operands().get(1),
              traps);
        }
        case SET_LOGGED -> code.setGlobal(
            Math.toIntExact(instruction.operands().get(0)),
            instruction.operands().get(1));
        case SWAP -> code.swapGlobals(
            Math.toIntExact(instruction.operands().get(0)),
            Math.toIntExact(instruction.operands().get(1)));
        case EXPECT_EQ -> code.expectGlobal(
            Math.toIntExact(instruction.operands().get(0)),
            instruction.operands().get(1),
            traps);
        case LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW -> {
          int destination = local(instruction, 0);
          code.loadRax(local(instruction, 1));
          code.storeRax(destination);
        }
        case BUFFER_LENGTH -> {
          code.bufferLength(local(instruction, 1));
          code.storeRax(local(instruction, 0));
        }
        case UTF8_VALID, UTF8_COUNT -> {
          code.utf8Whole(
              local(instruction, 1), instruction.opcode(), traps);
          code.storeRax(local(instruction, 0));
        }
        case BYTES_GET -> {
          code.inputByte(local(instruction, 1), local(instruction, 2), io, traps);
          code.storeRax(local(instruction, 0));
        }
        case UTF8_SCALAR, UTF8_WIDTH -> {
          code.utf8At(
              local(instruction, 1),
              local(instruction, 2),
              instruction.opcode(),
              traps);
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
          int callAreaBytes = code.loadArguments(argumentBase, argumentCount);
          if (boundedRecursion) {
            code.enterCall(traps);
          }
          code.bytes(0xe8);
          calls.add(new CallPatch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(0))));
          code.closeArguments(callAreaBytes);
          if (boundedRecursion) {
            code.leaveCall();
          }
          code.bytes(0x48, 0x85, 0xd2, 0x0f, 0x85);
          traps.add(code.reserveInt());
          if (instruction.opcode() == Opcode.CALL_VALUE) {
            code.storeRax(local(instruction, 3));
          }
        }
        case LOCAL_STORE_GLOBAL -> {
          code.loadRax(local(instruction, 1));
          code.storeGlobal(Math.toIntExact(instruction.operands().get(0)));
        }
        case RETURN, RETURN_VALUE, HALT -> {
          // The function epilogue owns its terminal instruction.
        }
        default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
      }
    }
    return new FunctionPatches(instructionOffsets, branches, traps);
  }

  private static void patchFunction(ScalarAotX86 code, FunctionPatches patches, int trap) {
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

  private record CallPatch(int displacement, int target) {}

  private record MachineBranch(int displacement, int target) {}

  private record FunctionPatches(
      int[] instructionOffsets,
      ArrayList<MachineBranch> branches,
      ArrayList<Integer> traps) {}

}
