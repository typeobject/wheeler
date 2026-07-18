package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.ValueType;

/** Lowering rules for affine region owners and their fixed-length buffers. */
final class SourceStorageLowerer {
  interface Context {
    int requireLocal(String name, int line);

    void requireType(int local, ValueType type, int line);

    ValueType localType(int local);

    int declareInternal(String name, int line, ValueType type);

    void emit(Instruction instruction);
  }

  private SourceStorageLowerer() {}

  static void lower(Statement statement, Context context) {
    switch (statement.operation()) {
      case "region_new" -> lowerRegionNew(statement, context);
      case "words_alloc", "bytes_alloc" -> lowerBufferAllocate(statement, context);
      case "words_set", "bytes_set" -> lowerBufferSet(statement, context);
      case "owned_drop" -> lowerDrop(statement, context);
      case "utf8_valid", "utf8_count" -> lowerUtf8(statement, context);
      case "buffer_length" -> lowerLength(statement, context);
      case "utf8_scalar", "utf8_width" -> lowerUtf8Scalar(statement, context);
      default -> throw new IllegalArgumentException(
          "Not a storage operation: " + statement.operation());
    }
  }

  static Opcode getOpcode(ValueType type, int line) {
    if (type.equals(ValueType.WORDS)) {
      return Opcode.WORDS_GET;
    }
    if (type.equals(ValueType.BYTES)) {
      return Opcode.BYTES_GET;
    }
    throw new CompilerException(line, "indexing requires an array, slice, or buffer");
  }

  private static void lowerRegionNew(Statement statement, Context context) {
    requireArguments(statement, 3);
    long maxBytes = SourceParser.parseInteger(
        statement.arguments().get(1), statement.line());
    long maxObjects = SourceParser.parseInteger(
        statement.arguments().get(2), statement.line());
    if (maxBytes <= 0 || maxBytes > (1L << 30)
        || maxObjects <= 0 || maxObjects > 65_535) {
      throw new CompilerException(statement.line(), "invalid region limits");
    }
    int destination = context.declareInternal(
        statement.arguments().get(0), statement.line(), ValueType.REGION);
    context.emit(Instruction.of(
        Opcode.REGION_NEW, destination, maxBytes, maxObjects));
  }

  private static void lowerBufferAllocate(Statement statement, Context context) {
    requireArguments(statement, 4);
    String intrinsic = statement.arguments().get(1);
    ValueType bufferType = intrinsic.equals("allocate")
        ? ValueType.WORDS
        : intrinsic.equals("allocateBytes") ? ValueType.BYTES : null;
    if (bufferType == null) {
      throw new CompilerException(statement.line(), "malformed buffer allocation");
    }
    int region = context.requireLocal(statement.arguments().get(2), statement.line());
    int length = context.requireLocal(statement.arguments().get(3), statement.line());
    context.requireType(region, ValueType.REGION, statement.line());
    context.requireType(length, ValueType.SIGNED, statement.line());
    int destination = context.declareInternal(
        statement.arguments().get(0), statement.line(), bufferType);
    Opcode opcode = bufferType.equals(ValueType.WORDS)
        ? Opcode.WORDS_ALLOC : Opcode.BYTES_ALLOC;
    context.emit(Instruction.of(opcode, destination, region, length));
  }

  private static void lowerBufferSet(Statement statement, Context context) {
    requireArguments(statement, 3);
    int buffer = context.requireLocal(statement.arguments().get(0), statement.line());
    int index = context.requireLocal(statement.arguments().get(1), statement.line());
    int value = context.requireLocal(statement.arguments().get(2), statement.line());
    ValueType expected = statement.operation().equals("words_set")
        ? ValueType.WORDS : ValueType.BYTES;
    context.requireType(buffer, expected, statement.line());
    context.requireType(index, ValueType.SIGNED, statement.line());
    context.requireType(value, ValueType.SIGNED, statement.line());
    Opcode opcode = expected.equals(ValueType.WORDS)
        ? Opcode.WORDS_SET : Opcode.BYTES_SET;
    context.emit(Instruction.of(opcode, buffer, index, value));
  }

  private static void lowerUtf8Scalar(Statement statement, Context context) {
    requireArguments(statement, 4);
    int bytes = context.requireLocal(statement.arguments().get(2), statement.line());
    int index = context.requireLocal(statement.arguments().get(3), statement.line());
    context.requireType(bytes, ValueType.BYTES, statement.line());
    context.requireType(index, ValueType.SIGNED, statement.line());
    int destination = context.declareInternal(
        statement.arguments().get(0), statement.line(), ValueType.SIGNED);
    Opcode opcode = statement.operation().equals("utf8_scalar")
        ? Opcode.UTF8_SCALAR : Opcode.UTF8_WIDTH;
    context.emit(Instruction.of(opcode, destination, bytes, index));
  }

  private static void lowerLength(Statement statement, Context context) {
    requireArguments(statement, 3);
    int buffer = context.requireLocal(statement.arguments().get(2), statement.line());
    ValueType type = context.localType(buffer);
    if (!type.equals(ValueType.WORDS) && !type.equals(ValueType.BYTES)) {
      throw new CompilerException(statement.line(), "bufferLength requires words or bytes");
    }
    int destination = context.declareInternal(
        statement.arguments().get(0), statement.line(), ValueType.SIGNED);
    context.emit(Instruction.of(Opcode.BUFFER_LENGTH, destination, buffer));
  }

  private static void lowerUtf8(Statement statement, Context context) {
    requireArguments(statement, 3);
    int bytes = context.requireLocal(statement.arguments().get(2), statement.line());
    context.requireType(bytes, ValueType.BYTES, statement.line());
    boolean validation = statement.operation().equals("utf8_valid");
    ValueType resultType = validation ? ValueType.BOOLEAN : ValueType.SIGNED;
    int destination = context.declareInternal(
        statement.arguments().get(0), statement.line(), resultType);
    context.emit(Instruction.of(
        validation ? Opcode.UTF8_VALID : Opcode.UTF8_COUNT,
        destination,
        bytes));
  }

  private static void lowerDrop(Statement statement, Context context) {
    requireArguments(statement, 1);
    int local = context.requireLocal(statement.arguments().getFirst(), statement.line());
    ValueType type = context.localType(local);
    Opcode opcode = type.equals(ValueType.WORDS) || type.equals(ValueType.BYTES)
        ? Opcode.BUFFER_DROP
        : type.equals(ValueType.REGION) ? Opcode.REGION_DROP : null;
    if (opcode == null) {
      throw new CompilerException(statement.line(), "drop requires an owned value");
    }
    context.emit(Instruction.of(opcode, local));
  }

  private static void requireArguments(Statement statement, int count) {
    if (statement.arguments().size() != count) {
      throw new CompilerException(statement.line(), "malformed storage operation");
    }
  }
}
