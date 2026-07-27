//! Resolves bounded statement sequences into compact compiler IR.

module wheeler.compiler.sequences;

import wheeler.compiler.statements;
import wheeler.compiler.tokens;

classical class StatementSequences {
  /// Defines immutable `StatementSequence` values for this module.
  public record StatementSequence(
    long count,
    long[16] opcodes,
    long[16] operands,
    boolean valid
  ) {}

  private long sequenceOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
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
    borrow mut words statementStarts,
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
    borrow mut words statementStarts,
    long count
  ) {
    long[16] absentOpcodes = new long[16](
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    );
    long[16] absentOperands = new long[16](
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    );
    if (count < 0) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    if (16 < count) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    long[16] opcodes = new long[16](
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 0),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 1),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 2),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 3),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 4),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 5),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 6),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 7),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 8),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 9),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 10),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 11),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 12),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 13),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 14),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 15)
    );
    long[16] operands = new long[16](
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 0),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 1),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 2),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 3),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 4),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 5),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 6),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 7),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 8),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 9),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 10),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 11),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 12),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 13),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 14),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 15)
    );

    long statement = 0;
    while (statement < count) limit 16 {
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
    while (statement < sequence.count) limit 16 {
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
