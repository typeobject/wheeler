package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.List;

/** Canonical scalar AOT artifacts shared by focused runtime evidence. */
final class ScalarAotArtifacts {
  private ScalarAotArtifacts() {}

  static byte[] artifact(long status) {
    return artifact("status", status, false);
  }

  static byte[] conditionalArtifact(
      Opcode comparison, long left, long right) {
    Program program = new Program(
        "scalar-aot-conditional",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.BOOLEAN,
                ValueType.SIGNED,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 0, left),
                Instruction.of(Opcode.LOCAL_CONST, 1, right),
                Instruction.of(comparison, 2, 0, 1),
                Instruction.of(Opcode.JUMP_IF_ZERO, 2, 7),
                Instruction.of(Opcode.LOCAL_CONST, 3, 73),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 3),
                Instruction.of(Opcode.JUMP, 9),
                Instruction.of(Opcode.LOCAL_CONST, 4, 74),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 4),
                Instruction.of(Opcode.HALT)),
            List.of())));
    return new BytecodeWriter().write(program);
  }

  static byte[] outputArtifact(byte[] output) {
    List<Instruction> instructions = new java.util.ArrayList<>();
    instructions.add(Instruction.of(Opcode.LOCAL_MOVE, 1, 0));
    for (int index = 0; index < output.length; index++) {
      instructions.add(Instruction.of(Opcode.LOCAL_CONST, 2, index));
      instructions.add(Instruction.of(Opcode.LOCAL_CONST, 3, output[index] & 0xff));
      instructions.add(Instruction.of(Opcode.BYTES_SET, 1, 2, 3));
    }
    instructions.add(Instruction.of(Opcode.LOCAL_CONST, 4, output.length));
    instructions.add(Instruction.of(Opcode.OUTPUT_LENGTH, 1, 4));
    instructions.add(Instruction.of(Opcode.LOCAL_CONST, 5, 73));
    instructions.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 5));
    instructions.add(Instruction.of(Opcode.HALT));
    return new BytecodeWriter().write(new Program(
        "scalar-aot-output",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            1,
            List.of(
                ValueType.BYTES_BORROW,
                ValueType.BYTES_BORROW,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED),
            null,
            instructions,
            List.of()))));
  }

  static byte[] zeroOutputArtifact(long length) {
    return zeroOutputArtifact(length, 3);
  }

  static byte[] zeroOutputArtifact(long length, int localCount) {
    List<ValueType> localTypes = new java.util.ArrayList<>(
        java.util.Collections.nCopies(localCount, ValueType.SIGNED));
    localTypes.set(0, ValueType.BYTES_BORROW);
    return new BytecodeWriter().write(new Program(
        "scalar-aot-zero-output",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            1,
            localTypes,
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 1, length),
                Instruction.of(Opcode.OUTPUT_LENGTH, 0, 1),
                Instruction.of(Opcode.LOCAL_CONST, 2, 73),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 2),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] invalidOutputWriteArtifact(long index, long value) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-invalid-output",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            1,
            List.of(
                ValueType.BYTES_BORROW,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 1, index),
                Instruction.of(Opcode.LOCAL_CONST, 2, value),
                Instruction.of(Opcode.BYTES_SET, 0, 1, 2),
                Instruction.of(Opcode.LOCAL_CONST, 1, 1),
                Instruction.of(Opcode.OUTPUT_LENGTH, 0, 1),
                Instruction.of(Opcode.LOCAL_CONST, 3, 73),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 3),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] executionBoundArtifact(boolean dynamicIo, int entryCalls) {
    ArrayList<Instruction> leafInstructions = repeatedCalls(-1, 3);
    ArrayList<Instruction> innerInstructions = repeatedCalls(0, 61);
    ArrayList<Instruction> outerInstructions = repeatedCalls(1, 3);
    ArrayList<Instruction> entryInstructions = new ArrayList<>();
    List<ValueType> entryTypes;
    if (dynamicIo) {
      entryTypes = List.of(
          ValueType.BYTE_VIEW,
          ValueType.BYTES_BORROW,
          ValueType.SIGNED,
          ValueType.SIGNED,
          ValueType.SIGNED,
          ValueType.SIGNED);
      entryInstructions.add(Instruction.of(Opcode.LOCAL_CONST, 2, 0));
      entryInstructions.add(Instruction.of(Opcode.LOCAL_CONST, 3, 88));
      entryInstructions.add(Instruction.of(Opcode.BYTES_SET, 1, 2, 3));
      entryInstructions.add(Instruction.of(Opcode.LOCAL_CONST, 4, 1));
      entryInstructions.add(Instruction.of(Opcode.OUTPUT_LENGTH, 1, 4));
    } else {
      entryTypes = List.of(ValueType.SIGNED);
    }
    for (int call = 0; call < entryCalls; call++) {
      entryInstructions.add(Instruction.of(Opcode.CALL_VOID, 2, 0, 0));
    }
    int statusLocal = dynamicIo ? 5 : 0;
    entryInstructions.add(Instruction.of(Opcode.LOCAL_CONST, statusLocal, 73));
    entryInstructions.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, statusLocal));
    entryInstructions.add(Instruction.of(Opcode.HALT));

    return new BytecodeWriter().write(new Program(
        "scalar-aot-execution-bound",
        3,
        List.of(new Global("status", 0)),
        List.of(
            voidHelper(0, "leaf", leafInstructions),
            voidHelper(1, "inner", innerInstructions),
            voidHelper(2, "outer", outerInstructions),
            new FunctionBody(
                3,
                "example.app::main",
                false,
                dynamicIo ? 2 : 0,
                entryTypes,
                null,
                entryInstructions,
                List.of()))));
  }

  private static ArrayList<Instruction> repeatedCalls(int target, int count) {
    ArrayList<Instruction> result = new ArrayList<>();
    for (int instruction = 0; instruction < count; instruction++) {
      result.add(target < 0
          ? Instruction.of(Opcode.NOP)
          : Instruction.of(Opcode.CALL_VOID, target, 0, 0));
    }
    result.add(Instruction.of(Opcode.RETURN));
    return result;
  }

  private static FunctionBody voidHelper(
      int id, String name, List<Instruction> instructions) {
    return new FunctionBody(
        id,
        "example.app::" + name,
        false,
        0,
        List.of(ValueType.SIGNED),
        null,
        instructions,
        List.of());
  }

  static byte[] scalarGlobalArtifact(int globalCount) {
    ArrayList<Global> globals = new ArrayList<>();
    globals.add(new Global("status", 0));
    globals.add(new Global("counter", 40));
    globals.add(new Global("mask", 3));
    for (int global = globals.size(); global < globalCount; global++) {
      globals.add(new Global("state" + global, global));
    }
    return new BytecodeWriter().write(new Program(
        "scalar-aot-globals",
        1,
        globals,
        List.of(
            new FunctionBody(
                0,
                "example.app::update",
                false,
                0,
                List.of(
                    ValueType.SIGNED,
                    ValueType.SIGNED,
                    ValueType.SIGNED,
                    ValueType.SIGNED,
                    ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 1),
                    Instruction.of(Opcode.LOCAL_CONST, 1, 1),
                    Instruction.of(Opcode.LOCAL_ADD, 2, 0, 1),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 1, 2),
                    Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 3, 2),
                    Instruction.of(Opcode.LOCAL_XOR, 4, 2, 3),
                    Instruction.of(Opcode.RETURN_VALUE, 4)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] utf8IoArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-utf8-io",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            2,
            List.of(
                ValueType.UTF8_BORROW,
                ValueType.BYTES_BORROW,
                ValueType.BOOLEAN,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.BOOLEAN,
                ValueType.SIGNED,
                ValueType.BOOLEAN,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.UTF8_VALID, 2, 0),
                Instruction.of(Opcode.EXPECT_TRUE, 2),
                Instruction.of(Opcode.UTF8_COUNT, 3, 0),
                Instruction.of(Opcode.LOCAL_CONST, 4, 1),
                Instruction.of(Opcode.UTF8_SCALAR, 5, 0, 4),
                Instruction.of(Opcode.UTF8_WIDTH, 6, 0, 4),
                Instruction.of(Opcode.LOCAL_CONST, 7, 0x1f642),
                Instruction.of(Opcode.LOCAL_EQ, 8, 5, 7),
                Instruction.of(Opcode.EXPECT_TRUE, 8),
                Instruction.of(Opcode.LOCAL_CONST, 9, 2),
                Instruction.of(Opcode.LOCAL_EQ, 10, 3, 9),
                Instruction.of(Opcode.EXPECT_TRUE, 10),
                Instruction.of(Opcode.BYTES_SET, 1, 4, 6),
                Instruction.of(Opcode.LOCAL_CONST, 11, 2),
                Instruction.of(Opcode.OUTPUT_LENGTH, 1, 11),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 6),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] dynamicIoHelperArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-dynamic-io-helper",
        1,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::echo",
                false,
                2,
                List.of(
                    ValueType.BYTE_VIEW,
                    ValueType.BYTES_BORROW,
                    ValueType.SIGNED,
                    ValueType.SIGNED,
                    ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.BUFFER_LENGTH, 2, 0),
                    Instruction.of(Opcode.LOCAL_CONST, 3, 0),
                    Instruction.of(Opcode.BYTES_GET, 4, 0, 3),
                    Instruction.of(Opcode.BYTES_SET, 1, 3, 4),
                    Instruction.of(Opcode.RETURN_VALUE, 4)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                2,
                List.of(
                    ValueType.BYTE_VIEW,
                    ValueType.BYTES_BORROW,
                    ValueType.SIGNED,
                    ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.LOCAL_CONST, 2, 1),
                    Instruction.of(Opcode.OUTPUT_LENGTH, 1, 2),
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 2, 3),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 3),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] dynamicIoArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-dynamic-io",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            2,
            List.of(
                ValueType.BYTE_VIEW,
                ValueType.BYTES_BORROW,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.BUFFER_LENGTH, 2, 0),
                Instruction.of(Opcode.LOCAL_CONST, 3, 0),
                Instruction.of(Opcode.BYTES_GET, 4, 0, 3),
                Instruction.of(Opcode.BYTES_SET, 1, 3, 4),
                Instruction.of(Opcode.LOCAL_CONST, 5, 1),
                Instruction.of(Opcode.OUTPUT_LENGTH, 1, 5),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 4),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] voidHelperArtifact(long value) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-void-helper",
        1,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::check",
                false,
                1,
                List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN),
                null,
                List.of(
                    Instruction.of(Opcode.LOCAL_CONST, 1, 73),
                    Instruction.of(Opcode.LOCAL_EQ, 2, 0, 1),
                    Instruction.of(Opcode.EXPECT_TRUE, 2),
                    Instruction.of(Opcode.RETURN)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.LOCAL_CONST, 0, value),
                    Instruction.of(Opcode.CALL_VOID, 0, 0, 1),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] globalInstructionArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-global-instructions",
        0,
        List.of(new Global("status", 0), new Global("value", 40)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.ADD_CONST, 1, 4),
                Instruction.of(Opcode.EXPECT_EQ, 1, 44),
                Instruction.of(Opcode.SUB_CONST, 1, 2),
                Instruction.of(Opcode.EXPECT_EQ, 1, 42),
                Instruction.of(Opcode.XOR_CONST, 1, 99),
                Instruction.of(Opcode.EXPECT_EQ, 1, 73),
                Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 1),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] directionalCallArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-directional-call",
        1,
        List.of(new Global("status", 0), new Global("counter", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::increment",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.ADD_CONST, 1, 1),
                    Instruction.of(Opcode.RETURN)),
                List.of(
                    Instruction.of(Opcode.SUB_CONST, 1, 1),
                    Instruction.of(Opcode.RETURN))),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL, 0),
                    Instruction.of(Opcode.CALL, 0),
                    Instruction.of(Opcode.EXPECT_EQ, 1, 2),
                    Instruction.of(Opcode.UNCALL, 0),
                    Instruction.of(Opcode.EXPECT_EQ, 1, 1),
                    Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 1),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] globalReplacementArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-global-replacement",
        1,
        List.of(
            new Global("status", 0),
            new Global("left", 11),
            new Global("right", 22)),
        List.of(
            new FunctionBody(
                0,
                "example.app::replace",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.SWAP, 1, 2),
                    Instruction.of(Opcode.SET_LOGGED, 2, 51),
                    Instruction.of(Opcode.RETURN)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL_VOID, 0, 0, 0),
                    Instruction.of(Opcode.EXPECT_EQ, 1, 22),
                    Instruction.of(Opcode.EXPECT_EQ, 2, 51),
                    Instruction.of(Opcode.SWAP, 1, 2),
                    Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 1),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] helperStatusMutationArtifact(Opcode opcode) {
    Instruction mutation = opcode == Opcode.SWAP
        ? Instruction.of(opcode, 0, 1)
        : Instruction.of(opcode, 0, 51);
    return new BytecodeWriter().write(new Program(
        "scalar-aot-helper-status-mutation",
        1,
        List.of(new Global("status", 0), new Global("value", 1)),
        List.of(
            new FunctionBody(
                0,
                "example.app::mutate",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(mutation, Instruction.of(Opcode.RETURN)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL_VOID, 0, 0, 0),
                    Instruction.of(Opcode.LOCAL_CONST, 0, 0),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] globalOverflowArtifact(Opcode opcode, long initial, long immediate) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-global-overflow",
        0,
        List.of(new Global("status", 0), new Global("value", initial)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(opcode, 1, immediate),
                Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 1),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] stateCheckArtifact(long expected) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-state-check",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.BOOLEAN,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 0, 0x540),
                Instruction.of(Opcode.LOCAL_CONST, 1, 5),
                Instruction.of(Opcode.LOCAL_ROTR32, 2, 0, 1),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 2),
                Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 3, 0),
                Instruction.of(Opcode.LOCAL_CONST, 4, expected),
                Instruction.of(Opcode.LOCAL_EQ, 5, 3, 4),
                Instruction.of(Opcode.EXPECT_TRUE, 5),
                Instruction.of(Opcode.LOCAL_CONST, 6, 31),
                Instruction.of(Opcode.LOCAL_ADD, 3, 3, 6),
                Instruction.of(Opcode.NOP),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 3),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] loopArtifact(long limit, long initial) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-loop",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.SIGNED,
                ValueType.BOOLEAN,
                ValueType.SIGNED,
                ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 0, initial),
                Instruction.of(Opcode.LOCAL_MOVE, 1, 0),
                Instruction.of(Opcode.LOCAL_CONST, 2, limit),
                Instruction.of(Opcode.LOCAL_CONST, 3, 0),
                Instruction.of(Opcode.LOCAL_MOVE, 4, 1),
                Instruction.of(Opcode.LOCAL_CONST, 5, 73),
                Instruction.of(Opcode.LOCAL_LT, 6, 4, 5),
                Instruction.of(Opcode.JUMP_IF_ZERO, 6, 12),
                Instruction.of(Opcode.LOCAL_LOOP_CHECK, 3, 2),
                Instruction.of(Opcode.LOCAL_CONST, 7, 1),
                Instruction.of(Opcode.LOCAL_ADD, 1, 1, 7),
                Instruction.of(Opcode.JUMP, 4),
                Instruction.of(Opcode.LOCAL_MOVE, 8, 1),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 8),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] uncheckedBackwardBranchArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-unchecked-loop",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 0, 73),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                Instruction.of(Opcode.JUMP, 1),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static FunctionBody statusEntry(int id, long status) {
    return new FunctionBody(
        id,
        "example.app::main",
        false,
        0,
        List.of(ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, status),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
  }

  static byte[] arithmeticArtifact(
      Opcode opcode, long left, long right) {
    Program program = new Program(
        "scalar-aot-arithmetic",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, 0, left),
                Instruction.of(Opcode.LOCAL_CONST, 1, right),
                Instruction.of(opcode, 2, 0, 1),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 2),
                Instruction.of(Opcode.HALT)),
            List.of())));
    return new BytecodeWriter().write(program);
  }

  static byte[] artifact(String globalName, long status, boolean extraInstruction) {
    List<Instruction> forward = extraInstruction
        ? List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, status),
            Instruction.of(Opcode.CHECKPOINT),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT))
        : List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, status),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT));
    Program program = new Program(
        "scalar-aot",
        0,
        List.of(new Global(globalName, 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED),
            null,
            forward,
            List.of())));
    return new BytecodeWriter().write(program);
  }

}
