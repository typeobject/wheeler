//! Resolves bounded statement sequences into compact compiler IR.

module wheeler.compiler.sequences;

import wheeler.compiler.ir;
import wheeler.compiler.statements;
import wheeler.compiler.tokens;

classical class StatementSequences {
  /// Defines immutable `StatementSequence` values for this module.
  public record StatementSequence(
    long count,
    long[64] opcodes,
    long[64] operands,
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
      return sequenceStatementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        statementStarts[index],
        statementStarts,
        index
      );
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
    long[64] absentOpcodes = emptyStatementOpcodes();
    long[64] absentOperands = emptyStatementOperands();
    if (count < 0) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    if (MAX_MINIMAL_STATEMENTS < count) {
      return new StatementSequence(0, absentOpcodes, absentOperands, false);
    }

    long[64] opcodes = new long[64](
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
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 15),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 16),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 17),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 18),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 19),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 20),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 21),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 22),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 23),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 24),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 25),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 26),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 27),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 28),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 29),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 30),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 31),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 32),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 33),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 34),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 35),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 36),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 37),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 38),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 39),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 40),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 41),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 42),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 43),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 44),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 45),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 46),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 47),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 48),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 49),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 50),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 51),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 52),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 53),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 54),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 55),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 56),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 57),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 58),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 59),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 60),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 61),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 62),
      sequenceOpcode(source, tokenStarts, tokenLengths, statementStarts, count, 63)
    );
    long[64] operands = new long[64](
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
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 15),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 16),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 17),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 18),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 19),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 20),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 21),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 22),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 23),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 24),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 25),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 26),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 27),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 28),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 29),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 30),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 31),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 32),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 33),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 34),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 35),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 36),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 37),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 38),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 39),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 40),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 41),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 42),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 43),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 44),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 45),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 46),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 47),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 48),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 49),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 50),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 51),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 52),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 53),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 54),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 55),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 56),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 57),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 58),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 59),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 60),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 61),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 62),
      sequenceOperand(source, tokenStarts, tokenLengths, statementStarts, count, 63)
    );

    long statement = 0;
    while (statement < count) limit MAX_MINIMAL_STATEMENTS {
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
    while (statement < sequence.count) limit MAX_MINIMAL_STATEMENTS {
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
