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
  private const long EFFECT_BYTES = MAX_CALLABLES * EFFECT_COLUMNS * WORD_BYTES;
  private const long NAME_BUFFERS = 1;
  private const long CLAIM_BUFFERS = 1;

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
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects
  ) {
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableEffects) == MAX_CLOSURE_CALLABLES);
    assert(callableCount < MAX_CLOSURE_CALLABLES - firstCallable + 1);
    long reversible = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long effect = callableEffects[firstCallable + callable];
      if (effect == MEMBER_REV) {
        reversible += 1;
      } else {
        if (effect != 0) {
          return -1;
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
    long reversible = reversibleCallableCount(firstCallable, callableCount, callableEffects);
    if (reversible < 0) {
      return new SourceClassicalCoveragePlan(0, 0, false);
    }

    if (0 < reversible) {
      SourceGeneratedInverseProofPlan inverse = materializeSourceGeneratedInverseProofs(
        source,
        callableCount,
        strings,
        stringBytes,
        stringCount,
        stringStarts,
        stringLengths,
        functionNameIds,
        proofNames,
        proofs
      );
      return new SourceClassicalCoveragePlan(reversible, inverse.proofCount, inverse.valid);
    }

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

    region local = new region(/* bytes= */ EFFECT_BYTES, /* allocations= */ EFFECT_COLUMNS);
    words effects = allocate(local, MAX_CALLABLES);
    long selected = 0;
    while (selected < callableCount) limit MAX_CALLABLES {
      set(effects, selected, callableEffects[firstCallable + selected]);
      selected += 1;
    }

    SourceClassicalProofPlan ordinary = materializeSourceClassicalProofs(
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
      proofNames,
      proofs
    );
    drop(effects);
    drop(local);
    return new SourceClassicalCoveragePlan(0, ordinary.proofCount, ordinary.valid);
  }
}
