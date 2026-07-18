package com.typeobject.wheeler.core.bytecode;

/** Type and immediate checks for affine region, buffer, and UTF-8 instructions. */
final class StorageInstructionVerifier {
  private StorageInstructionVerifier() {}

  static boolean isOwned(ValueType type) {
    return type.kind() == ValueType.Kind.REGION
        || isBuffer(type)
        || type.kind() == ValueType.Kind.LONG_MAP
        || type.kind() == ValueType.Kind.UTF8;
  }

  static boolean isBuffer(ValueType type) {
    return type.kind() == ValueType.Kind.WORDS || type.kind() == ValueType.Kind.BYTES;
  }

  static void verify(FunctionBody owner, Instruction instruction, int pc) {
    switch (instruction.opcode()) {
      case REGION_NEW -> verifyRegion(owner, instruction, pc);
      case WORDS_ALLOC -> verifyAllocate(owner, instruction, pc, ValueType.WORDS);
      case BYTES_ALLOC -> verifyAllocate(owner, instruction, pc, ValueType.BYTES);
      case WORDS_GET -> verifyGet(owner, instruction, pc, ValueType.WORDS);
      case BYTES_GET -> verifyGet(owner, instruction, pc, ValueType.BYTES);
      case WORDS_SET -> verifySet(owner, instruction, pc, ValueType.WORDS);
      case BYTES_SET -> verifySet(owner, instruction, pc, ValueType.BYTES);
      case UTF8_FREEZE -> verifyFreeze(owner, instruction, pc);
      case UTF8_VALID -> verifyUtf8Whole(owner, instruction, pc, ValueType.BOOLEAN);
      case UTF8_COUNT -> verifyUtf8Whole(owner, instruction, pc, ValueType.SIGNED);
      case UTF8_SCALAR, UTF8_WIDTH -> verifyUtf8At(owner, instruction, pc);
      case BUFFER_LENGTH -> verifyLength(owner, instruction, pc);
      case MAP_ALLOC -> verifyAllocate(owner, instruction, pc, ValueType.LONG_MAP);
      case MAP_PUT -> verifyMapPut(owner, instruction, pc);
      case MAP_GET -> verifyMapRead(owner, instruction, pc, ValueType.SIGNED);
      case MAP_HAS -> verifyMapRead(owner, instruction, pc, ValueType.BOOLEAN);
      case BUFFER_DROP -> verifyBufferDrop(owner, instruction, pc);
      case REGION_DROP -> require(owner, instruction, 0, ValueType.REGION, pc);
      default -> throw new IllegalArgumentException(
          "Not a storage instruction: " + instruction.opcode());
    }
  }

  private static void verifyRegion(FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.REGION, pc);
    long bytes = instruction.operands().get(1);
    long objects = instruction.operands().get(2);
    if (bytes <= 0 || bytes > (1L << 30) || objects <= 0 || objects > 65_535) {
      fail(owner, pc, "invalid region limits");
    }
  }

  private static void verifyAllocate(
      FunctionBody owner, Instruction instruction, int pc, ValueType type) {
    require(owner, instruction, 0, type, pc);
    require(owner, instruction, 1, ValueType.REGION, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyGet(
      FunctionBody owner, Instruction instruction, int pc, ValueType type) {
    require(owner, instruction, 0, ValueType.SIGNED, pc);
    require(owner, instruction, 1, type, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifySet(
      FunctionBody owner, Instruction instruction, int pc, ValueType type) {
    require(owner, instruction, 0, type, pc);
    require(owner, instruction, 1, ValueType.SIGNED, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyUtf8Whole(
      FunctionBody owner, Instruction instruction, int pc, ValueType result) {
    require(owner, instruction, 0, result, pc);
    requireUtf8Sequence(owner, instruction, 1, pc);
  }

  private static void verifyUtf8At(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.SIGNED, pc);
    requireUtf8Sequence(owner, instruction, 1, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyFreeze(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.UTF8, pc);
    require(owner, instruction, 1, ValueType.BYTES, pc);
  }

  private static void verifyMapPut(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.LONG_MAP, pc);
    require(owner, instruction, 1, ValueType.SIGNED, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyMapRead(
      FunctionBody owner, Instruction instruction, int pc, ValueType result) {
    require(owner, instruction, 0, result, pc);
    require(owner, instruction, 1, ValueType.LONG_MAP, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyLength(FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.SIGNED, pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType type = owner.localType(source);
    if (!isBuffer(type) && !type.equals(ValueType.UTF8)) {
      fail(owner, pc, "buffer length requires words, bytes, or utf8");
    }
  }

  private static void verifyBufferDrop(
      FunctionBody owner, Instruction instruction, int pc) {
    int source = local(owner, instruction.operands().getFirst(), pc);
    ValueType type = owner.localType(source);
    if (!isBuffer(type) && !type.equals(ValueType.LONG_MAP)
        && !type.equals(ValueType.UTF8)) {
      fail(owner, pc, "buffer drop requires words, bytes, longmap, or utf8");
    }
  }

  private static void requireUtf8Sequence(
      FunctionBody owner, Instruction instruction, int operand, int pc) {
    int local = local(owner, instruction.operands().get(operand), pc);
    ValueType type = owner.localType(local);
    if (!type.equals(ValueType.BYTES) && !type.equals(ValueType.UTF8)) {
      fail(owner, pc, "expected bytes or utf8 local " + local);
    }
  }

  private static void require(
      FunctionBody owner,
      Instruction instruction,
      int operand,
      ValueType expected,
      int pc) {
    int local = local(owner, instruction.operands().get(operand), pc);
    if (!owner.localType(local).equals(expected)) {
      fail(owner, pc, "expected " + expected.displayName() + " local " + local);
    }
  }

  private static int local(FunctionBody owner, long value, int pc) {
    if (value < 0 || value >= owner.localCount()) {
      fail(owner, pc, "invalid local index " + value);
    }
    return Math.toIntExact(value);
  }

  private static void fail(FunctionBody owner, int pc, String message) {
    throw new BytecodeException(owner.name() + "[" + pc + "] " + message);
  }
}
