package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.Opcode;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

/** Bounded position-independent x86-64 instruction encoder for scalar AOT. */
final class ScalarAotX86 {
  private static final int REGISTER_ARGUMENTS = 6;

  private final ByteArrayOutputStream output = new ByteArrayOutputStream(2048);
  private final ArrayList<RelativePatch> relativePatches = new ArrayList<>();
  private int utf8DecoderOffset = -1;

  int position() {
    return output.size();
  }

  void bytes(int... values) {
    for (int value : values) {
      output.write(value);
    }
  }

  int reserveInt() {
    int result = position();
    integer(0);
    return result;
  }

  void integer(int value) {
    for (int shift = 0; shift < Integer.SIZE; shift += Byte.SIZE) {
      output.write(value >>> shift);
    }
  }

  void word(long value) {
    for (int shift = 0; shift < Long.SIZE; shift += Byte.SIZE) {
      output.write((int) (value >>> shift));
    }
  }

  void stack(int delta) {
    bytes(0x48, 0x81, delta < 0 ? 0xec : 0xc4);
    integer(Math.abs(delta));
  }

  void moveImmediateToRax(long value) {
    bytes(0x48, 0xb8);
    word(value);
  }

  private void moveImmediateToRcx(long value) {
    bytes(0x48, 0xb9);
    word(value);
  }

  void loadRax(int local) {
    loadRaxOffset(local * Long.BYTES);
  }

  private void loadRaxOffset(int offset) {
    bytes(0x48, 0x8b, 0x84, 0x24);
    integer(offset);
  }

  void loadRcx(int local) {
    bytes(0x48, 0x8b, 0x8c, 0x24);
    integer(local * Long.BYTES);
  }

  void loadR8(int local) {
    bytes(0x4c, 0x8b, 0x84, 0x24);
    integer(local * Long.BYTES);
  }

  void loadR10(int local) {
    bytes(0x4c, 0x8b, 0x94, 0x24);
    integer(local * Long.BYTES);
  }

  void storeRax(int local) {
    storeRaxOffset(local * Long.BYTES);
  }

  private void storeRaxOffset(int offset) {
    bytes(0x48, 0x89, 0x84, 0x24);
    integer(offset);
  }

  void loadGlobal(int global) {
    bytes(0x49, 0x8b, 0x86);
    integer(global * Long.BYTES);
  }

  void storeGlobal(int global) {
    bytes(0x49, 0x89, 0x86);
    integer(global * Long.BYTES);
  }

  void setGlobal(int global, long value) {
    moveImmediateToRax(value);
    storeGlobal(global);
  }

  void swapGlobals(int left, int right) {
    loadGlobal(left);
    bytes(0x49, 0x8b, 0x8e);
    integer(right * Long.BYTES);
    storeGlobal(right);
    bytes(0x48, 0x89, 0xc8);
    storeGlobal(left);
  }

  void updateGlobal(
      Opcode opcode,
      int global,
      long immediate,
      ArrayList<Integer> traps) {
    loadGlobal(global);
    moveImmediateToRcx(immediate);
    Opcode localOpcode = switch (opcode) {
      case ADD_CONST -> Opcode.LOCAL_ADD;
      case SUB_CONST -> Opcode.LOCAL_SUB;
      case XOR_CONST -> Opcode.LOCAL_XOR;
      default -> throw new IllegalStateException("Validated scalar global update changed");
    };
    arithmetic(localOpcode, traps);
    storeGlobal(global);
  }

  void expectGlobal(int global, long expected, ArrayList<Integer> traps) {
    loadGlobal(global);
    moveImmediateToRcx(expected);
    bytes(0x48, 0x39, 0xc8, 0x0f, 0x85);
    traps.add(reserveInt());
  }

  int loadArguments(int argumentBase, int argumentCount) {
    if (argumentCount < 0 || ScalarAotProgram.MAX_PARAMETERS < argumentCount) {
      throw new IllegalStateException("Validated scalar AOT argument width changed");
    }

    int stackArguments = Math.max(0, argumentCount - REGISTER_ARGUMENTS);
    int callAreaBytes = alignBytes(Math.multiplyExact(stackArguments, Long.BYTES));
    if (0 < callAreaBytes) {
      stack(-callAreaBytes);
    }

    int registerArguments = Math.min(argumentCount, REGISTER_ARGUMENTS);
    for (int argument = 0; argument < registerArguments; argument++) {
      loadRegisterArgument(argument, argumentBase + argument, callAreaBytes);
    }
    for (int argument = REGISTER_ARGUMENTS; argument < argumentCount; argument++) {
      loadRaxOffset((argumentBase + argument) * Long.BYTES + callAreaBytes);
      storeRaxOffset((argument - REGISTER_ARGUMENTS) * Long.BYTES);
    }
    return callAreaBytes;
  }

