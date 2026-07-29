package com.typeobject.wheeler.core.vm;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT_SLOT;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.List;

/** Creates caller/callee frames for verified value and void argument calls. */
final class ArgumentCallBinder {
  record Binding(Frame caller, Frame callee) {}

  private ArgumentCallBinder() {}

  static Binding bind(
      Program program, Frame current, Instruction instruction, boolean returnsValue) {
    int functionId = Math.toIntExact(instruction.operand(FUNCTION));
    int argumentBase = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
    int argumentCount = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
    int destination = returnsValue
        ? Math.toIntExact(instruction.operand(RESULT)) : -1;
    List<Long> arguments = new ArrayList<>(argumentCount);
    for (int index = 0; index < argumentCount; index++) {
      arguments.add(current.local(argumentBase + index));
    }
    FunctionBody target = program.function(functionId);
    Frame caller = current.advance();
    for (int index = 0; index < argumentCount; index++) {
      if (transferred(target.localType(index))) {
        caller = caller.withLocal(argumentBase + index, 0);
      }
    }
    return new Binding(
        caller,
        Frame.create(functionId, false, target.localCount(), destination, arguments));
  }

  static Binding bindResultSlot(
      Program program, Frame current, Instruction instruction, boolean inverse) {
    int functionId = Math.toIntExact(instruction.operand(FUNCTION));
    int argumentBase = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
    int argumentCount = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
    int resultSlot = Math.toIntExact(instruction.operand(RESULT_SLOT));
    List<Long> arguments = new ArrayList<>(argumentCount);
    for (int index = 0; index < argumentCount; index++) {
      arguments.add(current.local(argumentBase + index));
    }
    FunctionBody target = program.function(functionId);
    long tag = current.local(resultSlot);
    long payload = current.local(resultSlot + 1);
    if ((!inverse && (tag != 0 || payload != 0)) || (inverse && tag != 1)) {
      throw new VmTrap(inverse
          ? "Inverse result slot is not holding a value"
          : "Forward result slot is not vacant");
    }
    Frame caller = current.advance();
    for (int index = 0; index < argumentCount; index++) {
      if (transferred(target.localType(index))) {
        caller = caller.withLocal(argumentBase + index, 0);
      }
    }
    Frame callee = Frame.create(
        functionId, inverse, target.localCount(), resultSlot, arguments);
    callee = callee
        .withLocal(target.resultSlotBase(), tag)
        .withLocal(target.resultSlotBase() + 1, payload);
    return new Binding(caller, callee);
  }

  private static boolean transferred(ValueType type) {
    return owned(type) || type.equals(ValueType.UTF8_BORROW)
        || type.equals(ValueType.LONG_MAP_BORROW)
        || type.equals(ValueType.WORDS_BORROW)
        || type.equals(ValueType.BYTES_BORROW)
        || type.equals(ValueType.REGION_BORROW)
        || type.equals(ValueType.BYTE_VIEW);
  }

  private static boolean owned(ValueType type) {
    return type.equals(ValueType.REGION)
        || type.equals(ValueType.WORDS)
        || type.equals(ValueType.BYTES)
        || type.equals(ValueType.LONG_MAP)
        || type.equals(ValueType.UTF8);
  }
}
