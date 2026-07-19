package com.typeobject.wheeler.core.vm;

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
    int functionId = Math.toIntExact(instruction.operands().get(0));
    int argumentBase = Math.toIntExact(instruction.operands().get(1));
    int argumentCount = Math.toIntExact(instruction.operands().get(2));
    int destination = returnsValue
        ? Math.toIntExact(instruction.operands().get(3)) : -1;
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