  void closeArguments(int callAreaBytes) {
    if (0 < callAreaBytes) {
      stack(callAreaBytes);
    }
  }

  private void loadRegisterArgument(int argument, int local, int callAreaBytes) {
    switch (argument) {
      case 0 -> bytes(0x48, 0x8b, 0xbc, 0x24);
      case 1 -> bytes(0x48, 0x8b, 0xb4, 0x24);
      case 2 -> bytes(0x48, 0x8b, 0x94, 0x24);
      case 3 -> bytes(0x48, 0x8b, 0x8c, 0x24);
      case 4 -> bytes(0x4c, 0x8b, 0x84, 0x24);
      case 5 -> bytes(0x4c, 0x8b, 0x8c, 0x24);
      default -> throw new IllegalStateException("Validated scalar AOT register changed");
    }
    integer(local * Long.BYTES + callAreaBytes);
  }

  void storeArgument(int argument, int frameBytes) {
    if (REGISTER_ARGUMENTS <= argument) {
      int stackOffset = frameBytes + Long.BYTES
          + (argument - REGISTER_ARGUMENTS) * Long.BYTES;
      loadRaxOffset(stackOffset);
      storeRax(argument);
      return;
    }

    switch (argument) {
      case 0 -> bytes(0x48, 0x89, 0xbc, 0x24);
      case 1 -> bytes(0x48, 0x89, 0xb4, 0x24);
      case 2 -> bytes(0x48, 0x89, 0x94, 0x24);
      case 3 -> bytes(0x48, 0x89, 0x8c, 0x24);
      case 4 -> bytes(0x4c, 0x89, 0x84, 0x24);
      case 5 -> bytes(0x4c, 0x89, 0x8c, 0x24);
      default -> throw new IllegalStateException("Validated scalar AOT parameter changed");
    }
    integer(argument * Long.BYTES);
  }

  void leaRax(int stackOffset) {
    bytes(0x48, 0x8d, 0x84, 0x24);
    integer(stackOffset);
  }

  void leaR13(int stackOffset) {
    bytes(0x4c, 0x8d, 0xac, 0x24);
    integer(stackOffset);
  }

  void leaR14(int stackOffset) {
    bytes(0x4c, 0x8d, 0xb4, 0x24);
    integer(stackOffset);
  }

  void leaR15(int stackOffset) {
    bytes(0x4c, 0x8d, 0xbc, 0x24);
    integer(stackOffset);
  }

  void consumeFuel(ArrayList<Integer> traps) {
    bytes(0x49, 0x83, 0x2f, 0x01, 0x0f, 0x88);
    traps.add(reserveInt());
  }

  void enterCall(ArrayList<Integer> traps) {
    bytes(0x49, 0x83, 0x45, 0x00, 0x01);
    bytes(0x49, 0x83, 0x7d, 0x00, ScalarAotProgram.MAX_CALL_DEPTH);
    bytes(0x0f, 0x8f);
    traps.add(reserveInt());
  }

  void leaveCall() {
    bytes(0x49, 0x83, 0x6d, 0x00, 0x01);
  }

  void zeroOutput(IoLayout io) {
    bytes(0x48, 0x8d, 0xbc, 0x24);
    integer(io.outputOffset());
    bytes(0x31, 0xc0, 0xb9);
    integer(ScalarAotProgram.MAX_OUTPUT_BYTES / Long.BYTES);
    bytes(0xfc, 0xf3, 0x48, 0xab);
  }

