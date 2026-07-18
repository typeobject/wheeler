package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.proof.ProofKernel;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Structural and semantic verification for decoded Wheeler programs. */
public final class BytecodeVerifier {
  private static final Set<Opcode> COHERENT_OPCODES = Set.of(
      Opcode.NOP, Opcode.XOR_CONST, Opcode.CALL, Opcode.UNCALL, Opcode.RETURN);

  private BytecodeVerifier() {}

  public static void verify(Program program) {
    verifyLimits(program);
    verifyGlobals(program);
    verifyRecordTypes(program);
    verifyVariantTypes(program);
    verifyArrayTypes(program);
    verifySliceTypes(program);
    verifyFunctions(program);
    verifyQuantum(program);
    verifyProofs(program);
    verifyWorkflow(program);

    FunctionBody entry = program.function(program.entryFunctionId());
    boolean validEntry = entry.parameterCount() == 0
        || (entry.parameterCount() == 1
            && (entry.localType(0).equals(ValueType.UTF8_BORROW)
                || entry.localType(0).equals(ValueType.BYTE_VIEW)
                || entry.localType(0).equals(ValueType.BYTES_BORROW)))
        || (entry.parameterCount() == 2
            && (entry.localType(0).equals(ValueType.UTF8_BORROW)
                || entry.localType(0).equals(ValueType.BYTE_VIEW))
            && entry.localType(1).equals(ValueType.BYTES_BORROW));
    if (entry.returnsValue() || !validEntry) {
      fail("Entry parameters must be optional UTF-8/byteview input then optional byte output");
    }
    if (entry.forward().stream().noneMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
      fail("Entry function must contain HALT");
    }
  }

  private static void verifyLimits(Program program) {
    if (program.name().isBlank()) {
      fail("Program name must not be blank");
    }
    if (program.maxHistoryRecords() <= 0 || program.maxHistoryRecords() > 10_000_000) {
      fail("Invalid history record limit");
    }
    if (program.maxSteps() <= 0 || program.maxSteps() > 1_000_000_000L) {
      fail("Invalid step limit");
    }
    if (program.globals().size() > 65_535
        || program.recordTypes().size() > 65_535
        || program.variantTypes().size() > 65_535
        || program.arrayTypes().size() > 65_535
        || program.sliceTypes().size() > 65_535
        || program.functions().size() > 65_535
        || program.proofCertificates().size() > 65_535
        || program.quantumRegisters().size() > 65_535
        || program.quantumCircuits().size() > 65_535) {
      fail("Program exceeds format table limits");
    }
  }

  private static void verifyGlobals(Program program) {
    Set<String> names = new HashSet<>();
    for (Global global : program.globals()) {
      if (!names.add(global.name())) {
        fail("Duplicate global name: " + global.name());
      }
    }
  }

  private static void verifyRecordTypes(Program program) {
    Set<String> names = new HashSet<>();
    for (int index = 0; index < program.recordTypes().size(); index++) {
      RecordType record = program.recordTypes().get(index);
      if (record.id() != index || !names.add(record.name())) {
        fail("Noncanonical or duplicate record type " + record.name());
      }
      for (RecordType.Field field : record.fields()) {
        if (field.type().kind() == ValueType.Kind.RECORD
            && field.type().descriptorId() >= record.id()) {
          fail("Record fields must reference an earlier record type: " + record.name());
        }
        if (field.type().kind() == ValueType.Kind.VARIANT
            || field.type().kind() == ValueType.Kind.ARRAY
            || field.type().kind() == ValueType.Kind.SLICE
            || nonescaping(field.type())) {
          fail("Record fields cannot reference later aggregate types: " + record.name());
        }
      }
    }
  }

  private static void verifyVariantTypes(Program program) {
    Set<String> names = new HashSet<>();
    program.recordTypes().forEach(record -> names.add(record.name()));
    for (int index = 0; index < program.variantTypes().size(); index++) {
      VariantType variant = program.variantTypes().get(index);
      if (variant.id() != index || !names.add(variant.name())) {
        fail("Noncanonical or duplicate variant type " + variant.name());
      }
      for (VariantType.Case variantCase : variant.cases()) {
        for (RecordType.Field field : variantCase.fields()) {
          verifyTypeReference(program, field.type(), variant.name());
          if (field.type().kind() == ValueType.Kind.ARRAY
              || field.type().kind() == ValueType.Kind.SLICE
              || nonescaping(field.type())) {
            fail("Variant payloads cannot reference later array types: " + variant.name());
          }
          if (field.type().kind() == ValueType.Kind.VARIANT
              && field.type().descriptorId() >= variant.id()) {
            fail("Variant payloads must reference an earlier variant type: " + variant.name());
          }
        }
      }
    }
  }

