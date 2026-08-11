package com.typeobject.wheeler.core.vm;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CONDITION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESCRIPTOR;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.INDEX;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ITERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LENGTH;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OWNER;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OPERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT_SLOT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.START;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TAG;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.ResultBinaryOperation;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.List;

/** Validates one instruction completely before the VM mutates semantic state. */
final class VmPreflight {
  private final Program program;
  private final long[] globals;
  private final Frame frame;
  private final int frameDepth;
  private final OwnedStore owned;
  private final AggregateStore aggregates;
  private final long hostOutputHandle;
  private final Failure failure;

  private VmPreflight(
      Program program,
      long[] globals,
      Frame frame,
      int frameDepth,
      OwnedStore owned,
      AggregateStore aggregates,
      long hostOutputHandle,
      Failure failure) {
    this.program = program;
    this.globals = globals;
    this.frame = frame;
    this.frameDepth = frameDepth;
    this.owned = owned;
    this.aggregates = aggregates;
    this.hostOutputHandle = hostOutputHandle;
    this.failure = failure;
  }

  static void validate(
      Instruction instruction,
      Program program,
      long[] globals,
      Frame frame,
      int frameDepth,
      OwnedStore owned,
      AggregateStore aggregates,
      long hostOutputHandle,
      Failure failure) {
    new VmPreflight(
        program,
        globals,
        frame,
        frameDepth,
        owned,
        aggregates,
        hostOutputHandle,
        failure)
        .validateInstruction(instruction);
  }

