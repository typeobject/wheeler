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
      case UTF8_BORROW -> verifyBorrow(owner, instruction, pc);
      case MAP_BORROW -> verifyMapBorrow(owner, instruction, pc);
      case BUFFER_BORROW -> verifyBufferBorrow(owner, instruction, pc);
      case REGION_BORROW -> verifyRegionBorrow(owner, instruction, pc);
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
    int region = local(owner, instruction.operands().get(1), pc);
    ValueType regionType = owner.localType(region);
    if (!regionType.equals(ValueType.REGION)
        && !regionType.equals(ValueType.REGION_BORROW)) {
      fail(owner, pc, "allocation requires a region owner or borrow");
    }
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyGet(
      FunctionBody owner, Instruction instruction, int pc, ValueType type) {
    require(owner, instruction, 0, ValueType.SIGNED, pc);
    requireBuffer(owner, instruction, 1, type, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifySet(
      FunctionBody owner, Instruction instruction, int pc, ValueType type) {
    requireBuffer(owner, instruction, 0, type, pc);
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

  private static void verifyBorrow(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.UTF8_BORROW, pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType type = owner.localType(source);
    if (!type.equals(ValueType.UTF8) && !type.equals(ValueType.UTF8_BORROW)) {
      fail(owner, pc, "UTF-8 borrow requires an immutable UTF-8 source");
    }
  }

  private static void verifyRegionBorrow(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.REGION_BORROW, pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType type = owner.localType(source);
    if (!type.equals(ValueType.REGION) && !type.equals(ValueType.REGION_BORROW)) {
      fail(owner, pc, "region borrow requires a region source");
    }
  }

  private static void verifyBufferBorrow(
      FunctionBody owner, Instruction instruction, int pc) {
    int destination = local(owner, instruction.operands().get(0), pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType expectedOwner;
    if (owner.localType(destination).equals(ValueType.WORDS_BORROW)) {
      expectedOwner = ValueType.WORDS;
    } else if (owner.localType(destination).equals(ValueType.BYTES_BORROW)) {
      expectedOwner = ValueType.BYTES;
    } else {
      fail(owner, pc, "buffer borrow destination has the wrong type");
      return;
    }
    ValueType sourceType = owner.localType(source);
    if (!sourceType.equals(expectedOwner)
        && !(expectedOwner.equals(ValueType.WORDS)
            && sourceType.equals(ValueType.WORDS_BORROW))
        && !(expectedOwner.equals(ValueType.BYTES)
            && sourceType.equals(ValueType.BYTES_BORROW))) {
      fail(owner, pc, "buffer borrow source kind differs from its destination");
    }
  }

  private static void verifyMapBorrow(
      FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.LONG_MAP_BORROW, pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType type = owner.localType(source);
    if (!type.equals(ValueType.LONG_MAP) && !type.equals(ValueType.LONG_MAP_BORROW)) {
      fail(owner, pc, "map borrow requires a signed-map source");
    }
  }

  private static void verifyMapPut(
      FunctionBody owner, Instruction instruction, int pc) {
    requireMap(owner, instruction, 0, pc);
    require(owner, instruction, 1, ValueType.SIGNED, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyMapRead(
      FunctionBody owner, Instruction instruction, int pc, ValueType result) {
    require(owner, instruction, 0, result, pc);
    requireMap(owner, instruction, 1, pc);
    require(owner, instruction, 2, ValueType.SIGNED, pc);
  }

  private static void verifyLength(FunctionBody owner, Instruction instruction, int pc) {
    require(owner, instruction, 0, ValueType.SIGNED, pc);
    int source = local(owner, instruction.operands().get(1), pc);
    ValueType type = owner.localType(source);
    if (!isBuffer(type) && !type.equals(ValueType.UTF8)
        && !type.equals(ValueType.UTF8_BORROW)
        && !type.equals(ValueType.WORDS_BORROW)
        && !type.equals(ValueType.BYTES_BORROW)) {
      fail(owner, pc, "buffer length requires words, bytes, utf8, or a UTF-8 borrow");
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

  private static void requireBuffer(
      FunctionBody owner,
      Instruction instruction,
      int operand,
      ValueType expectedOwner,
      int pc) {
    int local = local(owner, instruction.operands().get(operand), pc);
    ValueType type = owner.localType(local);
    ValueType borrow = expectedOwner.equals(ValueType.WORDS)
        ? ValueType.WORDS_BORROW : ValueType.BYTES_BORROW;
    if (!type.equals(expectedOwner) && !type.equals(borrow)) {
      fail(owner, pc, "buffer source kind differs from its opcode");
    }
  }

  private static void requireMap(
      FunctionBody owner, Instruction instruction, int operand, int pc) {
    int local = local(owner, instruction.operands().get(operand), pc);
    ValueType type = owner.localType(local);
    if (!type.equals(ValueType.LONG_MAP) && !type.equals(ValueType.LONG_MAP_BORROW)) {
      fail(owner, pc, "expected longmap or a map borrow local " + local);
    }
  }

  private static void requireUtf8Sequence(
      FunctionBody owner, Instruction instruction, int operand, int pc) {
    int local = local(owner, instruction.operands().get(operand), pc);
    ValueType type = owner.localType(local);
    if (!type.equals(ValueType.BYTES) && !type.equals(ValueType.BYTES_BORROW)
        && !type.equals(ValueType.UTF8) && !type.equals(ValueType.UTF8_BORROW)) {
      fail(owner, pc, "expected bytes, utf8, or a UTF-8 borrow local " + local);
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
