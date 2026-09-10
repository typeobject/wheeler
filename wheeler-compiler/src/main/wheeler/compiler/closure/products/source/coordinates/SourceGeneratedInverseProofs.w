//! Applies homogeneous reversible coverage to shared source classical proof products.

module wheeler.compiler.closure.source_generated_inverse_proofs;

import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.proof_rules;
import wheeler.compiler.source_member_modifiers;

classical class SourceGeneratedInverseProofs {
  private const long MAX_CALLABLES = 64;
  private const long MAX_CLOSURE_CALLABLES = 4096;
  private const long NATIVE_WORD_BYTES = 8;
  private const long EMPTY_CONSTANT_ROWS = 1;
  private const long STAGED_WORDS = MAX_CALLABLES + EMPTY_CONSTANT_ROWS + SOURCE_PROOF_ROWS;
  private const long STAGED_BYTES = STAGED_WORDS * NATIVE_WORD_BYTES + SOURCE_PROOF_NAMES;
  private const long STAGED_ALLOCATIONS = 4;
  private const long COVERAGE_COLUMNS = 3;
  /// Sizes copied names and the three homogeneous inverse coordinates.
  public const long SOURCE_INVERSE_ARENA_BYTES = SOURCE_PROOF_NAMES + MAX_SOURCE_PROOFS
    * COVERAGE_COLUMNS * NATIVE_WORD_BYTES;
  /// Counts one copied-name buffer and three coordinate buffers.
  public const long SOURCE_INVERSE_ALLOCATIONS = COVERAGE_COLUMNS + 1;

  /// Reports one complete generated-inverse coverage table.
  public record SourceGeneratedInverseProofPlan(long proofCount, boolean valid) {}

  /// Reports inverse coverage only. Ordinary callers must separately prove source claim absence.
  public record SourceReversibleCoveragePlan(
    long reversibleCallableCount,
    long proofCount,
    boolean valid
  ) {}

  private long structuredReversibleCallableCount(
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects
  ) {
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableEffects) == MAX_CLOSURE_CALLABLES);
    assert(callableCount < MAX_CLOSURE_CALLABLES - firstCallable + 1);
    long reversibleCallableCount = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long effect = callableEffects[firstCallable + callable];
      if (effect == MEMBER_REV) {
        reversibleCallableCount += 1;
      } else {
        if (effect != 0) {
          return -1;
        }
      }

      callable += 1;
    }

    if (0 < reversibleCallableCount) {
      if (reversibleCallableCount != callableCount) {
        return -1;
      }
    }

    return reversibleCallableCount;
  }

  /// Checks homogeneous effects and materializes only reversible coverage.
  /// An ordinary window has no coverage products and still requires member-front claim exclusion.
  public SourceReversibleCoveragePlan materializeSourceReversibleCoverage(
    borrow utf8 source,
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut bytes proofNames,
    borrow mut words proofNameStarts,
    borrow mut words proofNameLengths,
    borrow mut words proofSubjects
  ) {
    long reversibleCount = structuredReversibleCallableCount(
      firstCallable,
      callableCount,
      callableEffects
    );
    if (reversibleCount < 0) {
      return new SourceReversibleCoveragePlan(0, 0, false);
    }

    if (reversibleCount == 0) {
      return new SourceReversibleCoveragePlan(0, 0, true);
    }

    SourceGeneratedInverseProofPlan coverage = materializeSourceGeneratedInverseProofs(
      source,
      callableCount,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      functionNameIds,
      proofNames,
      proofNameStarts,
      proofNameLengths,
      proofSubjects
    );
    return new SourceReversibleCoveragePlan(reversibleCount, coverage.proofCount, coverage.valid);
  }

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
    borrow mut words proofNameStarts,
    borrow mut words proofNameLengths,
    borrow mut words proofSubjects
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(proofNames) == SOURCE_PROOF_NAMES);
    assert(bufferLength(proofNameStarts) == MAX_CALLABLES);
    assert(bufferLength(proofNameLengths) == MAX_CALLABLES);
    assert(bufferLength(proofSubjects) == MAX_CALLABLES);
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
        set(proofNameStarts, proof, rows[proof]);
        set(proofNameLengths, proof, rows[SOURCE_PROOF_LENGTH_ROW + proof]);
        set(proofSubjects, proof, rows[SOURCE_PROOF_SUBJECT_ROW + proof]);
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
