//! Joins ordinary classical claims with the homogeneous generated-inverse policy.

module wheeler.compiler.closure.source_classical_coverage;

import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.closure.source_generated_inverse_proofs;
import wheeler.compiler.source_member_modifiers;

classical class SourceClassicalCoverage {
  private const long MAX_CALLABLES = 64;
  private const long MAX_CLOSURE_CALLABLES = 4096;
  private const long WORD_BYTES = 8;
  private const long EFFECT_COLUMNS = 1;
  private const long STAGED_WORDS = MAX_CALLABLES * EFFECT_COLUMNS + SOURCE_PROOF_ROWS
    + SOURCE_PROOF_ORIGIN_ROWS;
  private const long STAGED_BYTES = STAGED_WORDS * WORD_BYTES + SOURCE_PROOF_NAMES;
  private const long NAME_BUFFERS = 1;
  private const long CLAIM_BUFFERS = 1;
  private const long ORIGIN_BUFFERS = 1;
  private const long STAGED_BUFFERS = EFFECT_COLUMNS + NAME_BUFFERS + CLAIM_BUFFERS
    + ORIGIN_BUFFERS;

  /// Sizes source-local copied names and the shared five-column claim table.
  public const long SOURCE_CLASSICAL_ARENA_BYTES = SOURCE_PROOF_NAMES + SOURCE_PROOF_ROWS
    * WORD_BYTES;
  /// Counts the copied-name buffer and claim table.
  public const long SOURCE_CLASSICAL_ALLOCATIONS = NAME_BUFFERS + CLAIM_BUFFERS;

  /// Reports bound claims and the distinct generated-inverse callable count.
  public record SourceClassicalCoveragePlan(
    long reversibleCallableCount,
    long proofCount,
    boolean valid
  ) {}

  private long reversibleCallableCount(
    long entryCallable,
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects
  ) {
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-2 < entryCallable);
    assert(entryCallable < callableCount);
    assert(bufferLength(callableEffects) == MAX_CLOSURE_CALLABLES);
    assert(callableCount < MAX_CLOSURE_CALLABLES - firstCallable + 1);
    long reversible = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long effect = callableEffects[firstCallable + callable];
      if (callable == entryCallable) {
        if (effect != MEMBER_ENTRY) {
          return -1;
        }
      } else {
        if (effect == MEMBER_REV) {
          reversible += 1;
        } else {
          if (effect != 0) {
            return -1;
          }
        }
      }

      callable += 1;
    }

    if (0 < reversible) {
      if (reversible != callableCount) {
        return -1;
      }
    }

    return reversible;
  }

  /// Binds ordinary claims from complete scoped constants or applies inverse coverage.
  /// Claim-free ordinary modules reuse empty private scratch without new owned buffers.
  /// Effects: clears selected private scratch and publishes only a complete claim batch.
  public SourceClassicalCoveragePlan materializeSourceClassicalCoverage(
    long entryCallable,
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
    borrow byteview constantNames,
    borrow mut words constants,
    borrow mut words scratchKinds,
    borrow mut words scratchStarts,
    borrow mut words scratchLengths,
    borrow mut words scratchModule,
    borrow mut bytes proofNames,
    borrow mut words proofs
  ) {
    long reversible = reversibleCallableCount(
      entryCallable,
      firstCallable,
      callableCount,
      callableEffects
    );
    if (reversible < 0) {
      return new SourceClassicalCoveragePlan(0, 0, false);
    }

    assert(bufferLength(proofNames) == SOURCE_PROOF_NAMES);
    assert(bufferLength(proofs) == SOURCE_PROOF_ROWS);
    if (reversible == 0) {
      if (
        sourceClassicalClaimsAbsent(
          source,
          scratchKinds,
          scratchStarts,
          scratchLengths,
          scratchModule
        )
      ) {
        return new SourceClassicalCoveragePlan(0, 0, true);
      }
    }

    region local = new region(/* bytes= */ STAGED_BYTES, /* allocations= */ STAGED_BUFFERS);
    words effects = allocate(local, MAX_CALLABLES);
    words stagedProofs = allocate(local, SOURCE_PROOF_ROWS);
    words origins = allocate(local, SOURCE_PROOF_ORIGIN_ROWS);
    bytes names = allocateBytes(local, SOURCE_PROOF_NAMES);
    long selected = 0;
    while (selected < callableCount) limit MAX_CALLABLES {
      set(effects, selected, callableEffects[firstCallable + selected]);
      selected += 1;
    }

    SourceClassicalProofPlan bound = materializeSourceClassicalProofs(
      source,
      callableCount,
      effects,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      functionNameIds,
      constantNames,
      constants,
      names,
      stagedProofs,
      origins
    );
    boolean valid = bound.valid;
    if (0 < reversible) {
      if (
        generatedInverseCoverageValid(callableCount, bound.proofCount, stagedProofs) == false
      ) {
        valid = false;
      }
    }

    long proofCount = 0;
    if (valid) {
      proofCount = bound.proofCount;
    }

    SourceClassicalCoveragePlan result = new SourceClassicalCoveragePlan(
      reversible,
      proofCount,
      valid
    );
    if (valid) {
      long column = 0;
      while (column < SOURCE_PROOF_COLUMNS) limit SOURCE_PROOF_COLUMNS {
        long proof = 0;
        while (proof < proofCount) limit MAX_SOURCE_PROOFS {
          long cell = column * MAX_SOURCE_PROOFS + proof;
          set(proofs, cell, stagedProofs[cell]);
          proof += 1;
        }

        column += 1;
      }

      long copiedName = 0;
      while (copiedName < bound.nameBytes) limit SOURCE_PROOF_NAMES {
        setByte(proofNames, copiedName, names[copiedName]);
        copiedName += 1;
      }
    }

    drop(names);
    drop(origins);
    drop(stagedProofs);
    drop(effects);
    drop(local);
    return result;
  }
}
