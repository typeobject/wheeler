package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.EnumSet;
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

    assertOperandFailure(badGlobal, Opcode.ADD_CONST, "global");
    assertOperandFailure(badFunction, Opcode.CALL, "function");
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
    assertOperandFailure(programWith(badJump), Opcode.JUMP, "target");
  }

  @Test
  void rejectsRegisterTypeMismatchesAndInvalidScalarConstants() {
    FunctionBody signedCondition = typedMain(
        List.of(ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 0, 2),
            Instruction.of(Opcode.HALT)));
    FunctionBody signedAssertion = typedMain(
        List.of(ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.EXPECT_TRUE, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody uninitializedAssertion = typedMain(
        List.of(ValueType.BOOLEAN),
        List.of(
            Instruction.of(Opcode.EXPECT_TRUE, 0),
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
    FunctionBody invalidDone = typedMain(
        List.of(ValueType.DONE),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.HALT)));
    FunctionBody doneXor = typedMain(
        List.of(ValueType.DONE, ValueType.DONE, ValueType.DONE),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.LOCAL_CONST, 1, 0),
            Instruction.of(Opcode.LOCAL_XOR, 2, 0, 1),
            Instruction.of(Opcode.HALT)));
    FunctionBody unresolvedRecord = typedMain(
        List.of(ValueType.record(7)),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.HALT)));

    assertEquals(ValueType.DONE, ValueType.fromCode(ValueType.DONE.code()));
    assertEquals(ValueType.record(7), ValueType.fromCode(ValueType.record(7).code()));
    assertOperandFailure(programWith(signedCondition), Opcode.JUMP_IF_ZERO, "condition");
    assertOperandFailure(programWith(signedAssertion), Opcode.EXPECT_TRUE, "condition");
    assertThrows(
        BytecodeException.class, () -> BytecodeVerifier.verify(programWith(uninitializedAssertion)));
    assertOperandFailure(programWith(booleanStore), Opcode.LOCAL_STORE_GLOBAL, "source");
    assertOperandFailure(programWith(invalidBoolean), Opcode.LOCAL_CONST, "immediate");
    assertOperandFailure(programWith(invalidDone), Opcode.LOCAL_CONST, "immediate");
    assertOperandFailure(programWith(doneXor), Opcode.LOCAL_XOR, "destination");
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(unresolvedRecord)));
  }

  @Test
  void recordDescriptorsAllowForwardReferencesAndRejectUnknownReferences() {
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

    assertDoesNotThrow(() -> BytecodeVerifier.verify(invalid));

    RecordType unknown = new RecordType(
        0,
        "Unknown",
        List.of(new RecordType.Field("missing", ValueType.record(2))));
    Program unknownReference = Program.classical(
        "UnknownRecord", 0, List.of(), List.of(unknown, later),
        List.of(), List.of(), List.of(), List.of(main), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(unknownReference));

    RecordType arrayRecord = new RecordType(
        0,
        "ArrayRecord",
        List.of(new RecordType.Field("values", ValueType.array(0))));
    ArrayType scalarArray = new ArrayType(0, ValueType.SIGNED, 2);
    Program validArrayRecord = Program.classical(
        "ValidArrayRecord", 0, List.of(), List.of(arrayRecord),
        List.of(), List.of(scalarArray), List.of(), List.of(main), List.of());
    assertDoesNotThrow(() -> BytecodeVerifier.verify(validArrayRecord));

    ArrayType recursiveArray = new ArrayType(0, ValueType.record(0), 2);
    Program invalidArrayRecord = Program.classical(
        "InvalidArrayRecord", 0, List.of(), List.of(arrayRecord),
        List.of(), List.of(recursiveArray), List.of(), List.of(main), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(invalidArrayRecord));

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
    assertOperandFailure(malformed, Opcode.RECORD_NEW, "element_count");

    VariantType selection = new VariantType(
        0, "Selection", List.of(new VariantType.Case("Missing", List.of())));
    FunctionBody badTag = typedMain(
        List.of(ValueType.variant(0)),
        List.of(
            Instruction.of(Opcode.VARIANT_NEW, 0, 0, 1, 0, 0),
            Instruction.of(Opcode.HALT)));
    Program malformedVariant = Program.classical(
        "MalformedVariant", 0, List.of(), List.of(), List.of(selection),
        List.of(), List.of(), List.of(badTag), List.of());
    assertOperandFailure(malformedVariant, Opcode.VARIANT_NEW, "tag");
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
    assertOperandFailure(malformedArray, Opcode.ARRAY_NEW, "element_count");
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
    assertOperandFailure(programWith(wrongBufferKind), Opcode.WORDS_GET, "owner");
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
  void acceptsOwnedResultsAndRejectsBorrowedResults() {
    FunctionBody make = new FunctionBody(
        0,
        "make",
        false,
        2,
        List.of(ValueType.REGION_BORROW, ValueType.SIGNED, ValueType.WORDS),
        ValueType.WORDS,
        List.of(
            Instruction.of(Opcode.WORDS_ALLOC, 2, 0, 1),
            Instruction.of(Opcode.RETURN_VALUE, 2)),
        List.of());
    FunctionBody relay = new FunctionBody(
        1,
        "relay",
        false,
        1,
        List.of(ValueType.WORDS),
        ValueType.WORDS,
        List.of(Instruction.of(Opcode.RETURN_VALUE, 0)),
        List.of());
    FunctionBody main = new FunctionBody(
        2,
        "main",
        false,
        0,
        List.of(
            ValueType.REGION,
            ValueType.SIGNED,
            ValueType.REGION_BORROW,
            ValueType.SIGNED,
            ValueType.WORDS,
            ValueType.WORDS,
            ValueType.WORDS),
        null,
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 8, 1),
            Instruction.of(Opcode.LOCAL_CONST, 1, 1),
            Instruction.of(Opcode.REGION_BORROW, 2, 0),
            Instruction.of(Opcode.LOCAL_MOVE, 3, 1),
            Instruction.of(Opcode.CALL_VALUE, 0, 2, 2, 4),
            Instruction.of(Opcode.OWNED_MOVE, 5, 4),
            Instruction.of(Opcode.CALL_VALUE, 1, 5, 1, 6),
            Instruction.of(Opcode.BUFFER_DROP, 6),
            Instruction.of(Opcode.REGION_DROP, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program valid = Program.classical(
        "OwnedResult", 2, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(make, relay, main), List.of());

    BytecodeVerifier.verify(valid);
    byte[] encoded = new BytecodeWriter().write(valid);
    Program decoded = new BytecodeReader().read(encoded);
    assertEquals(ValueType.WORDS, decoded.function(0).resultType());
    assertArrayEquals(encoded, new BytecodeWriter().write(decoded));

    FunctionBody borrowed = new FunctionBody(
        0,
        "borrowed",
        false,
        1,
        List.of(ValueType.REGION_BORROW),
        ValueType.REGION_BORROW,
        List.of(Instruction.of(Opcode.RETURN_VALUE, 0)),
        List.of());
    Program invalid = Program.classical(
        "BorrowedResult", 2, List.of(), List.of(), List.of(), List.of(), List.of(),
        List.of(borrowed, relay, main), List.of());
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(invalid));
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
  void rejectsReferenceWindowAndLimitOperandsWithTheirRegistryRoles() {
    RecordType scalar = new RecordType(
        0, "Scalar", List.of(new RecordType.Field("value", ValueType.SIGNED)));
    FunctionBody badDescriptor = typedMain(
        List.of(ValueType.record(0)),
        List.of(
            Instruction.of(Opcode.RECORD_NEW, 0, 9, 0, 0),
            Instruction.of(Opcode.HALT)));
    Program descriptorProgram = Program.classical(
        "BadDescriptor", 0, List.of(), List.of(scalar), List.of(), List.of(), List.of(),
        List.of(badDescriptor), List.of());
    assertOperandFailure(descriptorProgram, Opcode.RECORD_NEW, "descriptor");

    FunctionBody badElementBase = typedMain(
        List.of(ValueType.record(0), ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.RECORD_NEW, 0, 0, 2, 1),
            Instruction.of(Opcode.HALT)));
    Program elementBaseProgram = Program.classical(
        "BadElementBase", 0, List.of(), List.of(scalar), List.of(), List.of(), List.of(),
        List.of(badElementBase), List.of());
    assertOperandFailure(elementBaseProgram, Opcode.RECORD_NEW, "element_base");

    FunctionBody badIndex = typedMain(
        List.of(ValueType.SIGNED, ValueType.record(0), ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.RECORD_NEW, 1, 0, 0, 1),
            Instruction.of(Opcode.RECORD_GET, 2, 1, 1),
            Instruction.of(Opcode.HALT)));
    Program indexProgram = Program.classical(
        "BadIndex", 0, List.of(), List.of(scalar), List.of(), List.of(), List.of(),
        List.of(badIndex), List.of());
    assertOperandFailure(indexProgram, Opcode.RECORD_GET, "index");

    FunctionBody parameterTarget = new FunctionBody(
        0, "consume", false, 1, List.of(ValueType.SIGNED), null,
        List.of(Instruction.of(Opcode.RETURN)), List.of());
    FunctionBody badCountMain = new FunctionBody(
        1, "main", false, 0, List.of(), null,
        List.of(
            Instruction.of(Opcode.CALL_VOID, 0, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program countProgram = new Program(
        "BadArgumentCount", 1, List.of(), List.of(parameterTarget, badCountMain));
    assertOperandFailure(countProgram, Opcode.CALL_VOID, "argument_count");

    FunctionBody voidTarget = new FunctionBody(
        0, "consume", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.RETURN)), List.of());
    FunctionBody badBaseMain = new FunctionBody(
        1, "main", false, 0, List.of(), null,
        List.of(
            Instruction.of(Opcode.CALL_VOID, 0, 1, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program baseProgram = new Program(
        "BadArgumentBase", 1, List.of(), List.of(voidTarget, badBaseMain));
    assertOperandFailure(baseProgram, Opcode.CALL_VOID, "argument_base");

    FunctionBody valueTarget = new FunctionBody(
        0, "value", false, 0, List.of(ValueType.SIGNED), ValueType.SIGNED,
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.RETURN_VALUE, 0)),
        List.of());
    FunctionBody badResultMain = new FunctionBody(
        1, "main", false, 0, List.of(ValueType.BOOLEAN), null,
        List.of(
            Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    Program resultProgram = new Program(
        "BadResult", 1, List.of(), List.of(valueTarget, badResultMain));
    assertOperandFailure(resultProgram, Opcode.CALL_VALUE, "result");

    FunctionBody badCapacity = typedMain(
        List.of(ValueType.REGION),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 0, 1),
            Instruction.of(Opcode.HALT)));
    assertOperandFailure(programWith(badCapacity), Opcode.REGION_NEW, "capacity");

    FunctionBody badAllocationLimit = typedMain(
        List.of(ValueType.REGION),
        List.of(
            Instruction.of(Opcode.REGION_NEW, 0, 1, 0),
            Instruction.of(Opcode.HALT)));
    assertOperandFailure(
        programWith(badAllocationLimit), Opcode.REGION_NEW, "allocation_limit");
  }

  @Test
  void everyRegisteredOperandRoleHasTheCanonicalDiagnosticLabel() {
    FunctionBody owner = typedMain(List.of(), List.of(Instruction.of(Opcode.HALT)));
    EnumSet<InstructionForm.OperandRole> covered =
        EnumSet.noneOf(InstructionForm.OperandRole.class);
    for (Opcode opcode : Opcode.values()) {
      Instruction instruction = Instruction.of(opcode, new long[opcode.operandCount()]);
      for (InstructionForm.OperandRole role : opcode.form().roles()) {
        BytecodeException error = assertThrows(
            BytecodeException.class,
            () -> InstructionOperandVerifier.failOperand(
                owner, instruction, role, 0, "test rejection"));
        assertTrue(
            error.getMessage().contains(opcode.name() + " " + role.label() + " "),
            error.getMessage());
        covered.add(role);
      }
    }
    assertEquals(EnumSet.allOf(InstructionForm.OperandRole.class), covered);
  }

  @Test
  void everyGeneratedInversePairIsSymmetric() {
    for (Opcode opcode : Opcode.values()) {
      if (opcode.supportsGeneratedInverse()) {
        assertEquals(opcode, opcode.inverse().inverse(), opcode.name());
      }
    }
  }

  private static void assertOperandFailure(
      Program program, Opcode opcode, String role) {
    BytecodeException error = assertThrows(
        BytecodeException.class, () -> BytecodeVerifier.verify(program));
    assertTrue(error.getMessage().contains(opcode.name() + " " + role + " "),
        error.getMessage());
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
