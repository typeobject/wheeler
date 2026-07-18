package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;

/** Preflight checks for region, buffer, map, and UTF-8 instructions. */
final class OwnedInstructionValidator {
  private OwnedInstructionValidator() {}

  static boolean handles(Opcode opcode) {
    return switch (opcode) {
      case REGION_NEW, WORDS_ALLOC, BYTES_ALLOC, WORDS_GET, BYTES_GET,
          WORDS_SET, BYTES_SET, UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH,
          UTF8_SCALAR, UTF8_WIDTH, UTF8_FREEZE, UTF8_BORROW, MAP_BORROW,
          MAP_ALLOC, MAP_PUT,
          MAP_GET, MAP_HAS, BUFFER_DROP, REGION_DROP -> true;
      default -> false;
    };
  }

  static void validate(Instruction instruction, Frame frame, OwnedStore store) {
    switch (instruction.opcode()) {
      case REGION_NEW -> {
        localIndex(frame, instruction, 0);
        store.validateRegionLimits(
            operand(instruction, 1), Math.toIntExact(operand(instruction, 2)));
      }
      case WORDS_ALLOC, BYTES_ALLOC, MAP_ALLOC -> {
        localIndex(frame, instruction, 0);
        store.validateAllocation(
            local(frame, instruction, 1),
            Math.toIntExact(local(frame, instruction, 2)),
            allocationKind(instruction.opcode()));
      }
      case WORDS_GET, BYTES_GET -> {
        localIndex(frame, instruction, 0);
        store.validateGet(
            local(frame, instruction, 1),
            Math.toIntExact(local(frame, instruction, 2)),
            bufferKind(instruction.opcode(), Opcode.WORDS_GET));
      }
      case WORDS_SET, BYTES_SET -> store.validateSet(
          local(frame, instruction, 0),
          Math.toIntExact(local(frame, instruction, 1)),
          local(frame, instruction, 2),
          bufferKind(instruction.opcode(), Opcode.WORDS_SET));
      case UTF8_VALID -> {
        localIndex(frame, instruction, 0);
        store.validateUtf8Bytes(local(frame, instruction, 1));
      }
      case UTF8_COUNT -> {
        localIndex(frame, instruction, 0);
        if (!Utf8.analyze(store.utf8Bytes(local(frame, instruction, 1))).valid()) {
          throw new VmTrap("Invalid UTF-8 byte sequence");
        }
      }
      case BUFFER_LENGTH -> {
        localIndex(frame, instruction, 0);
        store.validateBuffer(local(frame, instruction, 1));
      }
      case UTF8_SCALAR, UTF8_WIDTH -> {
        localIndex(frame, instruction, 0);
        Utf8.Scalar scalar = Utf8.decode(
            store.utf8Bytes(local(frame, instruction, 1)),
            Math.toIntExact(local(frame, instruction, 2)));
        if (!scalar.valid()) {
          throw new VmTrap("Invalid UTF-8 scalar boundary");
        }
      }
      case UTF8_FREEZE -> {
        localIndex(frame, instruction, 0);
        store.validateFreezeUtf8(local(frame, instruction, 1));
      }
      case UTF8_BORROW -> {
        localIndex(frame, instruction, 0);
        store.validateUtf8Bytes(local(frame, instruction, 1));
      }
      case MAP_BORROW -> {
        localIndex(frame, instruction, 0);
        store.validateMap(local(frame, instruction, 1));
      }
      case MAP_PUT -> store.validateMapPut(
          local(frame, instruction, 0), local(frame, instruction, 1));
      case MAP_GET -> {
        localIndex(frame, instruction, 0);
        store.validateMapGet(
            local(frame, instruction, 1), local(frame, instruction, 2));
      }
      case MAP_HAS -> {
        localIndex(frame, instruction, 0);
        store.validateMap(local(frame, instruction, 1));
      }
      case BUFFER_DROP -> store.validateDropBuffer(local(frame, instruction, 0));
      case REGION_DROP -> store.validateDropRegion(local(frame, instruction, 0));
      default -> throw new IllegalArgumentException(
          "Not an owned-storage instruction: " + instruction.opcode());
    }
  }

  private static BufferKind allocationKind(Opcode opcode) {
    return switch (opcode) {
      case WORDS_ALLOC -> BufferKind.WORDS;
      case BYTES_ALLOC -> BufferKind.BYTES;
      case MAP_ALLOC -> BufferKind.LONG_MAP;
      default -> throw new IllegalArgumentException("Not an allocation opcode: " + opcode);
    };
  }

  private static BufferKind bufferKind(Opcode opcode, Opcode wordsOpcode) {
    return opcode == wordsOpcode ? BufferKind.WORDS : BufferKind.BYTES;
  }

  private static int localIndex(Frame frame, Instruction instruction, int operand) {
    int index = Math.toIntExact(operand(instruction, operand));
    frame.local(index);
    return index;
  }

  private static long local(Frame frame, Instruction instruction, int operand) {
    return frame.local(localIndex(frame, instruction, operand));
  }

  private static long operand(Instruction instruction, int index) {
    return instruction.operands().get(index);
  }
}