  private void validateInstruction(Instruction instruction) {
    try {
      if (OwnedInstructionValidator.handles(instruction.opcode())) {
        OwnedInstructionValidator.validate(instruction, frame, owned);
        return;
      }
      switch (instruction.opcode()) {
        case ADD_CONST -> Math.addExact(
            globals[globalIndex(instruction, GLOBAL)], instruction.operand(IMMEDIATE));
        case SUB_CONST -> Math.subtractExact(
            globals[globalIndex(instruction, GLOBAL)], instruction.operand(IMMEDIATE));
        case LOCAL_ADD -> {
          localIndex(instruction, DESTINATION);
          Math.addExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_SUB -> {
          localIndex(instruction, DESTINATION);
          Math.subtractExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_MUL -> {
          localIndex(instruction, DESTINATION);
          Math.multiplyExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_DIV, LOCAL_MOD -> {
          localIndex(instruction, DESTINATION);
          long dividend = localValue(instruction, LEFT_SOURCE);
          long divisor = localValue(instruction, RIGHT_SOURCE);
          if (divisor == 0) {
            trap("Division by zero");
          }
          if (instruction.opcode() == Opcode.LOCAL_DIV
              && dividend == Long.MIN_VALUE && divisor == -1) {
            trap("Arithmetic overflow in LOCAL_DIV");
          }
        }
        case LOCAL_CONST -> localIndex(instruction, DESTINATION);
        case LOCAL_LOAD_GLOBAL -> {
          localIndex(instruction, DESTINATION);
          globalIndex(instruction, GLOBAL);
        }
        case LOCAL_STORE_GLOBAL -> {
          globalIndex(instruction, GLOBAL);
          localIndex(instruction, SOURCE);
        }
        case LOCAL_MOVE, OWNED_MOVE -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, SOURCE);
        }
        case LOCAL_AND, LOCAL_XOR, LOCAL_EQ, LOCAL_LT -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, LEFT_SOURCE);
          localIndex(instruction, RIGHT_SOURCE);
        }
        case LOCAL_ROTR32 -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, LEFT_SOURCE);
          long amount = localValue(instruction, RIGHT_SOURCE);
          if (amount < 0 || amount > 31) {
            trap("32-bit rotate amount must be between 0 and 31");
          }
        }
        case JUMP -> VmControlChecks.jumpTarget(program, frame, instruction);
        case JUMP_IF_ZERO -> {
          localIndex(instruction, CONDITION);
          VmControlChecks.jumpTarget(program, frame, instruction);
        }
        case LOCAL_LOOP_CHECK -> {
          long iteration = localValue(instruction, ITERATION);
          long limit = localValue(instruction, LIMIT);
          if (iteration < 0 || limit < 0 || iteration >= limit) {
            trap("Loop iteration limit exceeded");
          }
          Math.addExact(iteration, 1);
        }
        case RECORD_NEW -> {
          localIndex(instruction, DESTINATION);
          RecordType type = program.recordType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = frame.local(base + field);
            fields.add(value);
            ValueType fieldType = type.fields().get(field).type();
            if (fieldType.kind() == ValueType.Kind.RECORD
                && VmAggregateChecks.record(aggregates, value).typeId()
                    != fieldType.descriptorId()) {
              trap("Nested record type mismatch");
            }
          }
          if (aggregates.fullForNew(new RecordValue(type.id(), fields))) {
            trap("Record value limit exceeded");
          }
        }
        case RECORD_GET -> {
          localIndex(instruction, DESTINATION);
          RecordValue value = VmAggregateChecks.record(
              aggregates, localValue(instruction, OWNER));
          int field = Math.toIntExact(instruction.operand(INDEX));
          if (field < 0 || field >= value.fields().size()) {
            trap("Record field index out of range");
          }
        }
        case VARIANT_NEW -> {
          localIndex(instruction, DESTINATION);
          var type = program.variantType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int tag = Math.toIntExact(instruction.operand(TAG));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          var variantCase = type.cases().get(tag);
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = frame.local(base + field);
            VmAggregateChecks.validateValue(
                aggregates, variantCase.fields().get(field).type(), value);
            fields.add(value);
          }
          if (aggregates.fullForNew(new VariantValue(type.id(), tag, fields))) {
            trap("Variant value limit exceeded");
          }
        }
        case VARIANT_TAG_EQ -> {
          localIndex(instruction, DESTINATION);
          VariantValue value = VmAggregateChecks.checkedVariant(
              aggregates, program, frame, instruction, OWNER);
          if (instruction.operand(TAG) < 0
              || instruction.operand(TAG) >= program.variantType(value.typeId()).cases().size()) {
            trap("Variant tag out of range");
          }
        }
        case VARIANT_GET -> {
          localIndex(instruction, DESTINATION);
          VariantValue value = VmAggregateChecks.checkedVariant(
              aggregates, program, frame, instruction, OWNER);
          int tag = Math.toIntExact(instruction.operand(TAG));
          int field = Math.toIntExact(instruction.operand(INDEX));
          if (value.tag() != tag || field < 0 || field >= value.fields().size()) {
            trap("Variant payload access mismatch");
          }
        }
        case ARRAY_NEW -> {
          localIndex(instruction, DESTINATION);
          var type = program.arrayType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          List<Long> elements = new ArrayList<>(count);
          for (int element = 0; element < count; element++) {
            long value = frame.local(base + element);
            VmAggregateChecks.validateValue(aggregates, type.elementType(), value);
            elements.add(value);
          }
          if (aggregates.fullForNew(new ArrayValue(type.id(), elements))) {
            trap("Array value limit exceeded");
          }
        }
        case ARRAY_GET -> {
          localIndex(instruction, DESTINATION);
          ArrayValue value = VmAggregateChecks.checkedArray(
              aggregates, program, frame, instruction, OWNER);
          long index = localValue(instruction, INDEX);
          if (index < 0 || index >= value.elements().size()) {
            trap("Array index out of bounds: " + index);
          }
        }
        case SLICE_NEW -> {
          localIndex(instruction, DESTINATION);
          ArrayValue array = VmAggregateChecks.checkedArray(
              aggregates, program, frame, instruction, OWNER);
          long start = localValue(instruction, START);
          long length = localValue(instruction, LENGTH);
          long end = Math.addExact(start, length);
          if (start < 0 || length < 0 || end > array.elements().size()) {
            trap("Slice range is outside its array");
          }
          SliceValue value = new SliceValue(
              Math.toIntExact(instruction.operand(DESCRIPTOR)),
              localValue(instruction, OWNER),
              Math.toIntExact(start),
              Math.toIntExact(length));
          if (aggregates.fullForNew(value)) {
            trap("Slice value limit exceeded");
          }
        }
        case SLICE_GET -> {
          localIndex(instruction, DESTINATION);
          SliceValue value = VmAggregateChecks.checkedSlice(
              aggregates, program, frame, instruction, OWNER);
          long index = localValue(instruction, INDEX);
          if (index < 0 || index >= value.length()) {
            trap("Slice index out of bounds: " + index);
          }
        }
        case OUTPUT_LENGTH -> {
          long handle = localValue(instruction, OWNER);
          long length = localValue(instruction, LENGTH);
          if (handle != hostOutputHandle || length < 0 || length > owned.length(handle)) {
            trap("Invalid host output length: " + length);
          }
        }
        case CALL -> {
          requireCallCapacity();
          program.function(Math.toIntExact(instruction.operand(FUNCTION)));
        }
        case CALL_VALUE, CALL_VOID -> {
          requireCallCapacity();
          FunctionBody target = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
          int base = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
          boolean returnsValue = instruction.opcode() == Opcode.CALL_VALUE;
          if (returnsValue) {
            localIndex(instruction, RESULT);
          }
          if (target.returnsValue() != returnsValue || target.implicitResultSlot()
              || target.parameterCount() != count
              || base < 0 || count < 0 || base > frame.localCount() - count) {
            trap("Argument call signature mismatch for " + target.name());
          }
        }
        case CALL_RESULT_SLOT, UNCALL_RESULT_SLOT -> {
          requireCallCapacity();
          FunctionBody target = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
          int base = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
          int slot = localIndex(instruction, RESULT_SLOT);
          if (!target.implicitResultSlot() || target.parameterCount() != count
              || base < 0 || count < 0 || base > frame.localCount() - count
              || slot >= frame.localCount() - 1) {
            trap("Result slot call signature mismatch for " + target.name());
          }
          long tag = frame.local(slot);
          long payload = frame.local(slot + 1);
          if (instruction.opcode() == Opcode.CALL_RESULT_SLOT) {
            if (tag != 0 || payload != 0) {
              trap("Forward result slot is not vacant");
            }
          } else {
            Instruction inverseTransition = target.inverse().getFirst();
            long expected;
            String relation;
            if (inverseTransition.opcode() == Opcode.RESULT_FILL_CONSTANT) {
              relation = "constant";
              expected = inverseTransition.operand(IMMEDIATE);
            } else if (inverseTransition.opcode() == Opcode.RESULT_FILL_SOURCE
                || inverseTransition.opcode() == Opcode.RESULT_FILL_BINARY
                || inverseTransition.opcode() == Opcode.RESULT_FILL_BINARY_SOURCES) {
              int source = Math.toIntExact(inverseTransition.operand(SOURCE));
              if (source < 0 || source >= count) {
                trap("Inverse result source is outside the argument window");
              }
              long sourceValue = frame.local(base + source);
              if (inverseTransition.opcode() == Opcode.RESULT_FILL_SOURCE) {
                relation = "source";
                expected = sourceValue;
              } else {
                relation = "computed result";
                long right = inverseTransition.opcode() == Opcode.RESULT_FILL_BINARY
                    ? inverseTransition.operand(IMMEDIATE)
                    : resultArgument(base, count, inverseTransition, RIGHT_SOURCE);
                expected = ResultBinaryOperation.apply(
                    inverseTransition.operand(OPERATION), sourceValue, right);
              }
            } else {
              trap("Inverse result slot has no exact fill relation");
              return;
            }
            if (tag != 1 || payload != expected) {
              trap("Inverse result slot does not hold the expected " + relation);
            }
          }
        }
        case UNCALL -> {
          requireCallCapacity();
          FunctionBody function = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
          if (!function.reversible()) {
            trap("Function has no inverse: " + function.name());
          }
        }
        case RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE, RESULT_FILL_BINARY,
            RESULT_FILL_BINARY_SOURCES -> {
          int slot = localIndex(instruction, RESULT_SLOT);
          if (slot >= frame.localCount() - 1) {
            trap("Result slot is outside the frame");
          }
          long expected;
          if (instruction.opcode() == Opcode.RESULT_FILL_CONSTANT) {
            expected = instruction.operand(IMMEDIATE);
          } else {
            expected = localValue(instruction, SOURCE);
            if (instruction.opcode() == Opcode.RESULT_FILL_BINARY) {
              expected = ResultBinaryOperation.apply(
                  instruction.operand(OPERATION), expected, instruction.operand(IMMEDIATE));
            }
            if (instruction.opcode() == Opcode.RESULT_FILL_BINARY_SOURCES) {
              expected = ResultBinaryOperation.apply(
                  instruction.operand(OPERATION),
                  expected,
                  localValue(instruction, RIGHT_SOURCE));
            }
          }
          long tag = frame.local(slot);
          long payload = frame.local(slot + 1);
          if ((!frame.inverse() && (tag != 0 || payload != 0))
              || (frame.inverse() && (tag != 1 || payload != expected))) {
            String relation = instruction.opcode() == Opcode.RESULT_FILL_CONSTANT
                ? "constant"
                : instruction.opcode() == Opcode.RESULT_FILL_SOURCE
                    ? "source"
                    : "computed result";
            trap(frame.inverse()
                ? "Inverse result slot does not hold the expected " + relation
                : "Forward result slot is not vacant");
          }
        }
        case RETURN -> {
          if (frameDepth <= 1 || frame.returnDestination() != -1) {
            trap("Invalid void return");
          }
        }
        case RETURN_VALUE -> {
          localIndex(instruction, RESULT);
          if (frameDepth <= 1 || frame.returnDestination() < 0) {
            trap("Invalid value return");
          }
        }
        case RETURN_RESULT_SLOT -> {
          int slot = localIndex(instruction, RESULT_SLOT);
          if (slot >= frame.localCount() - 1
              || frameDepth <= 1 || frame.returnDestination() < 0) {
            trap("Invalid result slot return");
          }
          long expectedTag = frame.inverse() ? 0 : 1;
          long tag = frame.local(slot);
          long payload = frame.local(slot + 1);
          if (tag != expectedTag || (tag == 0 && payload != 0)) {
            trap("Result slot return state is not canonical");
          }
        }
        case EXPECT_EQ -> VmControlChecks.requireGlobalEqual(
            program, globals, globalIndex(instruction, GLOBAL), instruction.operand(IMMEDIATE));
        case EXPECT_TRUE -> VmControlChecks.requireTrue(
            program, frame, localIndex(instruction, CONDITION));
        case HALT, NOP, XOR_CONST, SWAP, SET_LOGGED, CHECKPOINT, COMMIT -> {
          // The verifier and operand access establish all remaining preconditions.
        }
      }
    } catch (ArithmeticException exception) {
      trap("Arithmetic overflow in " + instruction.opcode());
    }
  }

  private int globalIndex(
      Instruction instruction, InstructionForm.OperandRole role) {
    return VmControlChecks.globalIndex(
        globals.length, Math.toIntExact(instruction.operand(role)));
  }

  private int localIndex(
      Instruction instruction, InstructionForm.OperandRole role) {
    int index = Math.toIntExact(instruction.operand(role));
    if (index < 0 || index >= frame.localCount()) {
      trap("Invalid local index " + index);
    }
    return index;
  }

  private long localValue(
      Instruction instruction, InstructionForm.OperandRole role) {
    return frame.local(localIndex(instruction, role));
  }

  private long resultArgument(
      int base,
      int count,
      Instruction instruction,
      InstructionForm.OperandRole role) {
    int source = Math.toIntExact(instruction.operand(role));
    if (source < 0 || source >= count) {
      trap("Inverse result source is outside the argument window");
    }
    return frame.local(base + source);
  }

  private void requireCallCapacity() {
    if (frameDepth >= VirtualMachine.MAX_CALL_DEPTH) {
      trap("Call depth limit exceeded");
    }
  }

  private void trap(String message) {
    failure.raise(message);
  }

  @FunctionalInterface
  interface Failure {
    void raise(String message);
  }
}
