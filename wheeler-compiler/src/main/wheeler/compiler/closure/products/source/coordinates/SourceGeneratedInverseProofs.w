//! Applies homogeneous reversible coverage to shared source classical proof products.

module wheeler.compiler.closure.source_generated_inverse_proofs;

import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.proof_rules;
import wheeler.compiler.source_member_modifiers;

classical class SourceGeneratedInverseProofs {
  private const long MAX_CALLABLES = 64;
  private const long NATIVE_WORD_BYTES = 8;
  private const long EMPTY_CONSTANT_ROWS = 1;
  private const long STAGED_WORDS = MAX_CALLABLES + EMPTY_CONSTANT_ROWS + SOURCE_PROOF_ROWS;
  private const long STAGED_BYTES = STAGED_WORDS * NATIVE_WORD_BYTES + SOURCE_PROOF_NAMES;
  private const long STAGED_ALLOCATIONS = 4;

  /// Reports one complete generated-inverse coverage table.
  public record SourceGeneratedInverseProofPlan(long proofCount, boolean valid) {}

  /// Requires exactly one inverse claim per callable for the homogeneous reversible emitter.
  /// The general source product owner also admits repeated subjects and static step claims.
  public SourceGeneratedInverseProofPlan materializeSourceGeneratedInverseProofs(
    borrow utf8 source,
    long callableCount,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut bytes proofNames,
    borrow mut words proofs
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(proofNames) == SOURCE_PROOF_NAMES);
    assert(bufferLength(proofs) == SOURCE_PROOF_ROWS);
    region scratch = new region(/* bytes= */ STAGED_BYTES, /* allocations= */ STAGED_ALLOCATIONS);
    words effects = allocate(scratch, MAX_CALLABLES);
    words constants = allocate(scratch, EMPTY_CONSTANT_ROWS);
    words rows = allocate(scratch, SOURCE_PROOF_ROWS);
    bytes names = allocateBytes(scratch, SOURCE_PROOF_NAMES);
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      set(effects, callable, MEMBER_REV);
      callable += 1;
    }

    SourceClassicalProofPlan plan = materializeSourceClassicalProofs(
      source,
      callableCount,
      effects,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      functionNameIds,
      /* constantNames= */ strings,
      constants,
      names,
      rows
    );
    boolean valid = plan.valid;
    if (plan.proofCount != callableCount) {
      valid = false;
    }

    long proof = 0;
    while (proof < plan.proofCount) limit MAX_SOURCE_PROOFS {
      if (rows[SOURCE_PROOF_RULE_ROW + proof] != PROOF_GENERATED_INVERSE) {
        valid = false;
      }

      long earlier = 0;
      while (earlier < proof) limit MAX_SOURCE_PROOFS {
        if (
          rows[SOURCE_PROOF_SUBJECT_ROW + earlier] == rows[SOURCE_PROOF_SUBJECT_ROW + proof]
        ) {
          valid = false;
        }

        earlier += 1;
      }

      proof += 1;
    }

    long proofCount = 0;
    if (valid) {
      proofCount = plan.proofCount;
      proof = 0;
      while (proof < proofCount) limit MAX_SOURCE_PROOFS {
        long column = 0;
        while (column < SOURCE_PROOF_COLUMNS) limit SOURCE_PROOF_COLUMNS {
          long cell = column * MAX_SOURCE_PROOFS + proof;
          set(proofs, cell, rows[cell]);
          column += 1;
        }

        proof += 1;
      }

      long copied = 0;
      while (copied < plan.nameBytes) limit SOURCE_PROOF_NAMES {
        setByte(proofNames, copied, names[copied]);
        copied += 1;
      }
    }

    drop(names);
    drop(rows);
    drop(constants);
    drop(effects);
    drop(scratch);
    return new SourceGeneratedInverseProofPlan(proofCount, valid);
  }
}
