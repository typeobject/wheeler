package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.*;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CAPACITY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CONDITION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESCRIPTOR;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.INDEX;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ITERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.KEY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LENGTH;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LOCAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OWNER;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT_SLOT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.START;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TAG;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TARGET;

import com.typeobject.wheeler.core.proof.ProofKernel;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Structural and semantic verification for decoded Wheeler programs. */
public final class BytecodeVerifier {
  private static final Set<Opcode> COHERENT_OPCODES = Set.of(
      Opcode.NOP,
      Opcode.ADD_CONST,
      Opcode.SUB_CONST,
      Opcode.XOR_CONST,
      Opcode.CALL,
      Opcode.UNCALL,
      Opcode.RETURN);

  private BytecodeVerifier() {}

  public static void verify(Program program) {
    InstructionExtensionCodec.validate(program.requiredInstructionExtensions());
    verifyLimits(program);
    verifyGlobals(program);
    verifyRecordTypes(program);
    verifyVariantTypes(program);
    verifyArrayTypes(program);
    verifySliceTypes(program);
    verifyFunctions(program);
    ProgramSectionVerifier.verifyQuantum(program);
    ProgramSectionVerifier.verifyProofs(program);
    ProgramSectionVerifier.verifyWorkflow(program);

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
        verifyTypeReference(program, field.type(), record.name());
        if (field.type().kind() == ValueType.Kind.ARRAY) {
          verifyEmbeddedScalarArray(program, field.type(), record.name());
        } else if (field.type().kind() == ValueType.Kind.SLICE
            || nonescaping(field.type())) {
          fail("Record fields cannot borrow storage: " + record.name());
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
          if (field.type().kind() == ValueType.Kind.ARRAY) {
            verifyEmbeddedScalarArray(program, field.type(), variant.name());
          } else if (field.type().kind() == ValueType.Kind.SLICE
              || nonescaping(field.type())) {
            fail("Variant payloads cannot reference this aggregate type: " + variant.name());
          }
        }
      }
    }
  }

  private static void verifyEmbeddedScalarArray(
      Program program, ValueType type, String owner) {
    verifyTypeReference(program, type, owner);
    ValueType element = program.arrayTypes().get(type.descriptorId()).elementType();
    if (!element.equals(ValueType.SIGNED) && !element.equals(ValueType.BOOLEAN)
        && !element.equals(ValueType.DONE)) {
      fail("Embedded arrays require scalar elements: " + owner);
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
      if (function.resultType() != null) {
        verifyTypeReference(program, function.resultType(), function.name());
        if (function.resultType().kind() == ValueType.Kind.SLICE
            || borrowed(function.resultType())) {
          fail("Borrowed result escapes function " + function.name());
        }
      }
      if (function.implicitResultSlot()) {
        ResultSlotVerifier.verifyFunction(function);
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
        for (int pc = 0; pc < function.forward().size(); pc++) {
          Instruction instruction = function.forward().get(pc);
          if (!COHERENT_OPCODES.contains(instruction.opcode())) {
            fail("Coherent function contains " + instruction.opcode() + ": " + function.name());
          }
          if (instruction.opcode() == Opcode.CALL || instruction.opcode() == Opcode.UNCALL) {
            FunctionBody target = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
            if (!target.coherent()) {
              failOperand(
                  function, instruction, FUNCTION, pc,
                  "coherent function calls noncoherent function " + target.name());
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
    return owned(type) || borrowed(type);
  }

  private static boolean borrowed(ValueType type) {
    return type.equals(ValueType.UTF8_BORROW)
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
          verifyGlobal(program, instruction, GLOBAL, owner, pc);
      case EXPECT_TRUE -> {
        int condition = verifyLocal(owner, instruction, CONDITION, pc);
        requireType(owner, instruction, condition, CONDITION, ValueType.BOOLEAN, pc);
      }
      case LOCAL_CONST -> {
        int destination = verifyLocal(owner, instruction, DESTINATION, pc);
        if (owner.localType(destination).kind() == ValueType.Kind.RECORD
            || owner.localType(destination).kind() == ValueType.Kind.VARIANT
            || owner.localType(destination).kind() == ValueType.Kind.ARRAY
            || owner.localType(destination).kind() == ValueType.Kind.SLICE
            || owned(owner.localType(destination))) {
          failOperand(
              owner, instruction, DESTINATION, pc,
              "aggregate local requires aggregate construction");
        }
        long value = instruction.operand(IMMEDIATE);
        if (owner.localType(destination).equals(ValueType.BOOLEAN)
            && value != 0 && value != 1) {
          failOperand(
              owner, instruction, IMMEDIATE, pc,
              "Boolean constant must be zero or one, got " + value);
        }
        if (owner.localType(destination).equals(ValueType.DONE) && value != 0) {
          failOperand(
              owner, instruction, IMMEDIATE, pc,
              "Done constant must be zero, got " + value);
        }
      }
      case LOCAL_LOAD_GLOBAL -> {
        int destination = verifyLocal(owner, instruction, DESTINATION, pc);
        requireType(owner, instruction, destination, DESTINATION, ValueType.SIGNED, pc);
        verifyGlobal(program, instruction, GLOBAL, owner, pc);
      }
      case LOCAL_STORE_GLOBAL -> {
        verifyGlobal(program, instruction, GLOBAL, owner, pc);
        int source = verifyLocal(owner, instruction, SOURCE, pc);
        requireType(owner, instruction, source, SOURCE, ValueType.SIGNED, pc);
      }
      case LOCAL_MOVE, OWNED_MOVE -> {
        int destination = verifyLocal(owner, instruction, DESTINATION, pc);
        int source = verifyLocal(owner, instruction, SOURCE, pc);
        requireSameType(
            owner, instruction, destination, DESTINATION, source, SOURCE, pc);
        if (owned(owner.localType(source)) != (opcode == Opcode.OWNED_MOVE)) {
          failOperand(owner, instruction, SOURCE, pc, "uses the wrong copy/move operation");
        }
      }
      case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_ROTR32 -> {
        requireType(
            owner, instruction, verifyLocal(owner, instruction, DESTINATION, pc),
            DESTINATION, ValueType.SIGNED, pc);
        requireType(
            owner, instruction, verifyLocal(owner, instruction, LEFT_SOURCE, pc),
            LEFT_SOURCE, ValueType.SIGNED, pc);
        requireType(
            owner, instruction, verifyLocal(owner, instruction, RIGHT_SOURCE, pc),
            RIGHT_SOURCE, ValueType.SIGNED, pc);
      }
      case LOCAL_XOR -> {
        int destination = verifyLocal(owner, instruction, DESTINATION, pc);
        int left = verifyLocal(owner, instruction, LEFT_SOURCE, pc);
        int right = verifyLocal(owner, instruction, RIGHT_SOURCE, pc);
        requireSameType(
            owner, instruction, destination, DESTINATION, left, LEFT_SOURCE, pc);
        requireSameType(
            owner, instruction, destination, DESTINATION, right, RIGHT_SOURCE, pc);
        ValueType xorType = owner.localType(destination);
        if (!xorType.equals(ValueType.SIGNED) && !xorType.equals(ValueType.BOOLEAN)) {
          failOperand(
              owner, instruction, DESTINATION, pc,
              "XOR requires signed or Boolean values");
        }
      }
      case LOCAL_EQ -> {
        int destination = verifyLocal(owner, instruction, DESTINATION, pc);
        int left = verifyLocal(owner, instruction, LEFT_SOURCE, pc);
        int right = verifyLocal(owner, instruction, RIGHT_SOURCE, pc);
        requireType(owner, instruction, destination, DESTINATION, ValueType.BOOLEAN, pc);
        requireSameType(owner, instruction, left, LEFT_SOURCE, right, RIGHT_SOURCE, pc);
        if (owned(owner.localType(left))) {
          failOperand(
              owner, instruction, LEFT_SOURCE, pc,
              "owned handles do not support value equality");
        }
      }
      case LOCAL_LT -> {
        requireType(
            owner, instruction, verifyLocal(owner, instruction, DESTINATION, pc),
            DESTINATION, ValueType.BOOLEAN, pc);
        requireType(
            owner, instruction, verifyLocal(owner, instruction, LEFT_SOURCE, pc),
            LEFT_SOURCE, ValueType.SIGNED, pc);
        requireType(
            owner, instruction, verifyLocal(owner, instruction, RIGHT_SOURCE, pc),
            RIGHT_SOURCE, ValueType.SIGNED, pc);
      }
      case JUMP -> verifyJump(owner, instruction, TARGET, pc, owner.body(inverseBody));
      case JUMP_IF_ZERO -> {
        int condition = verifyLocal(owner, instruction, CONDITION, pc);
        requireType(owner, instruction, condition, CONDITION, ValueType.BOOLEAN, pc);
        verifyJump(owner, instruction, TARGET, pc, owner.body(inverseBody));
      }
      case LOCAL_LOOP_CHECK -> {
        requireType(
            owner, instruction, verifyLocal(owner, instruction, ITERATION, pc),
            ITERATION, ValueType.SIGNED, pc);
        requireType(
            owner, instruction, verifyLocal(owner, instruction, LIMIT, pc),
            LIMIT, ValueType.SIGNED, pc);
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
        int output = verifyLocal(owner, instruction, InstructionForm.OperandRole.OWNER, pc);
        int length = verifyLocal(owner, instruction, LENGTH, pc);
        if (owner.id() != program.entryFunctionId()
            || !owner.localType(output).equals(ValueType.BYTES_BORROW)) {
          failOperand(
              owner, instruction, OWNER, pc,
              "output length requires the entry output parameter");
        }
        requireType(owner, instruction, length, LENGTH, ValueType.SIGNED, pc);
      }
      case SWAP -> {
        verifyGlobal(program, instruction, LEFT_GLOBAL, owner, pc);
        verifyGlobal(program, instruction, RIGHT_GLOBAL, owner, pc);
      }
      case CALL -> {
        FunctionBody target = program.function(verifyReference(
            owner, instruction, FUNCTION, pc, program.functions().size(), "function"));
        if (target.parameterCount() != 0 || target.returnsValue()) {
          failOperand(
              owner, instruction, FUNCTION, pc,
              "void call signature mismatch for " + target.name());
        }
      }
      case CALL_VALUE -> verifyArgumentCall(program, owner, instruction, pc, true);
      case CALL_VOID -> verifyArgumentCall(program, owner, instruction, pc, false);
      case CALL_RESULT_SLOT, UNCALL_RESULT_SLOT ->
          ResultSlotVerifier.verifyCall(program, owner, instruction, pc);
      case UNCALL -> {
        FunctionBody target = program.function(verifyReference(
            owner, instruction, FUNCTION, pc, program.functions().size(), "function"));
        if (!target.reversible()) {
          failOperand(
              owner, instruction, FUNCTION, pc,
              "calls missing inverse for " + target.name());
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
        int source = verifyLocal(owner, instruction, RESULT, pc);
        if (owner.id() == program.entryFunctionId() || !owner.returnsValue()
            || owner.implicitResultSlot()) {
          fail(location(owner, pc) + " invalid value RETURN");
        }
        requireType(owner, instruction, source, RESULT, owner.resultType(), pc);
      }
      case RESULT_FILL_CONSTANT ->
          ResultSlotVerifier.verifyFill(owner, instruction, pc);
      case RESULT_FILL_SOURCE ->
          ResultSlotVerifier.verifyFillSource(owner, instruction, pc);
      case RESULT_FILL_BINARY ->
          ResultSlotVerifier.verifyFillBinary(owner, instruction, pc);
      case RESULT_FILL_BINARY_SOURCES ->
          ResultSlotVerifier.verifyFillBinarySources(owner, instruction, pc);
      case RETURN_RESULT_SLOT ->
          ResultSlotVerifier.verifyReturn(program, owner, instruction, pc);
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
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int typeId = verifyReference(
        owner, instruction, DESCRIPTOR, pc, program.recordTypes().size(), "record type");
    var window = verifyLocalWindow(owner, instruction, ELEMENT_BASE, ELEMENT_COUNT, pc);
    RecordType record = program.recordType(typeId);
    requireType(
        owner, instruction, destination, DESTINATION, ValueType.record(typeId), pc);
    if (window.count() != record.fields().size()) {
      failOperand(
          owner, instruction, ELEMENT_COUNT, pc,
          "field count must be " + record.fields().size() + ", got " + window.count());
    }
    for (int field = 0; field < window.count(); field++) {
      requireType(
          owner, instruction, window.base() + field, ELEMENT_BASE,
          record.fields().get(field).type(), pc);
    }
  }

  private static void verifyRecordGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int source = verifyLocal(owner, instruction, OWNER, pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.RECORD) {
      failOperand(owner, instruction, OWNER, pc, "field access requires a record");
    }
    RecordType record = program.recordType(sourceType.descriptorId());
    int field = verifyReference(
        owner, instruction, INDEX, pc, record.fields().size(), "record field");
    requireType(
        owner, instruction, destination, DESTINATION, record.fields().get(field).type(), pc);
  }

  private static void verifyVariantNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int typeId = verifyReference(
        owner, instruction, DESCRIPTOR, pc, program.variantTypes().size(), "variant type");
    VariantType variant = program.variantType(typeId);
    int tag = verifyReference(
        owner, instruction, TAG, pc, variant.cases().size(), "variant tag");
    var window = verifyLocalWindow(owner, instruction, ELEMENT_BASE, ELEMENT_COUNT, pc);
    VariantType.Case variantCase = variant.cases().get(tag);
    requireType(
        owner, instruction, destination, DESTINATION, ValueType.variant(typeId), pc);
    if (window.count() != variantCase.fields().size()) {
      failOperand(
          owner, instruction, ELEMENT_COUNT, pc,
          "payload count must be " + variantCase.fields().size()
              + ", got " + window.count());
    }
    for (int field = 0; field < window.count(); field++) {
      requireType(
          owner, instruction, window.base() + field, ELEMENT_BASE,
          variantCase.fields().get(field).type(), pc);
    }
  }

  private static void verifyVariantTag(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int source = verifyLocal(owner, instruction, OWNER, pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.VARIANT) {
      failOperand(owner, instruction, OWNER, pc, "tag test requires a variant");
    }
    VariantType variant = program.variantType(sourceType.descriptorId());
    verifyReference(owner, instruction, TAG, pc, variant.cases().size(), "variant tag");
    requireType(owner, instruction, destination, DESTINATION, ValueType.BOOLEAN, pc);
  }

  private static void verifyVariantGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int source = verifyLocal(owner, instruction, OWNER, pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.VARIANT) {
      failOperand(owner, instruction, OWNER, pc, "payload access requires a variant");
    }
    VariantType variant = program.variantType(sourceType.descriptorId());
    int tag = verifyReference(
        owner, instruction, TAG, pc, variant.cases().size(), "variant tag");
    VariantType.Case variantCase = variant.cases().get(tag);
    int field = verifyReference(
        owner, instruction, INDEX, pc, variantCase.fields().size(), "variant field");
    requireType(
        owner, instruction, destination, DESTINATION,
        variantCase.fields().get(field).type(), pc);
  }

  private static void verifyArrayNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int typeId = verifyReference(
        owner, instruction, DESCRIPTOR, pc, program.arrayTypes().size(), "array type");
    var window = verifyLocalWindow(owner, instruction, ELEMENT_BASE, ELEMENT_COUNT, pc);
    ArrayType array = program.arrayType(typeId);
    requireType(
        owner, instruction, destination, DESTINATION, ValueType.array(typeId), pc);
    if (window.count() != array.length()) {
      failOperand(
          owner, instruction, ELEMENT_COUNT, pc,
          "element count must be " + array.length() + ", got " + window.count());
    }
    for (int element = 0; element < window.count(); element++) {
      requireType(
          owner, instruction, window.base() + element, ELEMENT_BASE,
          array.elementType(), pc);
    }
  }

  private static void verifyArrayGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int source = verifyLocal(owner, instruction, OWNER, pc);
    int index = verifyLocal(owner, instruction, INDEX, pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.ARRAY) {
      failOperand(owner, instruction, OWNER, pc, "indexing requires an array");
    }
    requireType(
        owner, instruction, destination, DESTINATION,
        program.arrayType(sourceType.descriptorId()).elementType(), pc);
    requireType(owner, instruction, index, INDEX, ValueType.SIGNED, pc);
  }

  private static void verifySliceNew(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int typeId = verifyReference(
        owner, instruction, DESCRIPTOR, pc, program.sliceTypes().size(), "slice type");
    int array = verifyLocal(owner, instruction, OWNER, pc);
    int start = verifyLocal(owner, instruction, START, pc);
    int length = verifyLocal(owner, instruction, LENGTH, pc);
    ValueType arrayType = owner.localType(array);
    if (arrayType.kind() != ValueType.Kind.ARRAY
        || !program.arrayType(arrayType.descriptorId()).elementType()
            .equals(program.sliceType(typeId).elementType())) {
      failOperand(owner, instruction, OWNER, pc, "slice origin type mismatch");
    }
    requireType(owner, instruction, destination, DESTINATION, ValueType.slice(typeId), pc);
    requireType(owner, instruction, start, START, ValueType.SIGNED, pc);
    requireType(owner, instruction, length, LENGTH, ValueType.SIGNED, pc);
  }

  private static void verifySliceGet(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int destination = verifyLocal(owner, instruction, DESTINATION, pc);
    int source = verifyLocal(owner, instruction, OWNER, pc);
    int index = verifyLocal(owner, instruction, INDEX, pc);
    ValueType sourceType = owner.localType(source);
    if (sourceType.kind() != ValueType.Kind.SLICE) {
      failOperand(owner, instruction, OWNER, pc, "indexing requires a slice");
    }
    requireType(
        owner, instruction, destination, DESTINATION,
        program.sliceType(sourceType.descriptorId()).elementType(), pc);
    requireType(owner, instruction, index, INDEX, ValueType.SIGNED, pc);
  }

  private static void verifyLocalFlow(FunctionBody owner, List<Instruction> body) {
    BitSet[] incoming = new BitSet[body.size()];
    incoming[0] = new BitSet(owner.localCount());
    incoming[0].set(0, owner.parameterCount());
    if (owner.implicitResultSlot()) {
      incoming[0].set(owner.resultSlotBase(), owner.resultSlotBase() + 2);
    }
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
          failOperand(
              owner, instruction, writtenRole(instruction), pc,
              "overwrites live owned local " + written);
        }
        assigned.set(written);
      }
      if (instruction.opcode() == Opcode.OWNED_MOVE
          || instruction.opcode() == Opcode.UTF8_FREEZE) {
        assigned.clear(Math.toIntExact(instruction.operand(SOURCE)));
      } else if (instruction.opcode() == Opcode.RETURN_VALUE
          && owner.resultType() != null && owned(owner.resultType())) {
        assigned.clear(Math.toIntExact(instruction.operand(RESULT)));
      } else if (instruction.opcode() == Opcode.BUFFER_DROP
          || instruction.opcode() == Opcode.REGION_DROP) {
        assigned.clear(Math.toIntExact(instruction.operand(LOCAL)));
      } else if (instruction.opcode() == Opcode.CALL_VALUE
          || instruction.opcode() == Opcode.CALL_VOID
          || instruction.opcode() == Opcode.CALL_RESULT_SLOT
          || instruction.opcode() == Opcode.UNCALL_RESULT_SLOT) {
        int base = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
        int count = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
        for (int local = base; local < base + count; local++) {
          if (owned(owner.localType(local))
              || owner.localType(local).equals(ValueType.UTF8_BORROW)
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
        || instruction.opcode() == Opcode.CALL_RESULT_SLOT
        || instruction.opcode() == Opcode.UNCALL_RESULT_SLOT
        || instruction.opcode() == Opcode.RECORD_NEW
        || instruction.opcode() == Opcode.VARIANT_NEW
        || instruction.opcode() == Opcode.ARRAY_NEW) {
      InstructionForm.OperandRole baseRole = switch (instruction.opcode()) {
        case CALL_VALUE, CALL_VOID, CALL_RESULT_SLOT, UNCALL_RESULT_SLOT -> ARGUMENT_BASE;
        case RECORD_NEW, VARIANT_NEW, ARRAY_NEW -> ELEMENT_BASE;
        default -> throw new IllegalStateException();
      };
      InstructionForm.OperandRole countRole = switch (instruction.opcode()) {
        case CALL_VALUE, CALL_VOID, CALL_RESULT_SLOT, UNCALL_RESULT_SLOT -> ARGUMENT_COUNT;
        case RECORD_NEW, VARIANT_NEW, ARRAY_NEW -> ELEMENT_COUNT;
        default -> throw new IllegalStateException();
      };
      int base = Math.toIntExact(instruction.operand(baseRole));
      int count = Math.toIntExact(instruction.operand(countRole));
      for (int local = base; local < base + count; local++) {
        requireAssignedLocal(owner, instruction, baseRole, pc, assigned, local);
      }
      if (instruction.opcode() == Opcode.CALL_RESULT_SLOT
          || instruction.opcode() == Opcode.UNCALL_RESULT_SLOT) {
        int slot = Math.toIntExact(instruction.operand(RESULT_SLOT));
        requireAssignedLocal(owner, instruction, RESULT_SLOT, pc, assigned, slot);
        requireAssignedLocal(owner, instruction, RESULT_SLOT, pc, assigned, slot + 1);
      }
      return;
    }
    List<InstructionForm.OperandRole> reads = switch (instruction.opcode()) {
      case LOCAL_STORE_GLOBAL, LOCAL_MOVE, OWNED_MOVE, UTF8_FREEZE, UTF8_BORROW,
          MAP_BORROW, BUFFER_BORROW, REGION_BORROW -> List.of(SOURCE);
      case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_ROTR32, LOCAL_XOR, LOCAL_EQ, LOCAL_LT -> List.of(LEFT_SOURCE, RIGHT_SOURCE);
      case JUMP_IF_ZERO, EXPECT_TRUE -> List.of(CONDITION);
      case LOCAL_LOOP_CHECK -> List.of(ITERATION, LIMIT);
      case RETURN_VALUE -> List.of(RESULT);
      case RESULT_FILL_CONSTANT, RETURN_RESULT_SLOT -> List.of(RESULT_SLOT);
      case RESULT_FILL_SOURCE, RESULT_FILL_BINARY -> List.of(RESULT_SLOT, SOURCE);
      case RESULT_FILL_BINARY_SOURCES -> List.of(RESULT_SLOT, SOURCE, RIGHT_SOURCE);
      case RECORD_GET, VARIANT_TAG_EQ, VARIANT_GET -> List.of(OWNER);
      case ARRAY_GET, SLICE_GET, WORDS_GET, BYTES_GET, UTF8_SCALAR, UTF8_WIDTH ->
          List.of(OWNER, INDEX);
      case UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH -> List.of(SOURCE);
      case SLICE_NEW -> List.of(OWNER, START, LENGTH);
      case WORDS_ALLOC, BYTES_ALLOC, MAP_ALLOC -> List.of(OWNER, CAPACITY);
      case WORDS_SET, BYTES_SET -> List.of(OWNER, INDEX, SOURCE);
      case MAP_PUT -> List.of(OWNER, KEY, SOURCE);
      case MAP_GET, MAP_HAS -> List.of(OWNER, KEY);
      case BUFFER_DROP, REGION_DROP -> List.of(LOCAL);
      case OUTPUT_LENGTH -> List.of(OWNER, LENGTH);
      default -> List.of();
    };
    for (InstructionForm.OperandRole role : reads) {
      int local = Math.toIntExact(instruction.operand(role));
      requireAssignedLocal(owner, instruction, role, pc, assigned, local);
      if (role == RESULT_SLOT) {
        requireAssignedLocal(owner, instruction, role, pc, assigned, local + 1);
      }
    }
  }

  private static void requireAssignedLocal(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc,
      BitSet assigned,
      int local) {
    if (assigned.get(local)) {
      return;
    }
    if (owned(owner.localType(local))) {
      failOperand(
          owner, instruction, role, pc,
          "reads unavailable owned local " + local
              + " after move, drop, return, or call transfer");
    }
    failOperand(owner, instruction, role, pc, "reads uninitialized local " + local);
  }

  private static int writtenLocal(Instruction instruction) {
    return switch (instruction.opcode()) {
      case LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, OWNED_MOVE,
          LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_ROTR32, LOCAL_XOR, LOCAL_EQ, LOCAL_LT,
          RECORD_NEW, RECORD_GET, VARIANT_NEW, VARIANT_TAG_EQ, VARIANT_GET,
          ARRAY_NEW, ARRAY_GET, SLICE_NEW, SLICE_GET, REGION_NEW,
          WORDS_ALLOC, WORDS_GET, BYTES_ALLOC, BYTES_GET,
          UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH, UTF8_SCALAR, UTF8_WIDTH,
          MAP_ALLOC, MAP_GET, MAP_HAS, UTF8_FREEZE, UTF8_BORROW, MAP_BORROW,
          BUFFER_BORROW, REGION_BORROW -> Math.toIntExact(instruction.operand(DESTINATION));
      case LOCAL_LOOP_CHECK -> Math.toIntExact(instruction.operand(ITERATION));
      case CALL_VALUE -> Math.toIntExact(instruction.operand(RESULT));
      default -> -1;
    };
  }

  private static InstructionForm.OperandRole writtenRole(Instruction instruction) {
    return switch (instruction.opcode()) {
      case LOCAL_LOOP_CHECK -> ITERATION;
      case CALL_VALUE -> RESULT;
      default -> DESTINATION;
    };
  }

  private static List<Integer> successors(
      FunctionBody owner, List<Instruction> body, int pc, Instruction instruction) {
    if (instruction.opcode() == Opcode.HALT
        || instruction.opcode() == Opcode.RETURN
        || instruction.opcode() == Opcode.RETURN_VALUE
        || instruction.opcode() == Opcode.RETURN_RESULT_SLOT) {
      return List.of();
    }
    if (instruction.opcode() == Opcode.JUMP) {
      return List.of(Math.toIntExact(instruction.operand(TARGET)));
    }
    if (instruction.opcode() == Opcode.JUMP_IF_ZERO) {
      int next = checkedFallthrough(owner, body, pc);
      return List.of(next, Math.toIntExact(instruction.operand(TARGET)));
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
    FunctionBody target = program.function(verifyReference(
        owner, instruction, FUNCTION, pc, program.functions().size(), "function"));
    var window = verifyLocalWindow(owner, instruction, ARGUMENT_BASE, ARGUMENT_COUNT, pc);
    int base = window.base();
    int count = window.count();
    if (target.returnsValue() != returnsValue
        || target.implicitResultSlot()
        || count != target.parameterCount()) {
      failOperand(
          owner, instruction, ARGUMENT_COUNT, pc,
          "call signature mismatch for " + target.name());
    }
    if (returnsValue) {
      int destination = verifyLocal(owner, instruction, RESULT, pc);
      requireType(owner, instruction, destination, RESULT, target.resultType(), pc);
    }
    for (int argument = 0; argument < count; argument++) {
      if (!owner.localType(base + argument).equals(target.localType(argument))) {
        failOperand(
            owner, instruction, ARGUMENT_BASE, pc,
            "argument " + argument + " type mismatch for " + target.name());
      }
    }
  }

  private static String location(FunctionBody function, int pc) {
    return function.name() + "[" + pc + "]";
  }

  private static void fail(String message) {
    throw new BytecodeException(message);
  }
}
