package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.ElfImage;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/** Minimal x86-64 Linux entry shim for mapped canonical ELF capsules. */
public final class LinuxX8664EntryShim {
  public static final int SUCCESS_STATUS = 42;
  public static final int MALFORMED_IMAGE_STATUS = 125;
  private static final int PAGE_BYTES = 4096;
  private static final byte[] SUCCESS_OUTPUT = "Wheeler\n".getBytes(StandardCharsets.US_ASCII);
  private static final byte[] RUNTIME_TEXT = assemble(SUCCESS_STATUS);
  private static final String RUNTIME_IDENTITY = identity(RUNTIME_TEXT);

  private LinuxX8664EntryShim() {}

  /** Position-independent runtime text with no relocations or external imports. */
  public static byte[] runtimeText() {
    return RUNTIME_TEXT.clone();
  }

  static byte[] runtimeText(int successStatus) {
    if (successStatus < 0 || successStatus >= MALFORMED_IMAGE_STATUS) {
      throw new IllegalArgumentException("Native success status must be between 0 and 124");
    }
    return assemble(successStatus);
  }

  /** SHA-256 identity of the exact runtime text. */
  public static String runtimeIdentity() {
    return RUNTIME_IDENTITY;
  }

  /** Exact successful standard-output bytes. */
  public static byte[] successOutput() {
    return SUCCESS_OUTPUT.clone();
  }

  private static byte[] assemble(int successStatus) {
    Code code = new Code();
    code.bytes(0x48, 0x8d, 0x1d);
    int locatorDisplacement = code.reserveInt();
    code.bytes(0x48, 0xb9);
    code.word(magicWord(ElfImage.locatorMagic()));
    code.bytes(0x48, 0x39, 0x0b, 0x75);
    int badLocatorJump = code.reserveByte();

    code.bytes(0x8b, 0x43, ElfImage.LOCATOR_CAPSULE_OFFSET_FIELD, 0x3d);
    int capsuleOffsetValue = code.reserveInt();
    code.bytes(0x75);
    int badCapsuleOffsetJump = code.reserveByte();
    code.bytes(0x48, 0x8d, 0x8b);
    code.integer(-ElfImage.LOCATOR_FILE_OFFSET);
    code.bytes(0x48, 0x01, 0xc8, 0x48, 0xb9);
    code.word(magicWord(ApplicationCapsule.framingMagic()));
    code.bytes(0x48, 0x39, 0x08, 0x75);
    int badCapsuleJump = code.reserveByte();

    code.bytes(0x48, 0x8d, 0x35);
    int outputDisplacement = code.reserveInt();
    code.bytes(0xbf);
    code.integer(1);
    code.bytes(0xba);
    code.integer(SUCCESS_OUTPUT.length);
    code.bytes(0xb8);
    code.integer(1);
    code.bytes(0x0f, 0x05, 0x83, 0xf8, SUCCESS_OUTPUT.length, 0x75);
    int shortWriteJump = code.reserveByte();
    code.bytes(0xbf);
    code.integer(successStatus);
    code.bytes(0xeb);
    int exitJump = code.reserveByte();

    int failure = code.position();
    code.bytes(0xbf);
    code.integer(MALFORMED_IMAGE_STATUS);
    int exit = code.position();
    code.bytes(0xb8);
    code.integer(60);
    code.bytes(0x0f, 0x05);
    int output = code.position();
    code.raw(SUCCESS_OUTPUT);

    code.patchRelativeInt(
        locatorDisplacement,
        ElfImage.LOCATOR_FILE_OFFSET - ElfImage.RUNTIME_FILE_OFFSET);
    code.patchInt(
        capsuleOffsetValue,
        align(ElfImage.RUNTIME_FILE_OFFSET + code.position(), PAGE_BYTES));
    code.patchRelativeInt(outputDisplacement, output);
    code.patchRelativeByte(badLocatorJump, failure);
    code.patchRelativeByte(badCapsuleOffsetJump, failure);
    code.patchRelativeByte(badCapsuleJump, failure);
    code.patchRelativeByte(shortWriteJump, failure);
    code.patchRelativeByte(exitJump, exit);
    return code.finish();
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static int align(int value, int alignment) {
    return Math.addExact(value, alignment - 1) & -alignment;
  }

  private static long magicWord(byte[] magic) {
    if (magic.length != Long.BYTES) {
      throw new IllegalStateException("Native framing magic must occupy eight bytes");
    }
    return ByteBuffer.wrap(magic).order(ByteOrder.LITTLE_ENDIAN).getLong();
  }

  private static final class Code {
    private final ByteArrayOutputStream output = new ByteArrayOutputStream(128);
    private byte[] finished;

    int position() {
      return output.size();
    }

    void bytes(int... values) {
      for (int value : values) {
        output.write(value);
      }
    }

    void raw(byte[] values) {
      output.writeBytes(values);
    }

    int reserveByte() {
      int offset = position();
      output.write(0);
      return offset;
    }

    int reserveInt() {
      int offset = position();
      integer(0);
      return offset;
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

    void patchInt(int offset, int value) {
      requireFinished();
      ByteBuffer.wrap(finished).order(ByteOrder.LITTLE_ENDIAN).putInt(offset, value);
    }

    void patchRelativeByte(int displacementOffset, int target) {
      requireFinished();
      int displacement = target - displacementOffset - Byte.BYTES;
      if (displacement < Byte.MIN_VALUE || displacement > Byte.MAX_VALUE) {
        throw new IllegalStateException("x86-64 short branch is out of range");
      }
      finished[displacementOffset] = (byte) displacement;
    }

    void patchRelativeInt(int displacementOffset, int target) {
      requireFinished();
      int displacement = target - displacementOffset - Integer.BYTES;
      ByteBuffer.wrap(finished)
          .order(ByteOrder.LITTLE_ENDIAN)
          .putInt(displacementOffset, displacement);
    }

    byte[] finish() {
      requireFinished();
      return finished;
    }

    private void requireFinished() {
      if (finished == null) {
        finished = output.toByteArray();
      }
    }
  }
}
