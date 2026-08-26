package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.List;

/** Scalar AOT call, graph, and frame artifacts. */
final class ScalarAotCallArtifacts {
  private ScalarAotCallArtifacts() {}

  static byte[] helperArtifact(int functionCount) {
    List<FunctionBody> functions = new java.util.ArrayList<>();
    functions.add(new FunctionBody(
        0,
        "example.app::literal",
        false,
        0,
        List.of(ValueType.SIGNED),
        ValueType.SIGNED,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 73),
            Instruction.of(Opcode.RETURN_VALUE, 0)),
        List.of()));
    for (int id = 1; id < functionCount - 1; id++) {
      functions.add(new FunctionBody(
          id,
          "example.app::helper" + id,
          false,
          0,
          List.of(ValueType.SIGNED),
          ValueType.SIGNED,
          List.of(
              Instruction.of(Opcode.CALL_VALUE, id - 1, 0, 0, 0),
              Instruction.of(Opcode.RETURN_VALUE, 0)),
          List.of()));
    }
    int entry = functionCount - 1;
    functions.add(new FunctionBody(
        entry,
        "example.app::main",
        false,
        0,
        List.of(ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.CALL_VALUE, entry - 1, 0, 0, 0),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of()));
    return new BytecodeWriter().write(new Program(
        "scalar-aot-helpers",
        entry,
        List.of(new Global("status", 0)),
        functions));
  }

  static byte[] parameterHelperArtifact(int parameterCount) {
    return parameterHelperArtifact(parameterCount, true);
  }

  static byte[] parameterVoidHelperArtifact(int parameterCount) {
    return parameterHelperArtifact(parameterCount, false);
  }

  private static byte[] parameterHelperArtifact(int parameterCount, boolean returnsValue) {
    List<Instruction> helper = new java.util.ArrayList<>();
    int result = 0;
    for (int parameter = 1; parameter < parameterCount; parameter++) {
      result = parameterCount + parameter - 1;
      int left = parameter == 1 ? 0 : result - 1;
      helper.add(Instruction.of(Opcode.LOCAL_ADD, result, left, parameter));
    }
    if (returnsValue) {
      helper.add(Instruction.of(Opcode.RETURN_VALUE, result));
    } else {
      helper.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 1, result));
      helper.add(Instruction.of(Opcode.RETURN));
    }

    List<Instruction> entry = new java.util.ArrayList<>();
    for (int parameter = 0; parameter < parameterCount; parameter++) {
      long value = parameter + 1 == parameterCount
          ? 73 - parameter
          : 1;
      entry.add(Instruction.of(Opcode.LOCAL_CONST, parameter, value));
    }
    if (returnsValue) {
      entry.add(Instruction.of(
          Opcode.CALL_VALUE, 0, 0, parameterCount, parameterCount));
      entry.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, parameterCount));
    } else {
      entry.add(Instruction.of(Opcode.CALL_VOID, 0, 0, parameterCount));
      entry.add(Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, parameterCount, 1));
      entry.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, parameterCount));
    }
    entry.add(Instruction.of(Opcode.HALT));

    List<Global> globals = returnsValue
        ? List.of(new Global("status", 0))
        : List.of(new Global("status", 0), new Global("result", 0));
    return new BytecodeWriter().write(new Program(
        "scalar-aot-parameter-helper",
        1,
        globals,
        List.of(
            new FunctionBody(
                0,
                "example.app::sum",
                false,
                parameterCount,
                java.util.Collections.nCopies(
                    Math.max(1, parameterCount * 2 - 1), ValueType.SIGNED),
                returnsValue ? ValueType.SIGNED : null,
                helper,
                List.of()),
            new FunctionBody(
                1,
                "example.app::main",
                false,
                0,
                java.util.Collections.nCopies(
                    parameterCount + 1, ValueType.SIGNED),
                null,
                entry,
                List.of()))));
  }

  static byte[] booleanParameterArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-boolean-parameter",
        1,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::select",
                false,
                2,
                List.of(ValueType.BOOLEAN, ValueType.SIGNED, ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.LOCAL_MOVE, 2, 1),
                    Instruction.of(Opcode.RETURN_VALUE, 2)),
                List.of()),
            new FunctionBody(
                1,
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
                    Instruction.of(Opcode.LOCAL_CONST, 0, 1),
                    Instruction.of(Opcode.LOCAL_CONST, 1, 1),
                    Instruction.of(Opcode.LOCAL_EQ, 2, 0, 1),
                    Instruction.of(Opcode.LOCAL_CONST, 3, 73),
                    Instruction.of(Opcode.CALL_VALUE, 0, 2, 2, 4),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 4),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] booleanResultHelperArtifact() {
    FunctionBody helper = new FunctionBody(
        0,
        "example.app::accepted",
        false,
        1,
        List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN),
        ValueType.BOOLEAN,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 1, 73),
            Instruction.of(Opcode.LOCAL_EQ, 2, 0, 1),
            Instruction.of(Opcode.RETURN_VALUE, 2)),
        List.of());
    FunctionBody entry = new FunctionBody(
        1,
        "example.app::main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 73),
            Instruction.of(Opcode.CALL_VALUE, 0, 0, 1, 1),
            Instruction.of(Opcode.EXPECT_TRUE, 1),
            Instruction.of(Opcode.LOCAL_CONST, 2, 73),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 2),
            Instruction.of(Opcode.HALT)),
        List.of());
    return new BytecodeWriter().write(new Program(
        "scalar-aot-boolean-result-helper",
        1,
        List.of(new Global("status", 0)),
        List.of(helper, entry)));
  }

  static byte[] dormantUnsupportedHelperArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-dormant-helper",
        1,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::unused",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.LOCAL_CONST, 0, 73),
                    Instruction.of(Opcode.CHECKPOINT),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
                List.of()),
            ScalarAotArtifacts.statusEntry(1, 73))));
  }

  static byte[] recursiveHelperArtifact(int depth) {
    FunctionBody helper = new FunctionBody(
        0,
        "example.app::recursive",
        false,
        1,
        List.of(
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.BOOLEAN,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.SIGNED,
            ValueType.SIGNED),
        ValueType.SIGNED,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.LOCAL_EQ, 2, 0, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 2, 5),
            Instruction.of(Opcode.LOCAL_CONST, 6, 73),
            Instruction.of(Opcode.JUMP, 8),
            Instruction.of(Opcode.LOCAL_CONST, 4, 1),
            Instruction.of(Opcode.LOCAL_SUB, 5, 0, 4),
            Instruction.of(Opcode.CALL_VALUE, 0, 5, 1, 6),
            Instruction.of(Opcode.RETURN_VALUE, 6)),
        List.of());
    FunctionBody entry = new FunctionBody(
        1,
        "example.app::main",
        false,
        0,
        List.of(ValueType.SIGNED, ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, depth),
            Instruction.of(Opcode.CALL_VALUE, 0, 0, 1, 1),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    return new BytecodeWriter().write(new Program(
        "scalar-aot-recursive-helper",
        1,
        List.of(new Global("status", 0)),
        List.of(helper, entry)));
  }

  static byte[] forwardHelperArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-forward-helper",
        2,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::forward",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 1, 0, 0, 0),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::literal",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.LOCAL_CONST, 0, 73),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
                List.of()),
            new FunctionBody(
                2,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] cyclicHelperArtifact() {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-cyclic-helper",
        2,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::left",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 1, 0, 0, 0),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
                List.of()),
            new FunctionBody(
                1,
                "example.app::right",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
                List.of()),
            new FunctionBody(
                2,
                "example.app::main",
                false,
                0,
                List.of(ValueType.SIGNED),
                null,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] selfCallingHelperArtifact() {
    return invalidCallGraphArtifact(0);
  }

  private static byte[] invalidCallGraphArtifact(int target) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-invalid-call-graph",
        1,
        List.of(new Global("status", 0)),
        List.of(
            new FunctionBody(
                0,
                "example.app::helper",
                false,
                0,
                List.of(ValueType.SIGNED),
                ValueType.SIGNED,
                List.of(
                    Instruction.of(Opcode.CALL_VALUE, target, 0, 0, 0),
                    Instruction.of(Opcode.RETURN_VALUE, 0)),
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
                    Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
                    Instruction.of(Opcode.HALT)),
                List.of()))));
  }

  static byte[] localBoundArtifact(int localCount) {
    return new BytecodeWriter().write(new Program(
        "scalar-aot-local-bound",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            java.util.Collections.nCopies(localCount, ValueType.SIGNED),
            null,
            List.of(
                Instruction.of(Opcode.LOCAL_CONST, localCount - 1, 73),
                Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, localCount - 1),
                Instruction.of(Opcode.HALT)),
            List.of()))));
  }

  static byte[] instructionBoundArtifact(int instructionCount) {
    List<Instruction> instructions = new java.util.ArrayList<>();
    for (int instruction = 0; instruction < instructionCount - 3; instruction++) {
      instructions.add(Instruction.of(Opcode.NOP));
    }
    instructions.add(Instruction.of(Opcode.LOCAL_CONST, 255, 73));
    instructions.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 255));
    instructions.add(Instruction.of(Opcode.HALT));
    return new BytecodeWriter().write(new Program(
        "scalar-aot-instruction-bound",
        0,
        List.of(new Global("status", 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            java.util.Collections.nCopies(256, ValueType.SIGNED),
            null,
            instructions,
            List.of()))));
  }

}
