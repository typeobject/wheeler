//! Emits canonical zero-local global/literal assertions after complete code-window validation.

module wheeler.compiler.closure.direct_global_literal_assertions;

import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_statement_publication;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;

classical class DirectGlobalLiteralAssertions {
  private const long ASSERTION_BYTES = ENCODING_INSTRUCTION_HEADER_BYTES + INSTRUCTION_FORM_BINARY
    * ENCODING_WIDTH_U64;

  /// Measures an exact global assertion without writing code or reserving locals.
  public DirectScalarExtent measureGlobalLiteralAssertion(long cursor, long global) {
    if (cursor < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_CODE_BYTES - ASSERTION_BYTES < cursor) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (global < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_SOURCE_GLOBALS - 1 < global) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    return new DirectScalarExtent(cursor + ASSERTION_BYTES, 1, 0, true);
  }

  /// Publishes one canonical instruction after complete backing and extent validation.
  public DirectScalarExtent writeGlobalLiteralAssertion(
    borrow mut bytes output,
    long cursor,
    long global,
    long immediate
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    DirectScalarExtent extent = measureGlobalLiteralAssertion(cursor, global);
    if (extent.valid == false) {
      return extent;
    }

    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_EXPECT_EQ,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, global, ENCODING_WIDTH_U64);
    next = writeSignedLittleEndian(output, next, immediate, ENCODING_WIDTH_U64);
    assert(next == extent.next);
    return extent;
  }
}
