//! Resolves bounded scalar assignments and checked updates.

module wheeler.compiler.mutation_resolution;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.resolved_local_assignments;
import wheeler.compiler.resolved_local_updates;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.scalar_references;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class MutationResolution {
  /// Carries an optional substituted mutation operand without a scalar sentinel.
  public record MutationOperand(long value, boolean applies, boolean valid) {}

  private boolean globalTarget(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (0 < tokenLengths[COMPILER_GLOBAL_NAME_TOKEN]) {
      return sameTokenText(
        source,
        tokenStarts,
        tokenLengths,
        COMPILER_GLOBAL_NAME_TOKEN,
        statementStart
      );
    }

    return false;
  }

  private long literalUpdateOpcode(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return STATEMENT_UPDATE_ADD;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return STATEMENT_UPDATE_SUB;
    }

    if (opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED) {
      return STATEMENT_UPDATE_XOR;
    }

    return opcode;
  }

  private long localUpdateBase(long opcode, boolean namedSource) {
    long literalOpcode = literalUpdateOpcode(opcode);
    long base = STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
    if (namedSource) {
      base = STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE;
    }

    if (literalOpcode == STATEMENT_UPDATE_SUB) {
      base = STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
      if (namedSource) {
        base = STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE;
      }
    }

    if (literalOpcode == STATEMENT_UPDATE_XOR) {
      base = STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
      if (namedSource) {
        base = STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE;
      }
    }

    return base;
  }

  /// Resolves a class constant selected as one mutation's literal operand.
  public MutationOperand resolveMutationOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long sourceOpcode,
    long opcode
  ) {
    if (sourceOpcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      boolean literalAssignment = opcode == STATEMENT_ASSIGN;
      if (resolvedLocalAssignment(opcode)) {
        literalAssignment = resolvedLocalAssignmentNamed(opcode) == false;
      }

      if (literalAssignment) {
        long assignmentHash = tokenHash(source, tokenStarts, tokenLengths, statementStart + 2);
        if (resolvedLocalAssignmentBoolean(opcode)) {
          if (booleanTokenHash(assignmentHash)) {
            return new MutationOperand(0, false, true);
          }
        }

        ConstantResolution assignmentConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 2,
          resolvedLocalAssignmentBoolean(opcode) == false
        );
        return new MutationOperand(assignmentConstant.value, true, assignmentConstant.valid);
      }
    }

    boolean namedUpdateSource = sourceOpcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED;
    if (sourceOpcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      namedUpdateSource = true;
    }

    if (sourceOpcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED) {
      namedUpdateSource = true;
    }

    if (namedUpdateSource) {
      boolean literalUpdate = opcode == STATEMENT_UPDATE_ADD;
      if (opcode == STATEMENT_UPDATE_SUB) {
        literalUpdate = true;
      }

      if (opcode == STATEMENT_UPDATE_XOR) {
        literalUpdate = true;
      }

      if (resolvedLocalUpdate(opcode)) {
        literalUpdate = resolvedLocalUpdateNamed(opcode) == false;
      }

      if (literalUpdate) {
        ConstantResolution updateConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 3,
          true
        );
        return new MutationOperand(updateConstant.value, true, updateConstant.valid);
      }
    }

    return new MutationOperand(0, false, true);
  }

  /// Resolves one scalar assignment target and source form.
  public long resolveAssignmentOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    long signedTarget = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      true
    );
    long booleanTarget = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      false
    );
    boolean stateTarget = globalTarget(source, tokenStarts, tokenLengths, statementStart);
    if (-1 < signedTarget) {
      if (-1 < booleanTarget) {
        return -1;
      }

      if (stateTarget) {
        return -1;
      }

      if (opcode == STATEMENT_ASSIGN) {
        return STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE + signedTarget;
      }

      ScalarReference signedSource = resolveScalarReference(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (signedSource.valid == false) {
        return -1;
      }

      if (signedSource.local) {
        return STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + signedTarget;
      }

      return STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE + signedTarget;
    }

    if (-1 < booleanTarget) {
      if (stateTarget) {
        return -1;
      }

      long assignmentRightHash = tokenHash(
        source,
        tokenStarts,
        tokenLengths,
        statementStart + 2
      );
      if (booleanTokenHash(assignmentRightHash)) {
        return STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE + booleanTarget;
      }

      ScalarReference booleanSource = resolveScalarReference(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
      if (booleanSource.valid == false) {
        return -1;
      }

      if (booleanSource.local) {
        return STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + booleanTarget;
      }

      return STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE + booleanTarget;
    }

    if (stateTarget == false) {
      return -1;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return opcode;
    }

    ScalarReference globalSource = resolveScalarReference(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2,
      true
    );
    if (globalSource.valid == false) {
      return -1;
    }

    if (globalSource.local) {
      return STATEMENT_ASSIGN_LOCAL_NAMED;
    }

    return STATEMENT_ASSIGN;
  }

  /// Resolves one checked signed update target and source form.
  public long resolveUpdateOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    long target = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      true
    );
    boolean stateTarget = globalTarget(source, tokenStarts, tokenLengths, statementStart);
    boolean namedSource = opcode != literalUpdateOpcode(opcode);
    ScalarReference sourceReference = new ScalarReference(0, false, true);
    if (namedSource) {
      sourceReference = resolveScalarReference(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (sourceReference.valid == false) {
        return -1;
      }
    }

    if (-1 < target) {
      if (stateTarget) {
        return -1;
      }

      return localUpdateBase(opcode, sourceReference.local) + target;
    }

    if (stateTarget == false) {
      return -1;
    }

    if (sourceReference.local) {
      return opcode;
    }

    return literalUpdateOpcode(opcode);
  }
}
