package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for structural, typed, control-flow, storage, and proof verification. */
class BytecodeVerifierTest {
  @Test
  void rejectsOutOfRangeGlobalAndFunctionReferences() {
    Program badGlobal = programWith(Instruction.of(Opcode.ADD_CONST, 9, 1));
    Program badFunction = programWith(Instruction.of(Opcode.CALL, 9));
    FunctionBody signedEntry = new FunctionBody(
        0,
        "main",
        false,
        1,
        List.of(ValueType.SIGNED),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    Program badEntry = programWith(signedEntry);

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(badGlobal));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(badFunction));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(badEntry));
  }

  @Test
  void rejectsUninitializedLocalsAndInvalidControlTargets() {
    FunctionBody uninitialized = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody badJump = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.JUMP, 7), Instruction.of(Opcode.HALT)),
        List.of());

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(uninitialized)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(badJump)));
  }

  @Test
  void rejectsRegisterTypeMismatchesAndInvalidBooleanConstants() {
    FunctionBody signedCondition = typedMain(
        List.of(ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 0, 2),
            Instruction.of(Opcode.HALT)));
    FunctionBody booleanStore = typedMain(
        List.of(ValueType.BOOLEAN),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody invalidBoolean = typedMain(
        List.of(ValueType.BOOLEAN),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 2),
            Instruction.of(Opcode.HALT)));
    FunctionBody unresolvedRecord = typedMain(
        List.of(ValueType.record(7)),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.HALT)));

    assertEquals(ValueType.record(7), ValueType.fromCode(ValueType.record(7).code()));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(signedCondition)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(booleanStore)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(invalidBoolean)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(unresolvedRecord)));
  }

  @Test
  void recordDescriptorsRejectForwardAndUnknownReferences() {
    RecordType forward = new RecordType(
        0,
        "Forward",
        List.of(new RecordType.Field("next", ValueType.record(1))));
    RecordType later = new RecordType(
        1,
        "Later",
        List.of(new RecordType.Field("value", ValueType.SIGNED)));
    FunctionBody main = typedMain(List.of(), List.of(Instruction.of(Opcode.HALT)));
    Program invalid = Program.classical(
        "InvalidRecords", 0, List.of(), List.of(forward, later),
        List.of(), List.of(), List.of(), List.of(main), List.of());

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(invalid));

    RecordType pair = new RecordType(
        0,
        "Pair",
        List.of(
            new RecordType.Field("value", ValueType.SIGNED),
            new RecordType.Field("valid", ValueType.BOOLEAN)));
    FunctionBody badConstruction = typedMain(
        List.of(ValueType.SIGNED, ValueType.BOOLEAN, ValueType.record(0)),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.RECORD_NEW, 2, 0, 0, 1),
            Instruction.of(Opcode.HALT)));
    Program malformed = Program.classical(
        "MalformedRecord", 0, List.of(), List.of(pair),
        List.of(), List.of(), List.of(), List.of(badConstruction), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(malformed));

    VariantType option = new VariantType(
        0, "Option", List.of(new VariantType.Case("None", List.of())));
    FunctionBody badTag = typedMain(
        List.of(ValueType.variant(0)),
        List.of(
            Instruction.of(Opcode.VARIANT_NEW, 0, 0, 1, 0, 0),
            Instruction.of(Opcode.HALT)));
    Program malformedVariant = Program.classical(
        "MalformedVariant", 0, List.of(), List.of(), List.of(option),
        List.of(), List.of(), List.of(badTag), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(malformedVariant));
    assertEquals(ValueType.variant(3), ValueType.fromCode(ValueType.variant(3).code()));

    ArrayType pairArray = new ArrayType(0, ValueType.SIGNED, 2);
    FunctionBody badArray = typedMain(
        List.of(ValueType.SIGNED, ValueType.array(0)),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.ARRAY_NEW, 1, 0, 0, 1),
            Instruction.of(Opcode.HALT)));
    Program malformedArray = Program.classical(
        "MalformedArray", 0, List.of(), List.of(), List.of(),
        List.of(pairArray), List.of(), List.of(badArray), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(malformedArray));
    assertEquals(ValueType.array(4), ValueType.fromCode(ValueType.array(4).code()));

    SliceType signedSlice = new SliceType(0, ValueType.SIGNED);
    FunctionBody escapingSlice = new FunctionBody(
        0,
        "main",
        false,
        1,
        List.of(ValueType.slice(0)),
        ValueType.slice(0),
        List.of(Instruction.of(Opcode.RETURN_VALUE, 0)),
        List.of());
    Program malformedSlice = Program.classical(
        "MalformedSlice", 0, List.of(), List.of(), List.of(), List.of(),
        List.of(signedSlice), List.of(escapingSlice), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(malformedSlice));
    assertEquals(ValueType.slice(5), ValueType.fromCode(ValueType.slice(5).code()));
  }

  @Test
  void rejectsOwnedCopiesUseAfterMoveLeaksAndDivergentDrops() {
    FunctionBody copied = typedMain(
        List.of(ValueType.REGION, ValueType.REGION),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.LOCAL_MOVE, 1, 0),
            Instruction.of(Opcode.REGION_DROP, 1),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody movedTwice = typedMain(
        List.of(ValueType.REGION, ValueType.REGION),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.OWNED_MOVE, 1, 0),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.REGION_DROP, 1),
            Instruction.of(Opcode.HALT)));
    FunctionBody leaked = typedMain(
        List.of(ValueType.REGION),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.HALT)));
    FunctionBody wrongBufferKind = typedMain(
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.BYTES,
            ValueType.SIGNED,
            ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.BYTES_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.LOCAL_CONST, 3, 0),
            Instruction.of(Opcode.WORDS_GET, 4, 2, 3),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody strayBorrow = typedMain(
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.BYTES,
            ValueType.UTF8,
            ValueType.UTF8_BORROW),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 1, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.BYTES_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.UTF8_FREEZE, 3, 2),
            Instruction.of(Opcode.UTF8_BORROW, 4, 3),
            Instruction.of(Opcode.BUFFER_DROP, 3),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody divergent = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.BOOLEAN, ValueType.REGION),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.REGION_NEW, 1, 8, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 0, 5),
            Instruction.of(Opcode.REGION_DROP, 1),
            Instruction.of(Opcode.JUMP, 6),
            Instruction.of(Opcode.NOP),
            Instruction.of(Opcode.HALT)),
        List.of());

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(copied)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(movedTwice)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(leaked)));
    assertThrows(
        BytecodeException.class, () -> BytecodeVerifier.verify(programWith(wrongBufferKind)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(strayBorrow)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(divergent)));
    assertEquals(ValueType.REGION, ValueType.fromCode(ValueType.REGION.code()));
    assertEquals(ValueType.WORDS, ValueType.fromCode(ValueType.WORDS.code()));
    assertEquals(ValueType.BYTES, ValueType.fromCode(ValueType.BYTES.code()));
    assertEquals(ValueType.LONG_MAP, ValueType.fromCode(ValueType.LONG_MAP.code()));
    assertEquals(ValueType.UTF8, ValueType.fromCode(ValueType.UTF8.code()));
    assertEquals(
        ValueType.UTF8_BORROW, ValueType.fromCode(ValueType.UTF8_BORROW.code()));
    assertEquals(
        ValueType.LONG_MAP_BORROW,
        ValueType.fromCode(ValueType.LONG_MAP_BORROW.code()));
    assertEquals(
        ValueType.WORDS_BORROW, ValueType.fromCode(ValueType.WORDS_BORROW.code()));
    assertEquals(
        ValueType.BYTES_BORROW, ValueType.fromCode(ValueType.BYTES_BORROW.code()));
    assertEquals(
        ValueType.REGION_BORROW, ValueType.fromCode(ValueType.REGION_BORROW.code()));
  }

  @Test
  void rejectsAliasedMutableMapBorrowWindows() {
    FunctionBody read = new FunctionBody(
        0,
        "read",
        false,
        2,
        List.of(
            ValueType.LONG_MAP_BORROW,
            ValueType.LONG_MAP_BORROW,
            ValueType.SIGNED,
            ValueType.SIGNED),
        ValueType.SIGNED,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 2, 0),
            Instruction.of(Opcode.MAP_GET, 3, 0, 2),
            Instruction.of(Opcode.RETURN_VALUE, 3)),
        List.of());
    FunctionBody main = new FunctionBody(
        1,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.LONG_MAP,
            ValueType.LONG_MAP_BORROW,
            ValueType.LONG_MAP_BORROW,
            ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 24, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.MAP_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.MAP_BORROW, 3, 2),
            Instruction.of(Opcode.MAP_BORROW, 4, 2),
            Instruction.of(Opcode.CALL_VALUE, 0, 3, 2, 5),
            Instruction.of(Opcode.BUFFER_DROP, 2),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program program = Program.classical(
        "AliasedBorrow", 1, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(read, main), List.of());

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(program));
  }

  @Test
  void everyGeneratedInversePairIsSymmetric() {
    for (Opcode opcode : Opcode.values()) {
      if (opcode.supportsGeneratedInverse()) {
        assertEquals(opcode, opcode.inverse().inverse(), opcode.name());
      }
    }
  }

  private static FunctionBody typedMain(
      List<ValueType> types, List<Instruction> instructions) {
    return new FunctionBody(0, "main", false, 0, types, null, instructions, List.of());
  }

  private static Program programWith(Instruction instruction) {
    return programWith(new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(instruction, Instruction.of(Opcode.HALT)),
        List.of()));
  }

  private static Program programWith(FunctionBody function) {
    return new Program(
        "Invalid", 0, List.of(new Global("value", 0)), List.of(function));
  }
}
