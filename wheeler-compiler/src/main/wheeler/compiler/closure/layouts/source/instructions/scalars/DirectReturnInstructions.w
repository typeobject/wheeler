//! Emits ordinary values and reversible result slots through their distinct instruction owners.

module wheeler.compiler.closure.direct_return_instructions;

import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.direct_statement_publication;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.instruction_forms;
import wheeler.compiler.opcodes;
import wheeler.compiler.result_slot_codegen;

classical class DirectReturnInstructions {
  private const long MAX_FRAME_LOCALS = 256;
  private const long RESULT_INSTRUCTIONS = 2;

  /// Keeps globals out of reversible slots and preflights the complete ordinary or slot extent.
  public DirectScalarExtent writeDirectReturnInstructions(
    DirectScalarRelationProduct relation,
    long reversibleCallableCount,
    borrow mut bytes output,
    long cursor,
    long destination
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    assert(-1 < reversibleCallableCount);
    assert(reversibleCallableCount < DIRECT_FUNCTIONS + 1);
    if (relation.valid == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (
      directScalarTypesValid(
        reversibleCallableCount,
        relation.kind,
        relation.operation,
        relation.leftType,
        relation.rightType
      ) == false
    ) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (reversibleCallableCount == 0) {
      return writeDirectScalarDestination(
        output,
        cursor,
        OPCODE_RETURN_VALUE,
        0,
        relation.kind,
        relation.leftLoadOpcode,
        relation.rightLoadOpcode,
        destination,
        relation.left,
        relation.operation,
        relation.right,
        relation.immediate
      );
    }

    if (relation.leftLoadOpcode != OPCODE_LOCAL_MOVE) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (relation.rightLoadOpcode != OPCODE_LOCAL_MOVE) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (destination < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_FRAME_LOCALS - 1 < destination) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (relation.left < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_FRAME_LOCALS - 1 < relation.left) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    long fillOpcode = OPCODE_RESULT_FILL_SOURCE;
    if (relation.kind == RESULT_RELATION_BINARY) {
      fillOpcode = OPCODE_RESULT_FILL_BINARY;
    } else {
      if (relation.kind == RESULT_RELATION_BINARY_SOURCES) {
        if (relation.right < 0) {
          return new DirectScalarExtent(0, 0, 0, false);
        }

        if (MAX_FRAME_LOCALS - 1 < relation.right) {
          return new DirectScalarExtent(0, 0, 0, false);
        }

        fillOpcode = OPCODE_RESULT_FILL_BINARY_SOURCES;
      } else {
        if (relation.kind != RESULT_RELATION_SOURCE) {
          return new DirectScalarExtent(0, 0, 0, false);
        }
      }
    }

    long operandCount = expectedOperandCount(fillOpcode) + expectedOperandCount(
      OPCODE_RETURN_RESULT_SLOT
    );
    long length = RESULT_INSTRUCTIONS * ENCODING_INSTRUCTION_HEADER_BYTES + operandCount
      * ENCODING_WIDTH_U64;
    if (cursor < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_CODE_BYTES - length < cursor) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    DirectScalarExtent result = new DirectScalarExtent(
      cursor + length,
      RESULT_INSTRUCTIONS,
      1,
      true
    );
    long next = cursor;
    if (relation.kind == RESULT_RELATION_SOURCE) {
      next = writeResultSlotSourceBody(output, cursor, destination, relation.left);
    }

    if (relation.kind == RESULT_RELATION_BINARY) {
      next = writeResultSlotBinaryBody(
        output,
        cursor,
        destination,
        relation.left,
        relation.operation,
        relation.immediate
      );
    }

    if (relation.kind == RESULT_RELATION_BINARY_SOURCES) {
      next = writeResultSlotBinarySourcesBody(
        output,
        cursor,
        destination,
        relation.left,
        relation.operation,
        relation.right
      );
    }

    assert(next == result.next);
    return result;
  }
}
