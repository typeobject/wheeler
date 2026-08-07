//! Parses and measures bounded calls assigned into existing signed locals.

module wheeler.compiler.assignment_call_syntax;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_columns;
import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.identifier_starts;
import wheeler.compiler.source_scalars;

classical class AssignmentCallSyntax {
  /// Classifies one assignment whose right side starts with a helper call.
  public long namedAssignmentCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_OPEN_PAREN) {} else {
      return -1;
    }

    long arity = 0;
    long cursor = statementStart + 4;
    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {
      return sourceKind(arity);
    }

    while (arity < MAX_ASSIGNMENT_CALL_ARGUMENTS) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      if (identifierStart(utf8Scalar(source, tokenStarts[cursor]))) {} else {
        return sourceKind(arity);
      }

      arity += 1;
      cursor += 1;
      if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {
        cursor += 1;
      } else {
        return sourceKind(arity);
      }
    }

    return sourceKind(arity);
  }

  /// Returns one argument token in a call assignment.
  public long assignmentCallArgumentToken(long statementStart, long argument) {
    return statementStart + 4 + argument * 2;
  }

  /// Validates and measures one exact call-assignment source statement.
  public long assignmentCallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    if (tokenKinds[statementStart] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 1]) == PUNCTUATION_ASSIGN) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_OPEN_PAREN) {} else {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    long argument = 0;
    long cursor = statementStart + 4;
    while (argument < arity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      if (tokenKinds[cursor] == 1) {} else {
        return -1;
      }

      cursor += 1;
      argument += 1;
      if (argument < arity) {
        if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {} else {
          return -1;
        }

        cursor += 1;
      }
    }

    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[cursor + 1]) == PUNCTUATION_SEMICOLON) {
      return cursor - statementStart + 2;
    }

    return -1;
  }
}
