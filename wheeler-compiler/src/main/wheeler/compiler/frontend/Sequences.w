//! Resolves bounded statement sequences into compact compiler IR.

module wheeler.compiler.sequences;

import wheeler.compiler.statements;
import wheeler.compiler.tokens;

classical class StatementSequences {
  /// Defines immutable `StatementSequence` values for this module.
  public record StatementSequence(
    long count,
    long[8] opcodes,
    long[8] operands,
    boolean valid
  ) {}

  private long sequenceOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long[8] statementStarts,
    long count,
    long index
  ) {
    if (index < count) {
      return statementOpcode(source, tokenStarts, tokenLengths, statementStarts[index]);
    }

    return -1;
  }

  private long sequenceOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long[8] statementStarts,
    long count,
    long index
  ) {
    if (index < count) {
      return sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        statementStarts[index],
        statementStarts,
        index
      );
    }

    return 0;
  }

  /// Resolves one ordered source sequence without publishing partial results.
  public StatementSequence parseStatementSequence(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long[8] statementStarts,
    long count
  ) {
    long[8] absentOpcodes = new long[8](-1, -1, -1, -1, -1, -1, -1, -1);
    long[8] absentOperands = new long[8](0, 0, 0, 0, 0, 0, 0, 0);
    if (count < 0) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    if (8 < count) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    long firstOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      0
    );
    long secondOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      1
    );
    long thirdOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      2
    );
    long fourthOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      3
    );
    long fifthOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      4
    );
    long sixthOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      5
    );
    long seventhOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      6
    );
    long eighthOpcode = sequenceOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      7
    );
    long[8] opcodes = new long[8](
      firstOpcode,
      secondOpcode,
      thirdOpcode,
      fourthOpcode,
      fifthOpcode,
      sixthOpcode,
      seventhOpcode,
      eighthOpcode
    );

    long[8] operands = new long[8](
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 0),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 1),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 2),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 3),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 4),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 5),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 6),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 7)
    );

    long statement = 0;
    while (statement < count) limit 8 {
      if (sequenceOperandValid(opcodes[statement], operands[statement]) == false) {
        return new StatementSequence(count, opcodes, operands, false);
      }

      statement += 1;
    }

    return new StatementSequence(count, opcodes, operands, true);
  }

  /// Checks that every resolved statement has a reversible global-update inverse.
  public boolean reversibleSequenceValid(StatementSequence sequence) {
    if (sequence.valid == false) {
      return false;
    }

    long statement = 0;
    while (statement < sequence.count) limit 8 {
      long opcode = sequence.opcodes[statement];
      boolean reversible = opcode == STATEMENT_UPDATE_ADD;
      if (opcode == STATEMENT_UPDATE_SUB) {
        reversible = true;
      }

      if (opcode == STATEMENT_UPDATE_XOR) {
        reversible = true;
      }

      if (reversible == false) {
        return false;
      }

      statement += 1;
    }

    return true;
  }
}