  private static void verifyArrayTypes(Program program) {
    for (int index = 0; index < program.arrayTypes().size(); index++) {
      ArrayType array = program.arrayTypes().get(index);
      if (array.id() != index) {
        fail("Noncanonical array type ID " + array.id());
      }
      verifyTypeReference(program, array.elementType(), "array#" + array.id());
      if (array.elementType().kind() == ValueType.Kind.SLICE
          || nonescaping(array.elementType())) {
        fail("Arrays cannot own borrowed slices: " + array.id());
      }
      if (array.elementType().kind() == ValueType.Kind.ARRAY
          && array.elementType().descriptorId() >= array.id()) {
        fail("Array elements must reference an earlier array type: " + array.id());
      }
    }
  }

  private static void verifySliceTypes(Program program) {
    for (int index = 0; index < program.sliceTypes().size(); index++) {
      SliceType slice = program.sliceTypes().get(index);
      if (slice.id() != index || slice.elementType().kind() == ValueType.Kind.SLICE
          || nonescaping(slice.elementType())) {
        fail("Noncanonical slice type " + slice.id());
      }
      verifyTypeReference(program, slice.elementType(), "slice#" + slice.id());
    }
  }

  private static void verifyFunctions(Program program) {
    Set<String> names = new HashSet<>();
    for (FunctionBody function : program.functions()) {
      if (!names.add(function.name())) {
        fail("Duplicate function name: " + function.name());
      }
      function.localTypes().forEach(type -> verifyTypeReference(program, type, function.name()));
      for (int parameter = 0; parameter < function.parameterCount(); parameter++) {
        if (owned(function.localType(parameter))) {
          fail("Owned values cannot be function parameters: " + function.name());
        }
      }
      if (function.resultType() != null) {
        verifyTypeReference(program, function.resultType(), function.name());
        if (function.resultType().kind() == ValueType.Kind.SLICE
            || (nonescaping(function.resultType())
                && !function.resultType().equals(ValueType.REGION))) {
          fail("Borrowed or storage result escapes function " + function.name());
        }
      }
      verifyBody(program, function, function.forward(), false);
      if (function.reversible()) {
        verifyBody(program, function, function.inverse(), true);
        ProofKernel.verifyGeneratedInverse(function);
      }
      if (function.coherent()) {
        if (!function.reversible()) {
          fail("Coherent function is not reversible: " + function.name());
        }
        for (Instruction instruction : function.forward()) {
          if (!COHERENT_OPCODES.contains(instruction.opcode())) {
            fail("Coherent function contains " + instruction.opcode() + ": " + function.name());
          }
          if (instruction.opcode() == Opcode.CALL || instruction.opcode() == Opcode.UNCALL) {
            FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
            if (!target.coherent()) {
              fail("Coherent function calls noncoherent function: " + target.name());
            }
          }
        }
      }
    }
  }

  private static boolean owned(ValueType type) {
    return StorageInstructionVerifier.isOwned(type);
  }

  private static boolean nonescaping(ValueType type) {
    return owned(type) || type.equals(ValueType.UTF8_BORROW)
        || type.equals(ValueType.LONG_MAP_BORROW)
        || type.equals(ValueType.WORDS_BORROW)
        || type.equals(ValueType.BYTES_BORROW)
        || type.equals(ValueType.REGION_BORROW)
        || type.equals(ValueType.BYTE_VIEW);
  }

  private static void verifyTypeReference(
      Program program, ValueType type, String owner) {
    if (type.kind() == ValueType.Kind.RECORD
        && type.descriptorId() >= program.recordTypes().size()) {
      fail("Unknown record type " + type.displayName() + " in " + owner);
    }
    if (type.kind() == ValueType.Kind.VARIANT
        && type.descriptorId() >= program.variantTypes().size()) {
      fail("Unknown variant type " + type.displayName() + " in " + owner);
    }
    if (type.kind() == ValueType.Kind.ARRAY
        && type.descriptorId() >= program.arrayTypes().size()) {
      fail("Unknown array type " + type.displayName() + " in " + owner);
    }
    if (type.kind() == ValueType.Kind.SLICE
        && type.descriptorId() >= program.sliceTypes().size()) {
      fail("Unknown slice type " + type.displayName() + " in " + owner);
    }
  }

  private static void verifyBody(
      Program program, FunctionBody owner, List<Instruction> body, boolean inverseBody) {
    if (body.isEmpty()) {
      fail("Function body must not be empty: " + owner.name());
    }
    for (int pc = 0; pc < body.size(); pc++) {
      verifyInstruction(program, owner, body.get(pc), pc, inverseBody);
    }
    BorrowWindowVerifier.verify(program, owner, body);
    verifyLocalFlow(owner, body);
  }

