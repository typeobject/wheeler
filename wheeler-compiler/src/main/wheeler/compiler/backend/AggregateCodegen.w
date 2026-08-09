//! Emits canonical aggregate construction and projection instructions.

module wheeler.compiler.aggregate_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.storage_opcodes;

classical class AggregateCodegen {
  private const long U64 = 8;

  private long writeOperand(borrow mut bytes output, long cursor, long operand) {
    assert(-1 < operand);
    return writeUnsignedLittleEndian(output, cursor, operand, U64);
  }

  private long writeThree(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long first,
    long second,
    long third
  ) {
    assert(cursor < bufferLength(output) - 31);
    assert(-1 < first);
    assert(-1 < second);
    assert(-1 < third);
    cursor = writeInstructionHeader(output, cursor, opcode, /* operandCount= */ 3);
    cursor = writeOperand(output, cursor, first);
    cursor = writeOperand(output, cursor, second);
    return writeOperand(output, cursor, third);
  }

  private long writeFour(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long first,
    long second,
    long third,
    long fourth
  ) {
    assert(cursor < bufferLength(output) - 39);
    assert(-1 < first);
    assert(-1 < second);
    assert(-1 < third);
    assert(-1 < fourth);
    cursor = writeInstructionHeader(output, cursor, opcode, /* operandCount= */ 4);
    cursor = writeOperand(output, cursor, first);
    cursor = writeOperand(output, cursor, second);
    cursor = writeOperand(output, cursor, third);
    return writeOperand(output, cursor, fourth);
  }

  private long writeFive(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long first,
    long second,
    long third,
    long fourth,
    long fifth
  ) {
    assert(cursor < bufferLength(output) - 47);
    assert(-1 < first);
    assert(-1 < second);
    assert(-1 < third);
    assert(-1 < fourth);
    assert(-1 < fifth);
    cursor = writeInstructionHeader(output, cursor, opcode, /* operandCount= */ 5);
    cursor = writeOperand(output, cursor, first);
    cursor = writeOperand(output, cursor, second);
    cursor = writeOperand(output, cursor, third);
    cursor = writeOperand(output, cursor, fourth);
    return writeOperand(output, cursor, fifth);
  }

  /// Emits one canonical record construction instruction.
  public long writeRecordConstruction(
    borrow mut bytes output,
    long cursor,
    long destination,
    long descriptor,
    long elementBase,
    long elementCount
  ) {
    return writeFour(
      output,
      cursor,
      OPCODE_RECORD_NEW,
      destination,
      descriptor,
      elementBase,
      elementCount
    );
  }

  /// Emits one canonical record field projection instruction.
  public long writeRecordProjection(
    borrow mut bytes output,
    long cursor,
    long destination,
    long owner,
    long index
  ) {
    return writeThree(output, cursor, OPCODE_RECORD_GET, destination, owner, index);
  }

  /// Emits one canonical variant construction instruction.
  public long writeVariantConstruction(
    borrow mut bytes output,
    long cursor,
    long destination,
    long descriptor,
    long tag,
    long elementBase,
    long elementCount
  ) {
    return writeFive(
      output,
      cursor,
      OPCODE_VARIANT_NEW,
      destination,
      descriptor,
      tag,
      elementBase,
      elementCount
    );
  }

  /// Emits one canonical variant case test instruction.
  public long writeVariantCaseTest(
    borrow mut bytes output,
    long cursor,
    long destination,
    long owner,
    long tag
  ) {
    return writeThree(output, cursor, OPCODE_VARIANT_TAG_EQ, destination, owner, tag);
  }

  /// Emits one canonical variant payload projection instruction.
  public long writeVariantProjection(
    borrow mut bytes output,
    long cursor,
    long destination,
    long owner,
    long tag,
    long index
  ) {
    return writeFour(output, cursor, OPCODE_VARIANT_GET, destination, owner, tag, index);
  }

  /// Emits one canonical fixed-array construction instruction.
  public long writeArrayConstruction(
    borrow mut bytes output,
    long cursor,
    long destination,
    long descriptor,
    long elementBase,
    long elementCount
  ) {
    return writeFour(
      output,
      cursor,
      OPCODE_ARRAY_NEW,
      destination,
      descriptor,
      elementBase,
      elementCount
    );
  }

  /// Emits one canonical fixed-array element projection instruction.
  public long writeArrayProjection(
    borrow mut bytes output,
    long cursor,
    long destination,
    long owner,
    long index
  ) {
    return writeThree(output, cursor, OPCODE_ARRAY_GET, destination, owner, index);
  }

  /// Emits one canonical slice construction instruction.
  public long writeSliceConstruction(
    borrow mut bytes output,
    long cursor,
    long destination,
    long descriptor,
    long owner,
    long start,
    long length
  ) {
    return writeFive(
      output,
      cursor,
      OPCODE_SLICE_NEW,
      destination,
      descriptor,
      owner,
      start,
      length
    );
  }

  /// Emits one canonical slice element projection instruction.
  public long writeSliceProjection(
    borrow mut bytes output,
    long cursor,
    long destination,
    long owner,
    long index
  ) {
    return writeThree(output, cursor, OPCODE_SLICE_GET, destination, owner, index);
  }
}
