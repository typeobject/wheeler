//! Lowers root Boolean assertions through shared scalar locations and atomic type/code windows.

module wheeler.compiler.closure.direct_assertion_products;

import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.direct_statement_publication;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.type_codes;

classical class DirectAssertionProducts {
  /// Reports complete instruction and type extents, or an unchanged rejected batch.
  public record DirectAssertionProduct(
    long next,
    long instructionCount,
    long typeCount,
    boolean valid
  ) {}

  private DirectAssertionProduct invalidAssertion() {
    return new DirectAssertionProduct(0, 0, 0, false);
  }

  /// Validates syntax, types, locations, and complete backing before the first caller write.
  public DirectAssertionProduct writeDirectAssertion(
    borrow utf8 source,
    borrow byteview symbolNames,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long moduleOwner,
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long valueCount,
    borrow mut words valueRows,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words typeRows,
    long typeCount,
    borrow mut bytes output,
    long cursor,
    long localBase
  ) {
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (owner < 0) {
      return invalidAssertion();
    }

    if (DIRECT_FUNCTIONS - 1 < owner) {
      return invalidAssertion();
    }

    if (typeCount < 0) {
      return invalidAssertion();
    }

    SourceReversibleResultRelation syntax = sourceAssertionRelation(
      source,
      token,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    if (syntax.valid == false) {
      return invalidAssertion();
    }

    DirectScalarRelationProduct value = resolveDirectScalarValue(
      source,
      symbolNames,
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      token + 2,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      moduleOwner,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved,
      PUNCTUATION_CLOSE_PAREN
    );
    if (value.valid == false) {
      return invalidAssertion();
    }

    if (directRelationResultType(value.operation, value.leftType) != TYPE_BOOLEAN) {
      return invalidAssertion();
    }

    if (
      directScalarTypesValid(
        /* reversibleCallableCount= */ 0,
        value.kind,
        value.operation,
        value.leftType,
        value.rightType
      ) == false
    ) {
      return invalidAssertion();
    }

    DirectScalarExtent extent = measureDirectScalarDestination(
      cursor,
      OPCODE_EXPECT_TRUE,
      /* destinationOperand= */ 0,
      value.kind,
      value.leftLoadOpcode,
      value.rightLoadOpcode,
      localBase,
      value.left,
      value.operation,
      value.right
    );
    if (extent.valid == false) {
      return invalidAssertion();
    }

    if (MAX_STATEMENTS - extent.localCount < typeCount) {
      return invalidAssertion();
    }

    if (extent.localCount != scalarRelationValueWidth(syntax.kind)) {
      return invalidAssertion();
    }

    DirectAssertionProduct result = new DirectAssertionProduct(
      extent.next,
      extent.instructionCount,
      typeCount + extent.localCount,
      true
    );
    DirectScalarExtent written = writeDirectScalarDestination(
      output,
      cursor,
      OPCODE_EXPECT_TRUE,
      /* destinationOperand= */ 0,
      value.kind,
      value.leftLoadOpcode,
      value.rightLoadOpcode,
      localBase,
      value.left,
      value.operation,
      value.right,
      value.immediate
    );
    assert(written.valid);
    assert(written.next == extent.next);
    long local = 0;
    while (local < extent.localCount) limit SCALAR_BINARY_VALUE_LOCALS {
      long type = TYPE_BOOLEAN;
      if (local < extent.localCount - 1) {
        long sourceType = value.leftType;
        if (local == 1) {
          sourceType = value.rightType;
        }

        type = directRelationResultType(/* operation= */ 0, sourceType);
      }

      set(typeRows, typeCount + local, owner);
      set(typeRows, MAX_STATEMENTS + typeCount + local, localBase + local);
      set(typeRows, MAX_STATEMENTS * 2 + typeCount + local, type);
      local += 1;
    }

    return result;
  }
}
