package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.ProgramFixtures;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.proof.ProofRule;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Random;
import org.junit.jupiter.api.Test;

/** Conformance tests for canonical bytecode encoding, decoding, and disassembly. */
class BytecodeCodecTest {
  private static final String FUTURE_INSTRUCTION_EXTENSION = "wheeler.classical.future/1";
  private static final int EMPTY_EXTENSION_COUNT = 0;
  private static final int UNKNOWN_OPCODE = 0xffff;

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
    assertEquals("d2ee35cdae3f3641fc6f84f518df3d2ab6b374fc0d23c095ab846b6a54502f40", digest);
  }

  @Test
  void disassemblyContainsBothDirections() {
    String text = new Disassembler().disassemble(reader.read(writer.write(ProgramFixtures.counter())));

    assertTrue(text.contains("function 1 increment reversible"));
    assertTrue(text.contains("ADD_CONST    global=0, immediate=1"));
    assertTrue(text.contains("SUB_CONST    global=0, immediate=1"));
  }

  @Test
  void requiredInstructionExtensionsFailBeforeProgramConstruction() {
    Program base = ProgramFixtures.counter();
    Program future = withInstructionExtensions(
        base,
        java.util.List.of(FUTURE_INSTRUCTION_EXTENSION));

    byte[] artifact = writer.write(future);
    assertEquals(
        java.util.List.of(FUTURE_INSTRUCTION_EXTENSION),
        InstructionExtensionCodec.read(ByteBuffer.wrap(InstructionExtensionCodec.write(
            java.util.List.of(FUTURE_INSTRUCTION_EXTENSION)))));
    BytecodeException unsupported = assertThrows(
        BytecodeException.class,
        () -> reader.read(artifact));
    assertTrue(unsupported.getMessage().contains(FUTURE_INSTRUCTION_EXTENSION));

    byte[] unknownCode = artifact.clone();
    ByteBuffer.wrap(unknownCode)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putShort(sectionOffset(unknownCode, BytecodeFormat.CODE), (short) UNKNOWN_OPCODE);
    BytecodeException negotiationFirst = assertThrows(
        BytecodeException.class,
        () -> reader.read(unknownCode));
    assertTrue(negotiationFirst.getMessage().contains(FUTURE_INSTRUCTION_EXTENSION));

    assertThrows(
        BytecodeException.class,
        () -> new com.typeobject.wheeler.core.vm.VirtualMachine(future));

    byte[] emptyRequirements = artifact.clone();
    ByteBuffer.wrap(emptyRequirements)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(sectionOffset(emptyRequirements, BytecodeFormat.INSTRUCTION_EXTENSIONS),
            EMPTY_EXTENSION_COUNT);
    assertThrows(BytecodeException.class, () -> reader.read(emptyRequirements));

    Program unsorted = withInstructionExtensions(base, java.util.List.of("z/1", "a/1"));
    assertThrows(BytecodeException.class, () -> writer.write(unsorted));
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
    VariantType selection = new VariantType(
        0,
        "Selection",
        java.util.List.of(
            new VariantType.Case("Missing", java.util.List.of()),
            new VariantType.Case(
                "Found",
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
        java.util.List.of(selection),
        java.util.List.of(points),
        java.util.List.of(pointSlice),
        java.util.List.of(main),
        java.util.List.of(),
        java.util.List.of(),
        java.util.List.of(),
        java.util.List.of(),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);

    byte[] artifact = writer.write(source);
    Program decoded = reader.read(artifact);

    assertEquals(java.util.List.of(point), decoded.recordTypes());
    assertEquals(java.util.List.of(selection), decoded.variantTypes());
    assertEquals(java.util.List.of(points), decoded.arrayTypes());
    assertEquals(java.util.List.of(pointSlice), decoded.sliceTypes());
    assertArrayEquals(artifact, writer.write(decoded));
    String disassembly = new Disassembler().disassemble(decoded);
    assertTrue(disassembly.contains("variant 0 Selection Missing() Found(point:record#0)"));
    assertTrue(disassembly.contains("array 0 element=record#0 length=2"));
    assertTrue(disassembly.contains("slice 0 element=record#0"));
  }

  @Test
  void generatedInverseProofCertificatesRoundTripAndFailClosed() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        java.util.List.of(),
        null,
        java.util.List.of(
            Instruction.of(Opcode.CALL, 1),
            Instruction.of(Opcode.HALT)),
        java.util.List.of());
    FunctionBody increment = new FunctionBody(
        1,
        "increment",
        false,
        0,
        java.util.List.of(),
        null,
        java.util.List.of(
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.RETURN)),
        java.util.List.of(
            Instruction.of(Opcode.SUB_CONST, 0, 1),
            Instruction.of(Opcode.RETURN)));
    ProofCertificate proof = new ProofCertificate(
        0, "incrementInverse", ProofRule.GENERATED_INVERSE, 1, -1);
    Program valid = Program.classical(
        "Proof", 0, java.util.List.of(new Global("value", 0)),
        java.util.List.of(), java.util.List.of(), java.util.List.of(), java.util.List.of(),
        java.util.List.of(main, increment), java.util.List.of(proof));

    byte[] artifact = writer.write(valid);
    Program decoded = reader.read(artifact);

    assertEquals(java.util.List.of(proof), decoded.proofCertificates());
    assertArrayEquals(artifact, writer.write(decoded));
    assertTrue(new Disassembler().disassemble(decoded).contains(
        "proof 0 incrementInverse rule=GENERATED_INVERSE subject=1"));

    FunctionBody plain = new FunctionBody(
        0, "main", false, 0, java.util.List.of(), null,
        java.util.List.of(Instruction.of(Opcode.HALT)), java.util.List.of());
    Program forged = Program.classical(
        "Forged", 0, java.util.List.of(), java.util.List.of(), java.util.List.of(),
        java.util.List.of(), java.util.List.of(), java.util.List.of(plain),
        java.util.List.of(new ProofCertificate(
            0, "falseClaim", ProofRule.GENERATED_INVERSE, 0, -1)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(forged));

    assertThrows(IllegalArgumentException.class, () -> new ProofCertificate(
        0, "badArgument", ProofRule.GENERATED_INVERSE, 1, 0));
    Program wrongSubject = Program.classical(
        "WrongSubject", 0, java.util.List.of(new Global("value", 0)),
        java.util.List.of(), java.util.List.of(), java.util.List.of(), java.util.List.of(),
        java.util.List.of(main, increment), java.util.List.of(new ProofCertificate(
            0, "wrongSubject", ProofRule.GENERATED_INVERSE, 0, -1)));
    BytecodeException subjectFailure = assertThrows(
        BytecodeException.class, () -> BytecodeVerifier.verify(wrongSubject));
    assertTrue(subjectFailure.getMessage().contains("subject is not reversible"));
    FunctionBody forgedInverse = new FunctionBody(
        1,
        "increment",
        false,
        0,
        java.util.List.of(),
        null,
        increment.forward(),
        java.util.List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    Program wrongPayload = Program.classical(
        "WrongPayload", 0, java.util.List.of(new Global("value", 0)),
        java.util.List.of(), java.util.List.of(), java.util.List.of(), java.util.List.of(),
        java.util.List.of(main, forgedInverse), java.util.List.of(proof));
    BytecodeException payloadFailure = assertThrows(
        BytecodeException.class, () -> BytecodeVerifier.verify(wrongPayload));
    assertTrue(payloadFailure.getMessage().contains("inverse body does not match"));
  }

  private static int sectionOffset(byte[] artifact, int expectedType) {
    ByteBuffer input = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sectionCount = input.getInt(BytecodeFormat.HEADER_SECTION_COUNT_OFFSET);
    int directory = Math.toIntExact(input.getLong(BytecodeFormat.HEADER_DIRECTORY_OFFSET));
    for (int index = 0; index < sectionCount; index++) {
      int entry = directory + index * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
      if (input.getInt(entry) == expectedType) {
        return Math.toIntExact(input.getLong(entry + BytecodeFormat.DIRECTORY_SECTION_OFFSET));
      }
    }
    throw new AssertionError("Missing section " + expectedType);
  }

  private static Program withInstructionExtensions(
      Program program,
      java.util.List<String> extensions) {
    return new Program(
        program.name(),
        program.kind(),
        program.entryFunctionId(),
        program.globals(),
        program.recordTypes(),
        program.variantTypes(),
        program.arrayTypes(),
        program.sliceTypes(),
        program.functions(),
        program.proofCertificates(),
        program.quantumRegisters(),
        program.quantumCircuits(),
        program.workflow(),
        extensions,
        program.maxHistoryRecords(),
        program.maxSteps());
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
