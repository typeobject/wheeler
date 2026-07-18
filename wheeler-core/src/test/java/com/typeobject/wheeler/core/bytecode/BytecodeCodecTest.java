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
  void goldenArtifactLocksFirstFormatEncoding() throws NoSuchAlgorithmException {
    byte[] artifact = writer.write(ProgramFixtures.counter());
    String digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(artifact));

    assertEquals(616, artifact.length);
    assertEquals("40044d0e5eac740b8949dba248b0a84b854a868c5b5e311e6b22155d10341887", digest);
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
  void localTypeTableRoundTripsAndRejectsUnknownCodes() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        java.util.List.of(ValueType.BOOLEAN),
        null,
        java.util.List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.HALT)),
        java.util.List.of());
    byte[] artifact = writer.write(new Program("Typed", 0, java.util.List.of(), java.util.List.of(main)));
    Program decoded = reader.read(artifact);
    assertEquals(java.util.List.of(ValueType.BOOLEAN), decoded.function(0).localTypes());
    assertArrayEquals(artifact, writer.write(decoded));

    byte[] unknownType = artifact.clone();
    ByteBuffer bytes = ByteBuffer.wrap(unknownType).order(ByteOrder.LITTLE_ENDIAN);
    int sections = bytes.getInt(24);
    long directory = bytes.getLong(32);
    int functionOffset = -1;
    for (int index = 0; index < sections; index++) {
      int entry = Math.toIntExact(directory) + index * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
      if (bytes.getInt(entry) == BytecodeFormat.FUNCTIONS) {
        functionOffset = Math.toIntExact(bytes.getLong(entry + 8));
      }
    }
    unknownType[functionOffset + 4 + 40] = 99;
    byte[] conflictingResultTypes = artifact.clone();
    ByteBuffer.wrap(conflictingResultTypes).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(functionOffset + 4 + 8, 12);
    assertThrows(BytecodeException.class, () -> reader.read(unknownType));
    assertThrows(BytecodeException.class, () -> reader.read(conflictingResultTypes));
  }

  @Test
  void nominalAggregateDescriptorsRoundTripCanonically() {
    RecordType point = new RecordType(
        0,
        "Point",
        java.util.List.of(
            new RecordType.Field("x", ValueType.SIGNED),
            new RecordType.Field("visible", ValueType.BOOLEAN)));
    VariantType option = new VariantType(
        0,
        "Option",
        java.util.List.of(
            new VariantType.Case("None", java.util.List.of()),
            new VariantType.Case(
                "Some",
                java.util.List.of(new RecordType.Field("point", ValueType.record(0))))));
    ArrayType points = new ArrayType(0, ValueType.record(0), 2);
    SliceType pointSlice = new SliceType(0, ValueType.record(0));
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        java.util.List.of(),
        null,
        java.util.List.of(Instruction.of(Opcode.HALT)),
        java.util.List.of());
    Program source = new Program(
        "Records",
        ProgramKind.CLASSICAL,
        0,
        java.util.List.of(),
        java.util.List.of(point),
        java.util.List.of(option),
        java.util.List.of(points),
        java.util.List.of(pointSlice),
        java.util.List.of(main),
        java.util.List.of(),
        java.util.List.of(),
        java.util.List.of(),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);

    byte[] artifact = writer.write(source);
    Program decoded = reader.read(artifact);

    assertEquals(java.util.List.of(point), decoded.recordTypes());
    assertEquals(java.util.List.of(option), decoded.variantTypes());
    assertEquals(java.util.List.of(points), decoded.arrayTypes());
    assertEquals(java.util.List.of(pointSlice), decoded.sliceTypes());
    assertArrayEquals(artifact, writer.write(decoded));
    String disassembly = new Disassembler().disassemble(decoded);
    assertTrue(disassembly.contains("variant 0 Option None() Some(point:record#0)"));
    assertTrue(disassembly.contains("array 0 element=record#0 length=2"));
    assertTrue(disassembly.contains("slice 0 element=record#0"));
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
