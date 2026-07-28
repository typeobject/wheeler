package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;

/** Resolves and type-checks aggregate handles used by VM transitions. */
final class VmAggregateChecks {
  private VmAggregateChecks() {}

  static RecordValue record(AggregateStore aggregates, long handle) {
    return aggregates.record(handle);
  }

  static VariantValue variant(AggregateStore aggregates, long handle) {
    return aggregates.variant(handle);
  }

  static VariantValue checkedVariant(
      AggregateStore aggregates,
      Program program,
      Frame frame,
      Instruction instruction,
      InstructionForm.OperandRole role) {
    int source = Math.toIntExact(instruction.operand(role));
    VariantValue value = variant(aggregates, frame.local(source));
    ValueType type = program.function(frame.functionId()).localType(source);
    if (type.kind() != ValueType.Kind.VARIANT || value.typeId() != type.descriptorId()) {
      throw new VmTrap("Variant handle type mismatch");
    }
    return value;
  }

  static void validateValue(AggregateStore aggregates, ValueType type, long value) {
    if (type.kind() == ValueType.Kind.RECORD
        && record(aggregates, value).typeId() != type.descriptorId()) {
      throw new VmTrap("Nested record type mismatch");
    }
    if (type.kind() == ValueType.Kind.VARIANT
        && variant(aggregates, value).typeId() != type.descriptorId()) {
      throw new VmTrap("Nested variant type mismatch");
    }
    if (type.kind() == ValueType.Kind.ARRAY
        && array(aggregates, value).typeId() != type.descriptorId()) {
      throw new VmTrap("Nested array type mismatch");
    }
  }

  static ArrayValue array(AggregateStore aggregates, long handle) {
    return aggregates.array(handle);
  }

  static ArrayValue checkedArray(
      AggregateStore aggregates,
      Program program,
      Frame frame,
      Instruction instruction,
      InstructionForm.OperandRole role) {
    int source = Math.toIntExact(instruction.operand(role));
    ArrayValue value = array(aggregates, frame.local(source));
    ValueType type = program.function(frame.functionId()).localType(source);
    if (type.kind() != ValueType.Kind.ARRAY || value.typeId() != type.descriptorId()) {
      throw new VmTrap("Array handle type mismatch");
    }
    return value;
  }

  static SliceValue slice(AggregateStore aggregates, long handle) {
    return aggregates.slice(handle);
  }

  static SliceValue checkedSlice(
      AggregateStore aggregates,
      Program program,
      Frame frame,
      Instruction instruction,
      InstructionForm.OperandRole role) {
    int source = Math.toIntExact(instruction.operand(role));
    SliceValue value = slice(aggregates, frame.local(source));
    ValueType type = program.function(frame.functionId()).localType(source);
    if (type.kind() != ValueType.Kind.SLICE || value.typeId() != type.descriptorId()) {
      throw new VmTrap("Slice handle type mismatch");
    }
    return value;
  }
}
