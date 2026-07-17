package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.ProgramFixtures;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Random;
import org.junit.jupiter.api.Test;

class BytecodeCodecTest {
  private final BytecodeWriter writer = new BytecodeWriter();
  private final BytecodeReader reader = new BytecodeReader();

  @Test
  void canonicalRoundTripIsByteIdentical() {
    byte[] first = writer.write(ProgramFixtures.counter());
    byte[] second = writer.write(reader.read(first));

    assertArrayEquals(first, second);
    assertArrayEquals(BytecodeFormat.MAGIC, Arrays.copyOf(first, BytecodeFormat.MAGIC.length));
    assertEquals(first.length, ByteBuffer.wrap(first).order(ByteOrder.LITTLE_ENDIAN).getLong(16));
  }

  @Test
  void goldenArtifactLocksVersionOneEncoding() throws NoSuchAlgorithmException {
    byte[] artifact = writer.write(ProgramFixtures.counter());
    String digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(artifact));

    assertEquals(552, artifact.length);
    assertEquals("927fd446699b35213d56f357ce542afe624dc874ed57c32050bb7dc0f9456f04", digest);
  }

  @Test
  void disassemblyContainsBothDirections() {
    String text = new Disassembler().disassemble(reader.read(writer.write(ProgramFixtures.counter())));

    assertTrue(text.contains("function 1 increment reversible"));
    assertTrue(text.contains("ADD_CONST"));
    assertTrue(text.contains("SUB_CONST"));
  }

  @Test
  void malformedArtifactsAreRejected() {
    byte[] valid = writer.write(ProgramFixtures.counter());
    byte[] badMagic = valid.clone();
    badMagic[0] = 0;
    byte[] truncated = Arrays.copyOf(valid, valid.length - 1);
    byte[] wrongLength = valid.clone();
    ByteBuffer.wrap(wrongLength).order(ByteOrder.LITTLE_ENDIAN).putLong(16, valid.length + 8L);

    assertThrows(BytecodeException.class, () -> reader.read(badMagic));
    assertThrows(BytecodeException.class, () -> reader.read(truncated));
    assertThrows(BytecodeException.class, () -> reader.read(wrongLength));
  }

  @Test
  void mutatedArtifactsNeverEscapeAsUncheckedDecoderFailures() {
    byte[] valid = writer.write(ProgramFixtures.counter());
    Random random = new Random(11);
    for (int sample = 0; sample < 500; sample++) {
      byte[] mutation = valid.clone();
      int index = random.nextInt(mutation.length);
      mutation[index] ^= (byte) (1 + random.nextInt(255));
      try {
        reader.read(mutation);
      } catch (BytecodeException expected) {
        // A mutation may also remain a different valid artifact; all malformed cases use one error type.
      }
    }
  }
}
