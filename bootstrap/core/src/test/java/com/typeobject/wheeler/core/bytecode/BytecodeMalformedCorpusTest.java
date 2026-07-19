package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.ProgramFixtures;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import org.junit.jupiter.api.Test;

/** Deterministic structural mutation corpus for every container boundary. */
class BytecodeMalformedCorpusTest {
  private final BytecodeReader reader = new BytecodeReader();
  private final byte[] valid = new BytecodeWriter().write(ProgramFixtures.counter());

  @Test
  void rejectsEveryTruncatedPrefixWithOneCheckedFailureType() {
    for (int length = 0; length < valid.length; length++) {
      byte[] truncated = Arrays.copyOf(valid, length);
      assertThrows(BytecodeException.class, () -> reader.read(truncated), "length " + length);
    }
  }

  @Test
  void rejectsHeaderVersionAndDirectoryArithmeticMutations() {
    byte[] version = copy();
    buffer(version).putShort(8, (short) 2);
    reject(version);

    byte[] directoryOverflow = copy();
    buffer(directoryOverflow).putLong(32, Long.MAX_VALUE);
    reject(directoryOverflow);

    byte[] overlap = copy();
    buffer(overlap).putLong(directoryEntry(overlap, 0) + 8, 0);
    reject(overlap);

    byte[] badAlignment = copy();
    buffer(badAlignment).putInt(directoryEntry(badAlignment, 0) + 24, 4);
    reject(badAlignment);

    byte[] unknownFlags = copy();
    buffer(unknownFlags).putInt(directoryEntry(unknownFlags, 0) + 4, 2);
    reject(unknownFlags);

    byte[] reserved = copy();
    buffer(reserved).putInt(directoryEntry(reserved, 0) + 28, 1);
    reject(reserved);

    byte[] duplicateSection = copy();
    ByteBuffer duplicate = buffer(duplicateSection);
    duplicate.putInt(directoryEntry(duplicateSection, 1),
        duplicate.getInt(directoryEntry(duplicateSection, 0)));
    reject(duplicateSection);
  }

  @Test
  void rejectsInvalidUtf8UnknownOpcodesAndOversizedArtifacts() {
    byte[] utf8 = copy();
    int strings = sectionOffset(utf8, BytecodeFormat.STRINGS);
    int firstLength = buffer(utf8).getInt(strings + 4);
    if (firstLength <= 0) {
      throw new AssertionError("fixture has no string payload");
    }
    utf8[strings + 8] = (byte) 0xc0;
    reject(utf8);

    byte[] opcode = copy();
    int code = sectionOffset(opcode, BytecodeFormat.CODE);
    buffer(opcode).putShort(code, (short) 0xffff);
    reject(opcode);

    assertThrows(
        BytecodeException.class,
        () -> reader.read(new byte[BytecodeFormat.MAX_ARTIFACT_BYTES + 1]));
  }

  private byte[] copy() {
    return valid.clone();
  }

  private void reject(byte[] artifact) {
    assertThrows(BytecodeException.class, () -> reader.read(artifact));
  }

  private static ByteBuffer buffer(byte[] bytes) {
    return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static int directoryEntry(byte[] bytes, int index) {
    return Math.toIntExact(buffer(bytes).getLong(32))
        + index * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
  }

  private static int sectionOffset(byte[] bytes, int sectionType) {
    ByteBuffer input = buffer(bytes);
    int count = input.getInt(24);
    for (int index = 0; index < count; index++) {
      int entry = directoryEntry(bytes, index);
      if (input.getInt(entry) == sectionType) {
        return Math.toIntExact(input.getLong(entry + 8));
      }
    }
    throw new AssertionError("missing section " + sectionType);
  }
}
