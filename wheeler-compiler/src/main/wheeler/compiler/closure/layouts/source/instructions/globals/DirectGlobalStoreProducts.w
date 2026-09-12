//! Emits signed root stores from declared destinations and shared scalar value bindings.

module wheeler.compiler.closure.direct_global_store_products;

import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_locations;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectGlobalStoreProducts {
  /// Binds the destination independently of its value and emits a real global store.
  public DirectScalarExtent writeDirectGlobalStore(
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
    borrow mut bytes output,
    long cursor,
    long localBase
  ) {
    if (token < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (tokenCount < token + 4) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (tokenKinds[token] != 1) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    DirectScalarLocation destination = resolveDirectScalarLocation(
      source,
      tokenStarts[token],
      tokenLengths[token],
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (destination.valid == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (destination.loadOpcode != OPCODE_LOCAL_LOAD_GLOBAL) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    DirectScalarRelationProduct value = resolveDirectReturnRelation(
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
      symbolResolved
    );
    if (value.valid == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (directRelationResultType(value.operation, value.leftType) != TYPE_SIGNED) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (
      directReturnTypesValid(0, value.kind, value.operation, value.leftType, value.rightType)
        == false
    ) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    return writeDirectScalarDestination(
      output,
      cursor,
      OPCODE_LOCAL_STORE_GLOBAL,
      destination.operand,
      value.kind,
      value.leftLoadOpcode,
      value.rightLoadOpcode,
      localBase,
      value.left,
      value.operation,
      value.right,
      value.immediate
    );
  }
}
