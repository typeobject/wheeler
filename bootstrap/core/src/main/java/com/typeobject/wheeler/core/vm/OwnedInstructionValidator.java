package com.typeobject.wheeler.core.vm;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ALLOCATION_LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CAPACITY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.INDEX;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.KEY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LOCAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OWNER;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;

import com.typeobject.wheeler.core.bytecode.InstructionForm;
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
          BUFFER_BORROW, REGION_BORROW,
          MAP_ALLOC, MAP_PUT,
          MAP_GET, MAP_HAS, BUFFER_DROP, REGION_DROP -> true;
      default -> false;
    };
  }

  static void validate(Instruction instruction, Frame frame, OwnedStore store) {
    switch (instruction.opcode()) {
      case REGION_NEW -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateRegionLimits(
            instruction.operand(CAPACITY),
            Math.toIntExact(instruction.operand(ALLOCATION_LIMIT)));
      }
      case WORDS_ALLOC, BYTES_ALLOC, MAP_ALLOC -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateAllocation(
            local(frame, instruction, OWNER),
            Math.toIntExact(local(frame, instruction, CAPACITY)),
            allocationKind(instruction.opcode()));
      }
      case WORDS_GET, BYTES_GET -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateGet(
            local(frame, instruction, OWNER),
            Math.toIntExact(local(frame, instruction, INDEX)),
            bufferKind(instruction.opcode(), Opcode.WORDS_GET));
      }
      case WORDS_SET, BYTES_SET -> store.validateSet(
          local(frame, instruction, OWNER),
          Math.toIntExact(local(frame, instruction, INDEX)),
          local(frame, instruction, SOURCE),
          bufferKind(instruction.opcode(), Opcode.WORDS_SET));
      case UTF8_VALID -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateUtf8Bytes(local(frame, instruction, SOURCE));
      }
      case UTF8_COUNT -> {
        localIndex(frame, instruction, DESTINATION);
        if (!Utf8.analyze(store.utf8Bytes(local(frame, instruction, SOURCE))).valid()) {
          throw new VmTrap("Invalid UTF-8 byte sequence");
        }
      }
      case BUFFER_LENGTH -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateBuffer(local(frame, instruction, SOURCE));
      }
      case UTF8_SCALAR, UTF8_WIDTH -> {
        localIndex(frame, instruction, DESTINATION);
        Utf8.Scalar scalar = Utf8.decode(
            store.utf8Bytes(local(frame, instruction, OWNER)),
            Math.toIntExact(local(frame, instruction, INDEX)));
        if (!scalar.valid()) {
          throw new VmTrap("Invalid UTF-8 scalar boundary");
        }
      }
      case UTF8_FREEZE -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateFreezeUtf8(local(frame, instruction, SOURCE));
      }
      case UTF8_BORROW -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateUtf8Bytes(local(frame, instruction, SOURCE));
      }
      case MAP_BORROW -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateMap(local(frame, instruction, SOURCE));
      }
      case BUFFER_BORROW -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateBuffer(local(frame, instruction, SOURCE));
      }
      case REGION_BORROW -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateRegion(local(frame, instruction, SOURCE));
      }
      case MAP_PUT -> store.validateMapPut(
          local(frame, instruction, OWNER), local(frame, instruction, KEY));
      case MAP_GET -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateMapGet(
            local(frame, instruction, OWNER), local(frame, instruction, KEY));
      }
      case MAP_HAS -> {
        localIndex(frame, instruction, DESTINATION);
        store.validateMap(local(frame, instruction, OWNER));
      }
      case BUFFER_DROP -> store.validateDropBuffer(local(frame, instruction, LOCAL));
      case REGION_DROP -> store.validateDropRegion(local(frame, instruction, LOCAL));
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

  private static int localIndex(
      Frame frame, Instruction instruction, InstructionForm.OperandRole role) {
    int index = Math.toIntExact(instruction.operand(role));
    frame.local(index);
    return index;
  }

  private static long local(
      Frame frame, Instruction instruction, InstructionForm.OperandRole role) {
    return frame.local(localIndex(frame, instruction, role));
  }
}