  void readInput(IoLayout io, ArrayList<Integer> traps) {
    bytes(0x31, 0xc0);
    storeRax(io.inputLengthSlot());
    int loop = position();
    loadRax(io.inputLengthSlot());
    bytes(0x48, 0x3d);
    integer(ScalarAotProgram.MAX_INPUT_BYTES);
    bytes(0x0f, 0x84);
    int fullJump = reserveInt();
    bytes(0x48, 0x8d, 0xb4, 0x04);
    integer(io.inputOffset());
    bytes(0xba);
    integer(ScalarAotProgram.MAX_INPUT_BYTES);
    bytes(0x29, 0xc2, 0x31, 0xff, 0x31, 0xc0, 0x0f, 0x05);
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    traps.add(reserveInt());
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x84);
    int completeJump = reserveInt();
    bytes(0x48, 0x01, 0x84, 0x24);
    integer(io.inputLengthSlot() * Long.BYTES);
    bytes(0xe9);
    int loopJump = reserveInt();
    int full = position();
    bytes(0x31, 0xff);
    leaRsi(io.outputOffset());
    bytes(0xba);
    integer(1);
    bytes(0x31, 0xc0, 0x0f, 0x05, 0x48, 0x85, 0xc0, 0x0f, 0x85);
    traps.add(reserveInt());
    int complete = position();
    patchRelativeInt(fullJump, full);
    patchRelativeInt(completeJump, complete);
    patchRelativeInt(loopJump, loop);
  }

  void installUtf8Decoder(IoLayout io) {
    if (io == null || utf8DecoderOffset >= 0) {
      throw new IllegalStateException("UTF-8 decoder installation changed");
    }
    utf8DecoderOffset = position();
    ArrayList<Integer> invalid = new ArrayList<>();
    ArrayList<Integer> valid = new ArrayList<>();

    bytes(0x31, 0xd2, 0x4c, 0x89, 0xc0, 0x48, 0x85, 0xc0, 0x0f, 0x88);
    invalid.add(reserveInt());
    bytes(0x4d, 0x8b, 0x0a, 0x4d, 0x39, 0xc8, 0x0f, 0x83);
    invalid.add(reserveInt());
    utf8ByteToEax(io.inputDataOffset());
    bytes(0x3d);
    integer(0x7f);
    bytes(0x0f, 0x86);
    int ascii = reserveInt();
    bytes(0x3d);
    integer(0xc2);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    bytes(0x3d);
    integer(0xdf);
    bytes(0x0f, 0x86);
    int two = reserveInt();
    bytes(0x3d);
    integer(0xef);
    bytes(0x0f, 0x86);
    int three = reserveInt();
    bytes(0x3d);
    integer(0xf4);
    bytes(0x0f, 0x86);
    int four = reserveInt();
    bytes(0xe9);
    invalid.add(reserveInt());

    int asciiTarget = position();
    bytes(0xb9);
    integer(1);
    bytes(0xe9);
    valid.add(reserveInt());

    int twoTarget = position();
    bytes(0x89, 0xc7, 0x4d, 0x8d, 0x58, 0x01, 0x4d, 0x39, 0xcb, 0x0f, 0x83);
    invalid.add(reserveInt());
    utf8ByteToR11(io.inputDataOffset() + 1);
    continuationR11(invalid);
    bytes(0x89, 0xf8, 0x83, 0xe0, 0x1f, 0xc1, 0xe0, 0x06);
    bytes(0x41, 0x83, 0xe3, 0x3f, 0x4c, 0x09, 0xd8, 0xb9);
    integer(2);
    bytes(0xe9);
    valid.add(reserveInt());

    int threeTarget = position();
    bytes(0x89, 0xc7, 0x4d, 0x8d, 0x58, 0x02, 0x4d, 0x39, 0xcb, 0x0f, 0x83);
    invalid.add(reserveInt());
    utf8ByteToR11(io.inputDataOffset() + 1);
    continuationR11(invalid);
    bytes(0x81, 0xff);
    integer(0xe0);
    bytes(0x0f, 0x85);
    int notE0 = reserveInt();
    bytes(0x41, 0x81, 0xfb);
    integer(0xa0);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    int afterE0 = position();
    bytes(0x81, 0xff);
    integer(0xed);
    bytes(0x0f, 0x85);
    int notEd = reserveInt();
    bytes(0x41, 0x81, 0xfb);
    integer(0x9f);
    bytes(0x0f, 0x87);
    invalid.add(reserveInt());
    int afterEd = position();
    utf8ByteToEsi(io.inputDataOffset() + 2);
    continuationEsi(invalid);
    bytes(0x89, 0xf8, 0x83, 0xe0, 0x0f, 0xc1, 0xe0, 0x0c);
    bytes(0x41, 0x83, 0xe3, 0x3f, 0x41, 0xc1, 0xe3, 0x06);
    bytes(0x83, 0xe6, 0x3f, 0x4c, 0x09, 0xd8, 0x48, 0x09, 0xf0, 0xb9);
    integer(3);
    bytes(0xe9);
    valid.add(reserveInt());

    int fourTarget = position();
    bytes(0x89, 0xc7, 0x4d, 0x8d, 0x58, 0x03, 0x4d, 0x39, 0xcb, 0x0f, 0x83);
    invalid.add(reserveInt());
    utf8ByteToR11(io.inputDataOffset() + 1);
    continuationR11(invalid);
    bytes(0x81, 0xff);
    integer(0xf0);
    bytes(0x0f, 0x85);
    int notF0 = reserveInt();
    bytes(0x41, 0x81, 0xfb);
    integer(0x90);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    int afterF0 = position();
    bytes(0x81, 0xff);
    integer(0xf4);
    bytes(0x0f, 0x85);
    int notF4 = reserveInt();
    bytes(0x41, 0x81, 0xfb);
    integer(0x8f);
    bytes(0x0f, 0x87);
    invalid.add(reserveInt());
    int afterF4 = position();
    utf8ByteToEsi(io.inputDataOffset() + 2);
    continuationEsi(invalid);
    utf8ByteToEdx(io.inputDataOffset() + 3);
    continuationEdx(invalid);
    bytes(0x89, 0xf8, 0x83, 0xe0, 0x07, 0xc1, 0xe0, 0x12);
    bytes(0x41, 0x83, 0xe3, 0x3f, 0x41, 0xc1, 0xe3, 0x0c);
    bytes(0x83, 0xe6, 0x3f, 0xc1, 0xe6, 0x06, 0x83, 0xe2, 0x3f);
    bytes(0x4c, 0x09, 0xd8, 0x48, 0x09, 0xf0, 0x48, 0x09, 0xd0, 0xb9);
    integer(4);
    bytes(0xe9);
    valid.add(reserveInt());

    int validTarget = position();
    bytes(0xba);
    integer(1);
    bytes(0xc3);
    int invalidTarget = position();
    bytes(0x31, 0xc0, 0x31, 0xc9, 0x31, 0xd2, 0xc3);

    patchRelativeInt(ascii, asciiTarget);
    patchRelativeInt(two, twoTarget);
    patchRelativeInt(three, threeTarget);
    patchRelativeInt(four, fourTarget);
    patchRelativeInt(notE0, afterE0);
    patchRelativeInt(notEd, afterEd);
    patchRelativeInt(notF0, afterF0);
    patchRelativeInt(notF4, afterF4);
    for (int patch : valid) {
      patchRelativeInt(patch, validTarget);
    }
    for (int patch : invalid) {
      patchRelativeInt(patch, invalidTarget);
    }
  }

  void utf8Whole(int ownerLocal, Opcode opcode, ArrayList<Integer> traps) {
    loadR10(ownerLocal);
    bytes(0x45, 0x31, 0xc0, 0x45, 0x31, 0xe4);
    int loop = position();
    bytes(0x4d, 0x8b, 0x0a, 0x4d, 0x39, 0xc8, 0x0f, 0x83);
    int doneJump = reserveInt();
    callUtf8Decoder();
    bytes(0x85, 0xd2, 0x0f, 0x84);
    int invalidJump = reserveInt();
    bytes(0x49, 0x01, 0xc8, 0x49, 0xff, 0xc4, 0xe9);
    int loopJump = reserveInt();
    int invalid = position();
    patchRelativeInt(invalidJump, invalid);
    int completeJump = -1;
    if (opcode == Opcode.UTF8_VALID) {
      bytes(0x31, 0xc0, 0xe9);
      completeJump = reserveInt();
    } else {
      bytes(0xe9);
      traps.add(reserveInt());
    }
    int done = position();
    patchRelativeInt(doneJump, done);
    if (opcode == Opcode.UTF8_VALID) {
      bytes(0xb8);
      integer(1);
    } else {
      bytes(0x4c, 0x89, 0xe0);
    }
    int complete = position();
    patchRelativeInt(loopJump, loop);
    if (completeJump >= 0) {
      patchRelativeInt(completeJump, complete);
    }
  }

  void utf8At(
      int ownerLocal,
      int indexLocal,
      Opcode opcode,
      ArrayList<Integer> traps) {
    loadR10(ownerLocal);
    loadR8(indexLocal);
    callUtf8Decoder();
    bytes(0x85, 0xd2, 0x0f, 0x84);
    traps.add(reserveInt());
    if (opcode == Opcode.UTF8_WIDTH) {
      bytes(0x48, 0x89, 0xc8);
    }
  }

  private void callUtf8Decoder() {
    if (utf8DecoderOffset < 0) {
      throw new IllegalStateException("UTF-8 decoder is not installed");
    }
    bytes(0xe8);
    int displacement = reserveInt();
    patchRelativeInt(displacement, utf8DecoderOffset);
  }

  private void utf8ByteToEax(int displacement) {
    bytes(0x43, 0x0f, 0xb6, 0x84, 0x02);
    integer(displacement);
  }

  private void utf8ByteToR11(int displacement) {
    bytes(0x47, 0x0f, 0xb6, 0x9c, 0x02);
    integer(displacement);
  }

  private void utf8ByteToEsi(int displacement) {
    bytes(0x43, 0x0f, 0xb6, 0xb4, 0x02);
    integer(displacement);
  }

  private void utf8ByteToEdx(int displacement) {
    bytes(0x43, 0x0f, 0xb6, 0x94, 0x02);
    integer(displacement);
  }

  private void continuationR11(ArrayList<Integer> invalid) {
    bytes(0x41, 0x81, 0xfb);
    integer(0x80);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    bytes(0x41, 0x81, 0xfb);
    integer(0xbf);
    bytes(0x0f, 0x87);
    invalid.add(reserveInt());
  }

  private void continuationEsi(ArrayList<Integer> invalid) {
    bytes(0x81, 0xfe);
    integer(0x80);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    bytes(0x81, 0xfe);
    integer(0xbf);
    bytes(0x0f, 0x87);
    invalid.add(reserveInt());
  }

  private void continuationEdx(ArrayList<Integer> invalid) {
    bytes(0x81, 0xfa);
    integer(0x80);
    bytes(0x0f, 0x82);
    invalid.add(reserveInt());
    bytes(0x81, 0xfa);
    integer(0xbf);
    bytes(0x0f, 0x87);
    invalid.add(reserveInt());
  }

  void bufferLength(int ownerLocal) {
    loadR10(ownerLocal);
    bytes(0x49, 0x8b, 0x02);
  }

  void inputByte(
      int ownerLocal,
      int indexLocal,
      IoLayout io,
      ArrayList<Integer> traps) {
    loadRax(indexLocal);
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    traps.add(reserveInt());
    loadR10(ownerLocal);
    bytes(0x49, 0x8b, 0x0a, 0x48, 0x39, 0xc8, 0x0f, 0x83);
    traps.add(reserveInt());
    bytes(0x41, 0x0f, 0xb6, 0x84, 0x02);
    integer(io.inputDataOffset());
  }

  void outputByte(
      int ownerLocal,
      int indexLocal,
      int valueLocal,
      IoLayout io,
      ArrayList<Integer> traps) {
    loadRax(indexLocal);
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    traps.add(reserveInt());
    bytes(0x48, 0x3d);
    integer(ScalarAotProgram.MAX_OUTPUT_BYTES - 1);
    bytes(0x0f, 0x87);
    traps.add(reserveInt());
    loadRcx(valueLocal);
    bytes(0x48, 0x85, 0xc9, 0x0f, 0x88);
    traps.add(reserveInt());
    bytes(0x48, 0x81, 0xf9);
    integer(255);
    bytes(0x0f, 0x87);
    traps.add(reserveInt());
    loadR10(ownerLocal);
    bytes(0x41, 0x88, 0x8c, 0x02);
    integer(io.outputDataOffset());
  }

  void outputLength(
      int ownerLocal,
      int lengthLocal,
      IoLayout io,
      ArrayList<Integer> traps) {
    loadRax(lengthLocal);
    validOutputLength(traps);
    loadR10(ownerLocal);
    bytes(0x49, 0x89, 0x02);
  }

  void writeOutput(IoLayout io, ArrayList<Integer> traps) {
    loadRax(io.outputLengthSlot());
    validOutputLength(traps);
    bytes(0x48, 0x89, 0xc2);
    leaRsi(io.outputOffset());
    bytes(0xbf);
    integer(1);
    bytes(0xb8);
    integer(1);
    bytes(0x0f, 0x05, 0x48, 0x39, 0xd0, 0x0f, 0x85);
    traps.add(reserveInt());
  }

  private void validOutputLength(ArrayList<Integer> traps) {
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x8e);
    traps.add(reserveInt());
    bytes(0x48, 0x3d);
    integer(ScalarAotProgram.MAX_OUTPUT_BYTES);
    bytes(0x0f, 0x8f);
    traps.add(reserveInt());
  }

  private void leaRsi(int stackOffset) {
    bytes(0x48, 0x8d, 0xb4, 0x24);
    integer(stackOffset);
  }

  void arithmetic(Opcode opcode, ArrayList<Integer> traps) {
    switch (opcode) {
      case LOCAL_ADD -> {
        bytes(0x48, 0x01, 0xc8, 0x0f, 0x80);
        traps.add(reserveInt());
      }
      case LOCAL_SUB -> {
        bytes(0x48, 0x29, 0xc8, 0x0f, 0x80);
        traps.add(reserveInt());
      }
      case LOCAL_MUL -> {
        bytes(0x48, 0x0f, 0xaf, 0xc1, 0x0f, 0x80);
        traps.add(reserveInt());
      }
      case LOCAL_DIV, LOCAL_MOD -> division(opcode);
      case LOCAL_AND -> bytes(0x48, 0x21, 0xc8);
      case LOCAL_XOR -> bytes(0x48, 0x31, 0xc8);
      case LOCAL_ROTR32 -> bytes(0xd3, 0xc8);
      default -> throw new IllegalStateException("Validated scalar AOT arithmetic changed");
    }
  }

  void loopCheck(ArrayList<Integer> traps) {
    bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    traps.add(reserveInt());
    bytes(0x48, 0x85, 0xc9, 0x0f, 0x88);
    traps.add(reserveInt());
    bytes(0x48, 0x81, 0xf9);
    integer(ScalarAotProgram.MAX_LOOP_ITERATIONS);
    bytes(0x0f, 0x8f);
    traps.add(reserveInt());
    bytes(0x48, 0x39, 0xc8, 0x0f, 0x8d);
    traps.add(reserveInt());
    bytes(0x48, 0x83, 0xc0, 0x01, 0x0f, 0x80);
    traps.add(reserveInt());
  }

  void comparison(Opcode opcode) {
    bytes(0x48, 0x39, 0xc8);
    if (opcode == Opcode.LOCAL_EQ) {
      bytes(0x0f, 0x94, 0xc0);
    } else if (opcode == Opcode.LOCAL_LT) {
      bytes(0x0f, 0x9c, 0xc0);
    } else {
      throw new IllegalStateException("Validated scalar AOT comparison changed");
    }
    bytes(0x48, 0x0f, 0xb6, 0xc0);
  }

  void division(Opcode opcode) {
    bytes(0x48, 0x99, 0x48, 0xf7, 0xf9);
    if (opcode == Opcode.LOCAL_MOD) {
      bytes(0x48, 0x89, 0xd0);
    }
  }

  void patchRelativeInt(int displacementOffset, int target) {
    relativePatches.add(new RelativePatch(displacementOffset, target));
  }

  byte[] finish() {
    byte[] result = output.toByteArray();
    ByteBuffer buffer = ByteBuffer.wrap(result).order(ByteOrder.LITTLE_ENDIAN);
    for (RelativePatch patch : relativePatches) {
      buffer.putInt(
          patch.displacement(),
          patch.target() - patch.displacement() - Integer.BYTES);
    }
    return result;
  }

  record IoLayout(
      int inputLengthSlot,
      int outputLengthSlot,
      int inputOffset,
      int outputOffset,
      int frameBytes) {
    static IoLayout create(int fuelSlot) {
      int inputLengthSlot = fuelSlot + 1;
      int outputLengthSlot = fuelSlot + 2;
      int inputOffset = ScalarAotX86.frameBytes(fuelSlot + 3);
      int outputOffset = inputOffset + ScalarAotProgram.MAX_INPUT_BYTES;
      int frameBytes = alignBytes(outputOffset + ScalarAotProgram.MAX_OUTPUT_BYTES);
      return new IoLayout(
          inputLengthSlot, outputLengthSlot, inputOffset, outputOffset, frameBytes);
    }

    int inputDataOffset() {
      return inputOffset - inputLengthSlot * Long.BYTES;
    }

    int outputDataOffset() {
      return outputOffset - outputLengthSlot * Long.BYTES;
    }
  }

  private static int frameBytes(int slots) {
    return alignBytes(Math.multiplyExact(slots, Long.BYTES));
  }

  private static int alignBytes(int bytes) {
    return Math.addExact(bytes, 15) & -16;
  }

  private record RelativePatch(int displacement, int target) {}
}
