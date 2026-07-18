package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.Set;

/** Parameter-view selection and alias checks for value-call argument windows. */
final class SourceCallArgumentLowerer {
  private SourceCallArgumentLowerer() {}

  static ValueType parameterType(ValueType sourceType) {
    if (sourceType.equals(ValueType.UTF8)) {
      return ValueType.UTF8_BORROW;
    }
    if (sourceType.equals(ValueType.LONG_MAP)) {
      return ValueType.LONG_MAP_BORROW;
    }
    if (sourceType.equals(ValueType.WORDS)) {
      return ValueType.WORDS_BORROW;
    }
    if (sourceType.equals(ValueType.BYTES)) {
      return ValueType.BYTES_BORROW;
    }
    return sourceType;
  }

  static Opcode copyOpcode(
      ValueType parameterType,
      ValueType sourceType,
      int source,
      Set<Integer> mutableBorrows,
      int line) {
    if (parameterType.equals(ValueType.UTF8_BORROW)) {
      if (!sourceType.equals(ValueType.UTF8)
          && !sourceType.equals(ValueType.UTF8_BORROW)) {
        throw new CompilerException(line, "UTF-8 parameter requires immutable UTF-8");
      }
      return Opcode.UTF8_BORROW;
    }
    if (parameterType.equals(ValueType.LONG_MAP_BORROW)) {
      if (!sourceType.equals(ValueType.LONG_MAP)
          && !sourceType.equals(ValueType.LONG_MAP_BORROW)) {
        throw new CompilerException(line, "longmap parameter requires a signed map");
      }
      if (!mutableBorrows.add(source)) {
        throw new CompilerException(
            line, "one storage owner cannot alias multiple mutable parameters");
      }
      return Opcode.MAP_BORROW;
    }
    if (parameterType.equals(ValueType.WORDS_BORROW)
        || parameterType.equals(ValueType.BYTES_BORROW)) {
      ValueType owner = parameterType.equals(ValueType.WORDS_BORROW)
          ? ValueType.WORDS : ValueType.BYTES;
      if (!sourceType.equals(owner) && !sourceType.equals(parameterType)) {
        throw new CompilerException(line, "buffer parameter kind mismatch");
      }
      if (!mutableBorrows.add(source)) {
        throw new CompilerException(
            line, "one storage owner cannot alias multiple mutable parameters");
      }
      return Opcode.BUFFER_BORROW;
    }
    if (!sourceType.equals(parameterType)) {
      throw new CompilerException(
          line,
          "expected %s expression, got %s"
              .formatted(parameterType.displayName(), sourceType.displayName()));
    }
    return Opcode.LOCAL_MOVE;
  }
}
