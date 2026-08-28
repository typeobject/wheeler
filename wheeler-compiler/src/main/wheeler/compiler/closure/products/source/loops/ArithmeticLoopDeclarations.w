//! Resolves focused signed arithmetic declarations inside structured loops.

module wheeler.compiler.closure.arithmetic_loop_declarations;

import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;

classical class ArithmeticLoopDeclarations {
  /// Carries one recognized arithmetic declaration and its logical operands.
  public record ArithmeticLoopDeclaration(
    long opcode,
    long operandKind,
    long operand,
    boolean recognized,
    boolean valid
  ) {}

  /// Resolves checked literal multiplication or two-local addition.
  public ArithmeticLoopDeclaration resolveArithmeticLoopDeclaration(
    borrow utf8 source,
    long token,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    SourceReversibleResultRelation relation = sourceScalarRelation(
      source,
      token,
      semanticCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    boolean multiplication = relation.operation == OPCODE_LOCAL_MUL;
    boolean addition = relation.operation == OPCODE_LOCAL_ADD;
    if (multiplication == false) {
      if (addition == false) {
        return new ArithmeticLoopDeclaration(0, 0, 0, false, false);
      }
    }

    if (multiplication) {
      if (relation.kind != RESULT_RELATION_BINARY) {
        return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
      }
    }

    if (addition) {
      if (relation.kind != RESULT_RELATION_BINARY_SOURCES) {
        return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
      }
    }

    LoopBodyValue left = resolveLoopBodyValue(
      source,
      tokenStarts[relation.leftToken],
      tokenLengths[relation.leftToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (left.valid == false) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        left.local,
        valueCount,
        valueRows,
        semanticCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    if (255 < left.local) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    if (multiplication) {
      return new ArithmeticLoopDeclaration(
        BODY_LONG_MUL_LITERAL_BASE + left.local,
        /* operandKind= */ 0,
        relation.immediate,
        true,
        true
      );
    }

    LoopBodyValue right = resolveLoopBodyValue(
      source,
      tokenStarts[relation.rightToken],
      tokenLengths[relation.rightToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (right.valid == false) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        right.local,
        valueCount,
        valueRows,
        semanticCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    if (255 < right.local) {
      return new ArithmeticLoopDeclaration(0, 0, 0, true, false);
    }

    return new ArithmeticLoopDeclaration(
      BODY_LONG_ADD_LOCAL_BASE + left.local,
      /* operandKind= */ 1,
      right.local,
      true,
      true
    );
  }
}