  private static void verifyInstruction(
      Program program,
      FunctionBody owner,
      Instruction instruction,
      int pc,
      boolean inverseBody) {
    Opcode opcode = instruction.opcode();
    switch (opcode) {
      case ADD_CONST, SUB_CONST, XOR_CONST, SET_LOGGED, EXPECT_EQ ->
          verifyGlobal(program, instruction.operands().getFirst(), owner, pc);
      case LOCAL_CONST -> {
        int destination = verifyLocal(owner, instruction.operands().getFirst(), pc);
        if (owner.localType(destination).kind() == ValueType.Kind.RECORD
            || owner.localType(destination).kind() == ValueType.Kind.VARIANT
            || owner.localType(destination).kind() == ValueType.Kind.ARRAY
            || owner.localType(destination).kind() == ValueType.Kind.SLICE
            || owned(owner.localType(destination))) {
          fail(location(owner, pc) + " aggregate local requires aggregate construction");
        }
        if (owner.localType(destination).equals(ValueType.BOOLEAN)) {
          long value = instruction.operands().get(1);
          if (value != 0 && value != 1) {
            fail(location(owner, pc) + " invalid Boolean constant " + value);
          }
        }
      }
      case LOCAL_LOAD_GLOBAL -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        requireType(owner, destination, ValueType.SIGNED, pc);
        verifyGlobal(program, instruction.operands().get(1), owner, pc);
      }
      case LOCAL_STORE_GLOBAL -> {
        verifyGlobal(program, instruction.operands().get(0), owner, pc);
        int source = verifyLocal(owner, instruction.operands().get(1), pc);
        requireType(owner, source, ValueType.SIGNED, pc);
      }
      case LOCAL_MOVE, OWNED_MOVE -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int source = verifyLocal(owner, instruction.operands().get(1), pc);
        requireSameType(owner, destination, source, pc);
        if (owned(owner.localType(source)) != (opcode == Opcode.OWNED_MOVE)) {
          fail(location(owner, pc) + " uses the wrong copy/move operation");
        }
      }
      case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND -> {
        for (long operand : instruction.operands()) {
          requireType(owner, verifyLocal(owner, operand, pc), ValueType.SIGNED, pc);
        }
      }
      case LOCAL_XOR -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int left = verifyLocal(owner, instruction.operands().get(1), pc);
        int right = verifyLocal(owner, instruction.operands().get(2), pc);
        requireSameType(owner, destination, left, pc);
        requireSameType(owner, destination, right, pc);
        if (owner.localType(destination).kind() == ValueType.Kind.RECORD
            || owner.localType(destination).kind() == ValueType.Kind.VARIANT
            || owner.localType(destination).kind() == ValueType.Kind.ARRAY
            || owner.localType(destination).kind() == ValueType.Kind.SLICE
            || owned(owner.localType(destination))) {
          fail(location(owner, pc) + " XOR does not accept aggregate or owned values");
        }
      }
      case LOCAL_EQ -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int left = verifyLocal(owner, instruction.operands().get(1), pc);
        int right = verifyLocal(owner, instruction.operands().get(2), pc);
        requireType(owner, destination, ValueType.BOOLEAN, pc);
        requireSameType(owner, left, right, pc);
        if (owned(owner.localType(left))) {
          fail(location(owner, pc) + " owned handles do not support value equality");
        }
      }
      case LOCAL_LT -> {
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(0), pc), ValueType.BOOLEAN, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(1), pc), ValueType.SIGNED, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(2), pc), ValueType.SIGNED, pc);
      }
      case JUMP -> verifyJump(owner, instruction.operands().getFirst(), pc, owner.body(inverseBody));
      case JUMP_IF_ZERO -> {
        int condition = verifyLocal(owner, instruction.operands().get(0), pc);
        requireType(owner, condition, ValueType.BOOLEAN, pc);
        verifyJump(owner, instruction.operands().get(1), pc, owner.body(inverseBody));
      }
      case LOCAL_LOOP_CHECK -> {
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(0), pc), ValueType.SIGNED, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(1), pc), ValueType.SIGNED, pc);
      }
      case RECORD_NEW -> verifyRecordNew(program, owner, instruction, pc);
      case RECORD_GET -> verifyRecordGet(program, owner, instruction, pc);
      case VARIANT_NEW -> verifyVariantNew(program, owner, instruction, pc);
      case VARIANT_TAG_EQ -> verifyVariantTag(program, owner, instruction, pc);
      case VARIANT_GET -> verifyVariantGet(program, owner, instruction, pc);
      case ARRAY_NEW -> verifyArrayNew(program, owner, instruction, pc);
      case ARRAY_GET -> verifyArrayGet(program, owner, instruction, pc);
      case SLICE_NEW -> verifySliceNew(program, owner, instruction, pc);
      case SLICE_GET -> verifySliceGet(program, owner, instruction, pc);
      case REGION_NEW, WORDS_ALLOC, WORDS_GET, WORDS_SET,
          BYTES_ALLOC, BYTES_GET, BYTES_SET, BUFFER_DROP, REGION_DROP,
          UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH, UTF8_SCALAR, UTF8_WIDTH,
          MAP_ALLOC, MAP_PUT, MAP_GET, MAP_HAS, UTF8_FREEZE, UTF8_BORROW,
          MAP_BORROW, BUFFER_BORROW, REGION_BORROW ->
          StorageInstructionVerifier.verify(owner, instruction, pc);
      case OUTPUT_LENGTH -> {
        int output = verifyLocal(owner, instruction.operands().get(0), pc);
        int length = verifyLocal(owner, instruction.operands().get(1), pc);
        if (owner.id() != program.entryFunctionId()
            || !owner.localType(output).equals(ValueType.BYTES_BORROW)) {
          fail(location(owner, pc) + " output length requires the entry output parameter");
        }
        requireType(owner, length, ValueType.SIGNED, pc);
      }
      case SWAP -> {
        verifyGlobal(program, instruction.operands().get(0), owner, pc);
        verifyGlobal(program, instruction.operands().get(1), owner, pc);
      }
      case CALL -> {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
        if (target.parameterCount() != 0 || target.returnsValue()) {
          fail(location(owner, pc) + " void call signature mismatch for " + target.name());
        }
      }
      case CALL_VALUE -> verifyArgumentCall(program, owner, instruction, pc, true);
      case CALL_VOID -> verifyArgumentCall(program, owner, instruction, pc, false);
      case UNCALL -> {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
        if (!target.reversible()) {
          fail(location(owner, pc) + " calls missing inverse for " + target.name());
        }
      }
      case HALT -> {
        if (owner.id() != program.entryFunctionId() || inverseBody) {
          fail(location(owner, pc) + " HALT is only valid in the forward entry body");
        }
      }
      case RETURN -> {
        if (owner.id() == program.entryFunctionId() || owner.returnsValue()) {
          fail(location(owner, pc) + " invalid void RETURN");
        }
      }
      case RETURN_VALUE -> {
        int source = verifyLocal(owner, instruction.operands().getFirst(), pc);
        if (owner.id() == program.entryFunctionId() || !owner.returnsValue()) {
          fail(location(owner, pc) + " invalid value RETURN");
        }
        requireType(owner, source, owner.resultType(), pc);
      }
      case COMMIT -> {
        if (inverseBody) {
          fail(location(owner, pc) + " COMMIT cannot appear in an inverse body");
        }
      }
      case NOP, CHECKPOINT -> {
        // No additional operands to verify.
      }
    }
  }

  private static void verifyRecordNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int typeId = Math.toIntExact(instruction.operands().get(1));
    int base = Math.toIntExact(instruction.operands().get(2));
    int count = Math.toIntExact(instruction.operands().get(3));
    RecordType record = program.recordType(typeId);
    if (!owner.localType(destination).equals(ValueType.record(typeId))
        || count != record.fields().size()
        || base < 0
        || count < 0
        || base > owner.localCount() - count) {
      fail(location(owner, pc) + " record construction signature mismatch");
    }
    for (int field = 0; field < count; field++) {
      if (!owner.localType(base + field).equals(record.fields().get(field).type())) {
        fail(location(owner, pc) + " record field type mismatch at " + field);
      }
    }
  }

  private static void verifyRecordGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int source = verifyLocal(owner, instruction.operands().get(1), pc);
    int field = Math.toIntExact(instruction.operands().get(2));
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.RECORD) {
      fail(location(owner, pc) + " field access requires a record");
    }
    RecordType record = program.recordType(sourceType.descriptorId());
    if (field < 0 || field >= record.fields().size()
        || !owner.localType(destination).equals(record.fields().get(field).type())) {
      fail(location(owner, pc) + " record field access signature mismatch");
    }
  }

  private static void verifyVariantNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int typeId = Math.toIntExact(instruction.operands().get(1));
    int tag = Math.toIntExact(instruction.operands().get(2));
    int base = Math.toIntExact(instruction.operands().get(3));
    int count = Math.toIntExact(instruction.operands().get(4));
    VariantType variant = program.variantType(typeId);
    if (tag < 0 || tag >= variant.cases().size()) {
      fail(location(owner, pc) + " variant construction has invalid tag");
    }
    VariantType.Case variantCase = variant.cases().get(tag);
    if (!owner.localType(destination).equals(ValueType.variant(typeId))
        || count != variantCase.fields().size()
        || base < 0
        || count < 0
        || base > owner.localCount() - count) {
      fail(location(owner, pc) + " variant construction signature mismatch");
    }
    for (int field = 0; field < count; field++) {
      if (!owner.localType(base + field).equals(variantCase.fields().get(field).type())) {
        fail(location(owner, pc) + " variant payload type mismatch at " + field);
      }
    }
  }

  private static void verifyVariantTag(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int source = verifyLocal(owner, instruction.operands().get(1), pc);
    int tag = Math.toIntExact(instruction.operands().get(2));
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.VARIANT
        || tag < 0
        || tag >= program.variantType(sourceType.descriptorId()).cases().size()) {
      fail(location(owner, pc) + " invalid variant tag test");
    }
    requireType(owner, destination, ValueType.BOOLEAN, pc);
  }

  private static void verifyVariantGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int source = verifyLocal(owner, instruction.operands().get(1), pc);
    int tag = Math.toIntExact(instruction.operands().get(2));
    int field = Math.toIntExact(instruction.operands().get(3));
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.VARIANT) {
      fail(location(owner, pc) + " payload access requires a variant");
    }
    VariantType variant = program.variantType(sourceType.descriptorId());
    if (tag < 0 || tag >= variant.cases().size()) {
      fail(location(owner, pc) + " variant payload access has invalid tag");
    }
    VariantType.Case variantCase = variant.cases().get(tag);
    if (field < 0 || field >= variantCase.fields().size()
        || !owner.localType(destination).equals(variantCase.fields().get(field).type())) {
      fail(location(owner, pc) + " variant payload access signature mismatch");
    }
  }

  private static void verifyArrayNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int typeId = Math.toIntExact(instruction.operands().get(1));
    int base = Math.toIntExact(instruction.operands().get(2));
    int count = Math.toIntExact(instruction.operands().get(3));
    ArrayType array = program.arrayType(typeId);
    if (!owner.localType(destination).equals(ValueType.array(typeId))
        || count != array.length()
        || base < 0
        || base > owner.localCount() - count) {
      fail(location(owner, pc) + " array construction signature mismatch");
    }
    for (int element = 0; element < count; element++) {
      requireType(owner, base + element, array.elementType(), pc);
    }
  }

  private static void verifyArrayGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int source = verifyLocal(owner, instruction.operands().get(1), pc);
    int index = verifyLocal(owner, instruction.operands().get(2), pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.ARRAY) {
      fail(location(owner, pc) + " indexing requires an array");
    }
    requireType(owner, destination, program.arrayType(sourceType.descriptorId()).elementType(), pc);
    requireType(owner, index, ValueType.SIGNED, pc);
  }

  private static void verifySliceNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int typeId = Math.toIntExact(instruction.operands().get(1));
    int array = verifyLocal(owner, instruction.operands().get(2), pc);
    int start = verifyLocal(owner, instruction.operands().get(3), pc);
    int length = verifyLocal(owner, instruction.operands().get(4), pc);
    ValueType arrayType = owner.localType(array);
    if (arrayType.kind() != ValueType.Kind.ARRAY
        || !program.arrayType(arrayType.descriptorId()).elementType()
            .equals(program.sliceType(typeId).elementType())) {
      fail(location(owner, pc) + " slice origin type mismatch");
    }
    requireType(owner, destination, ValueType.slice(typeId), pc);
    requireType(owner, start, ValueType.SIGNED, pc);
    requireType(owner, length, ValueType.SIGNED, pc);
  }

  private static void verifySliceGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction.operands().get(0), pc);
    int source = verifyLocal(owner, instruction.operands().get(1), pc);
    int index = verifyLocal(owner, instruction.operands().get(2), pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.SLICE) {
      fail(location(owner, pc) + " indexing requires a slice");
    }
    requireType(owner, destination, program.sliceType(sourceType.descriptorId()).elementType(), pc);
    requireType(owner, index, ValueType.SIGNED, pc);
  }

  private static void verifyLocalFlow(FunctionBody owner, List<Instruction> body) {
    BitSet[] incoming = new BitSet[body.size()];
    incoming[0] = new BitSet(owner.localCount());
    incoming[0].set(0, owner.parameterCount());
    ArrayDeque<Integer> work = new ArrayDeque<>();
    work.add(0);
    while (!work.isEmpty()) {
      int pc = work.removeFirst();
      BitSet assigned = (BitSet) incoming[pc].clone();
      Instruction instruction = body.get(pc);
      requireAssignedLocals(owner, instruction, pc, assigned);
      int written = writtenLocal(instruction);
      if (written >= 0) {
        if (owned(owner.localType(written)) && assigned.get(written)) {
          fail(location(owner, pc) + " overwrites a live owned local " + written);
        }
        assigned.set(written);
      }
      if (instruction.opcode() == Opcode.OWNED_MOVE
          || instruction.opcode() == Opcode.UTF8_FREEZE) {
        assigned.clear(Math.toIntExact(instruction.operands().get(1)));
      } else if (instruction.opcode() == Opcode.RETURN_VALUE
          && owner.resultType() != null && owned(owner.resultType())) {
        assigned.clear(Math.toIntExact(instruction.operands().getFirst()));
      } else if (instruction.opcode() == Opcode.BUFFER_DROP
          || instruction.opcode() == Opcode.REGION_DROP) {
        assigned.clear(Math.toIntExact(instruction.operands().getFirst()));
      } else if (instruction.opcode() == Opcode.CALL_VALUE
          || instruction.opcode() == Opcode.CALL_VOID) {
        int base = Math.toIntExact(instruction.operands().get(1));
        int count = Math.toIntExact(instruction.operands().get(2));
        for (int local = base; local < base + count; local++) {
          if (owner.localType(local).equals(ValueType.UTF8_BORROW)
              || owner.localType(local).equals(ValueType.LONG_MAP_BORROW)
              || owner.localType(local).equals(ValueType.WORDS_BORROW)
              || owner.localType(local).equals(ValueType.BYTES_BORROW)
              || owner.localType(local).equals(ValueType.REGION_BORROW)
              || owner.localType(local).equals(ValueType.BYTE_VIEW)) {
            assigned.clear(local);
          }
        }
      }
      if (successors(owner, body, pc, instruction).isEmpty()) {
        requireNoLiveOwnedLocals(owner, pc, assigned);
      }
      for (int successor : successors(owner, body, pc, instruction)) {
        if (incoming[successor] == null) {
          incoming[successor] = (BitSet) assigned.clone();
          work.add(successor);
        } else {
          requireOwnedJoin(owner, successor, incoming[successor], assigned);
          BitSet merged = (BitSet) incoming[successor].clone();
          merged.and(assigned);
          if (!merged.equals(incoming[successor])) {
            incoming[successor] = merged;
            work.add(successor);
          }
        }
      }
    }
  }

  private static void requireOwnedJoin(
      FunctionBody owner, int pc, BitSet left, BitSet right) {
    for (int local = 0; local < owner.localCount(); local++) {
      if (owned(owner.localType(local)) && left.get(local) != right.get(local)) {
        fail(location(owner, pc) + " ownership state differs across control-flow paths");
      }
    }
  }

  private static void requireNoLiveOwnedLocals(
      FunctionBody owner, int pc, BitSet assigned) {
    for (int local = 0; local < owner.localCount(); local++) {
      if (owned(owner.localType(local)) && assigned.get(local)) {
        fail(location(owner, pc) + " exits with live owned local " + local);
      }
    }
  }

  private static void requireAssignedLocals(
      FunctionBody owner, Instruction instruction, int pc, BitSet assigned) {
    if (instruction.opcode() == Opcode.CALL_VALUE
        || instruction.opcode() == Opcode.CALL_VOID
        || instruction.opcode() == Opcode.RECORD_NEW
        || instruction.opcode() == Opcode.VARIANT_NEW
        || instruction.opcode() == Opcode.ARRAY_NEW) {
      int baseOperand = switch (instruction.opcode()) {
        case CALL_VALUE, CALL_VOID -> 1;
        case RECORD_NEW -> 2;
        case VARIANT_NEW -> 3;
        case ARRAY_NEW -> 2;
        default -> throw new IllegalStateException();
      };
      int countOperand = baseOperand + 1;
      int base = Math.toIntExact(instruction.operands().get(baseOperand));
      int count = Math.toIntExact(instruction.operands().get(countOperand));
      for (int local = base; local < base + count; local++) {
        if (!assigned.get(local)) {
          fail(location(owner, pc) + " reads uninitialized local " + local);
        }
      }
      return;
    }
    int[] reads = switch (instruction.opcode()) {
      case LOCAL_STORE_GLOBAL -> new int[] {1};
      case LOCAL_MOVE, OWNED_MOVE, UTF8_FREEZE, UTF8_BORROW, MAP_BORROW,
          BUFFER_BORROW, REGION_BORROW ->
          new int[] {1};
      case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_XOR, LOCAL_EQ, LOCAL_LT ->
          new int[] {1, 2};
      case JUMP_IF_ZERO -> new int[] {0};
      case LOCAL_LOOP_CHECK -> new int[] {0, 1};
      case RETURN_VALUE -> new int[] {0};
      case RECORD_GET, VARIANT_TAG_EQ, VARIANT_GET -> new int[] {1};
      case ARRAY_GET, SLICE_GET, WORDS_GET, BYTES_GET,
          UTF8_SCALAR, UTF8_WIDTH -> new int[] {1, 2};
      case UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH -> new int[] {1};
      case SLICE_NEW -> new int[] {2, 3, 4};
      case WORDS_ALLOC, BYTES_ALLOC, MAP_ALLOC -> new int[] {1, 2};
      case WORDS_SET, BYTES_SET, MAP_PUT -> new int[] {0, 1, 2};
      case MAP_GET, MAP_HAS -> new int[] {1, 2};
      case BUFFER_DROP, REGION_DROP -> new int[] {0};
      case OUTPUT_LENGTH -> new int[] {0, 1};
      default -> new int[0];
    };
    for (int operandIndex : reads) {
      int local = Math.toIntExact(instruction.operands().get(operandIndex));
      if (!assigned.get(local)) {
        fail(location(owner, pc) + " reads uninitialized local " + local);
      }
    }
  }

  private static int writtenLocal(Instruction instruction) {
    return switch (instruction.opcode()) {
      case LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, OWNED_MOVE,
          LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_XOR, LOCAL_EQ, LOCAL_LT,
          LOCAL_LOOP_CHECK,
          RECORD_NEW, RECORD_GET, VARIANT_NEW, VARIANT_TAG_EQ, VARIANT_GET,
          ARRAY_NEW, ARRAY_GET, SLICE_NEW, SLICE_GET, REGION_NEW,
          WORDS_ALLOC, WORDS_GET, BYTES_ALLOC, BYTES_GET,
          UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH, UTF8_SCALAR, UTF8_WIDTH,
          MAP_ALLOC, MAP_GET, MAP_HAS, UTF8_FREEZE, UTF8_BORROW, MAP_BORROW,
          BUFFER_BORROW, REGION_BORROW ->
          Math.toIntExact(instruction.operands().getFirst());
      case CALL_VALUE -> Math.toIntExact(instruction.operands().get(3));
      default -> -1;
    };
  }

  private static List<Integer> successors(
      FunctionBody owner, List<Instruction> body, int pc, Instruction instruction) {
    if (instruction.opcode() == Opcode.HALT
        || instruction.opcode() == Opcode.RETURN
        || instruction.opcode() == Opcode.RETURN_VALUE) {
      return List.of();
    }
    if (instruction.opcode() == Opcode.JUMP) {
      return List.of(Math.toIntExact(instruction.operands().getFirst()));
    }
    if (instruction.opcode() == Opcode.JUMP_IF_ZERO) {
      int next = checkedFallthrough(owner, body, pc);
      return List.of(next, Math.toIntExact(instruction.operands().get(1)));
    }
    return List.of(checkedFallthrough(owner, body, pc));
  }

  private static int checkedFallthrough(FunctionBody owner, List<Instruction> body, int pc) {
    if (pc + 1 >= body.size()) {
      fail(location(owner, pc) + " falls off the function body");
    }
    return pc + 1;
  }

  private static void verifyArgumentCall(
      Program program,
      FunctionBody owner,
      Instruction instruction,
      int pc,
      boolean returnsValue) {
    FunctionBody target = program.function(Math.toIntExact(instruction.operands().get(0)));
    int base = Math.toIntExact(instruction.operands().get(1));
    int count = Math.toIntExact(instruction.operands().get(2));
    if (target.returnsValue() != returnsValue
        || count != target.parameterCount()
        || base < 0
        || count < 0
        || base > owner.localCount() - count) {
      fail(location(owner, pc) + " call signature mismatch for " + target.name());
    }
    if (returnsValue) {
      int destination = verifyLocal(owner, instruction.operands().get(3), pc);
      requireType(owner, destination, target.resultType(), pc);
    }
    for (int argument = 0; argument < count; argument++) {
      if (!owner.localType(base + argument).equals(target.localType(argument))) {
        fail(location(owner, pc) + " call argument type mismatch for " + target.name());
      }
    }
  }

  private static int verifyLocal(FunctionBody owner, long operand, int pc) {
    if (operand < 0 || operand >= owner.localCount()) {
      fail(location(owner, pc) + " invalid local index " + operand);
    }
    return Math.toIntExact(operand);
  }

  private static void requireType(
      FunctionBody owner, int local, ValueType expected, int pc) {
    if (!owner.localType(local).equals(expected)) {
      fail(location(owner, pc) + " local " + local + " must have type "
          + expected.displayName());
    }
  }

  private static void requireSameType(
      FunctionBody owner, int left, int right, int pc) {
    if (!owner.localType(left).equals(owner.localType(right))) {
      fail(location(owner, pc) + " local type mismatch between " + left + " and " + right);
    }
  }

  private static void verifyJump(
      FunctionBody owner, long operand, int pc, List<Instruction> body) {
    if (operand < 0 || operand >= body.size()) {
      fail(location(owner, pc) + " invalid jump target " + operand);
    }
  }

  private static void verifyProofs(Program program) {
    Set<String> names = new HashSet<>();
    for (int index = 0; index < program.proofCertificates().size(); index++) {
      var proof = program.proofCertificates().get(index);
      if (proof.id() != index || !names.add(proof.name())) {
        fail("Noncanonical or duplicate proof " + proof.name());
      }
      ProofKernel.verify(program, proof);
    }
  }

  private static void verifyQuantum(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      if (!program.quantumRegisters().isEmpty()
          || !program.quantumCircuits().isEmpty()
          || !program.workflow().isEmpty()) {
        fail("Classical program contains quantum or workflow content");
      }
      return;
    }

    Set<String> registerNames = new HashSet<>();
    for (QuantumRegister register : program.quantumRegisters()) {
      if (!registerNames.add(register.name())) {
        fail("Duplicate quantum register name: " + register.name());
      }
    }
    Set<String> circuitNames = new HashSet<>();
    for (QuantumCircuit circuit : program.quantumCircuits()) {
      if (!circuitNames.add(circuit.name())) {
        fail("Duplicate quantum circuit name: " + circuit.name());
      }
      QuantumRegister register = program.quantumRegister(circuit.registerId());
      for (QuantumOperation operation : circuit.operations()) {
        if (operation instanceof GateOperation gate) {
          Set<Integer> used = new HashSet<>();
          for (int qubit : gate.qubits()) {
            if (qubit < 0 || qubit >= register.qubits() || !used.add(qubit)) {
              fail("Invalid or repeated qubit in circuit " + circuit.name());
            }
          }
        } else if (operation instanceof ParameterizedGateOperation gate) {
          Set<Integer> used = new HashSet<>();
          for (int qubit : gate.qubits()) {
            if (qubit < 0 || qubit >= register.qubits() || !used.add(qubit)) {
              fail("Invalid or repeated qubit in circuit " + circuit.name());
            }
          }
        } else if (operation instanceof LiftedCall lifted) {
          FunctionBody function = program.function(lifted.functionId());
          if (!function.coherent()) {
            fail("Lifted function is not coherent: " + function.name());
          }
        }
      }
    }
  }

  private static void verifyWorkflow(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      return;
    }
    if (program.workflow().isEmpty()
        || program.workflow().getLast().opcode() != WorkflowOpcode.HALT) {
      fail("Quantum and hybrid workflows must end in HALT");
    }
    int halts = 0;
    for (WorkflowStep step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> {
          QuantumRegister register = program.quantumRegister(Math.toIntExact(step.first()));
          if (step.second() < 0
              || (register.qubits() < 63 && step.second() >= (1L << register.qubits()))) {
            fail("Preparation basis value does not fit register " + register.name());
          }
        }
        case APPLY, UNAPPLY -> program.quantumCircuit(Math.toIntExact(step.first()));
        case MEASURE -> {
          program.quantumRegister(Math.toIntExact(step.first()));
          verifyGlobal(program, step.second(), program.function(program.entryFunctionId()), 0);
        }
        case CLASSICAL_CALL -> program.function(Math.toIntExact(step.first()));
        case CLASSICAL_UNCALL -> {
          FunctionBody function = program.function(Math.toIntExact(step.first()));
          if (!function.reversible()) {
            fail("Workflow uncalls nonreversible function " + function.name());
          }
        }
        case EXPECT -> verifyGlobal(
            program, step.first(), program.function(program.entryFunctionId()), 0);
        case COMMIT -> requireZeroOperands(step);
        case HALT -> {
          requireZeroOperands(step);
          halts++;
        }
      }
    }
    if (halts != 1) {
      fail("Workflow must contain exactly one final HALT");
    }
  }

  private static void requireZeroOperands(WorkflowStep step) {
    if (step.first() != 0 || step.second() != 0 || step.third() != 0) {
      fail(step.opcode() + " workflow record has nonzero operands");
    }
  }

  private static void verifyGlobal(
      Program program, long operand, FunctionBody owner, int pc) {
    if (operand < 0 || operand >= program.globals().size()) {
      fail(location(owner, pc) + " invalid global index " + operand);
    }
  }

  private static String location(FunctionBody function, int pc) {
    return function.name() + "[" + pc + "]";
  }

  private static void fail(String message) {
    throw new BytecodeException(message);
  }
}
