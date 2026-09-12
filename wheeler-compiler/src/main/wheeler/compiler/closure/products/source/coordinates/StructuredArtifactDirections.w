//! Publishes ordinary or reversible artifacts from completed structured products.

module wheeler.compiler.closure.structured_artifact_directions;

import wheeler.compiler.closure.classical_source_product_artifact;
import wheeler.compiler.closure.generated_inverse_products;
import wheeler.compiler.closure.reversible_result_composition;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;

classical class StructuredArtifactDirections {
  private const long ARTIFACT_BYTES = 32768;
  private const long IDENTITY_BYTES = 32;
  private const long PUBLICATION_BUFFERS = 2;
  private const long PUBLICATION_BYTES = ARTIFACT_BYTES + IDENTITY_BYTES;
  private const long MAX_CALLABLES = 64;
  private const long INVERSE_COLUMNS = 3;
  private const long INVERSE_ROWS = MAX_CALLABLES * INVERSE_COLUMNS;
  private const long CODE_BYTES = 262144;
  private const long WORD_BYTES = 8;
  private const long INVERSE_ARENA_BYTES = INVERSE_ROWS * WORD_BYTES + CODE_BYTES;
  private const long INVERSE_BUFFERS = 2;
  private const long EMPTY_WINDOW = 1;

  /// Stages forward products and publishes exactly one selected direction layout.
  public SourceProductArtifactPlan publishStructuredArtifactDirections(
    long classNameId,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long callableCount,
    long reversibleCallableCount,
    long stubCount,
    borrow mut words stubParameterStarts,
    borrow mut words stubParameterCounts,
    borrow mut words stubParameterTypes,
    borrow mut words stubResultTypes,
    borrow mut words stubEffects,
    borrow mut words composedCallables,
    borrow mut words parameterCounts,
    borrow mut words functionResultTypes,
    borrow mut words functionNameIds,
    long typeCount,
    borrow mut words composedTypes,
    borrow mut bytes composedCode,
    long codeLength,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    long proofCount,
    borrow byteview proofNames,
    borrow mut words proofs,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    long publishedTypeCount = typeCount;
    if (0 < reversibleCallableCount) {
      ReversibleResultCompositionPlan resultComposition
        = materializeReversibleResultCompositionProducts(
        callableCount,
        functionResultTypes,
        composedCallables,
        composedTypes,
        typeCount,
        composedCode,
        codeLength
      );
      assert(resultComposition.valid);
      publishedTypeCount = resultComposition.typeCount;
    }

    region publication = new region(
      /* bytes= */ PUBLICATION_BYTES,
      /* allocations= */ PUBLICATION_BUFFERS
    );
    bytes forwardArtifact = allocateBytes(publication, ARTIFACT_BYTES);
    bytes forwardIdentity = allocateBytes(publication, IDENTITY_BYTES);
    SourceProductArtifactPlan forwardResult = publishClassicalSourceModuleArtifactWithStubs(
      classNameId,
      globalCount,
      globalProductStart,
      globals,
      callableCount,
      reversibleCallableCount,
      stubCount,
      stubParameterStarts,
      stubParameterCounts,
      stubParameterTypes,
      stubResultTypes,
      stubEffects,
      composedCallables,
      parameterCounts,
      functionResultTypes,
      functionNameIds,
      publishedTypeCount,
      composedTypes,
      composedCode,
      codeLength,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      forwardArtifact,
      forwardIdentity
    );
    SourceProductArtifactPlan result = forwardResult;
    boolean rebuild = 0 < proofCount;
    if (0 < reversibleCallableCount) {
      rebuild = true;
    }

    if (rebuild) {
      long inverseRowCapacity = EMPTY_WINDOW;
      long inverseCodeCapacity = EMPTY_WINDOW;
      if (0 < reversibleCallableCount) {
        inverseRowCapacity = INVERSE_ROWS;
        inverseCodeCapacity = CODE_BYTES;
      }

      region inverses = new region(
        /* bytes= */ INVERSE_ARENA_BYTES,
        /* allocations= */ INVERSE_BUFFERS
      );
      words inverseRows = allocate(inverses, inverseRowCapacity);
      bytes inverseCode = allocateBytes(inverses, inverseCodeCapacity);
      if (0 < reversibleCallableCount) {
        assert(reversibleCallableCount == callableCount);
        GeneratedInversePlan inverse = materializeGeneratedInverseCompositionProducts(
          callableCount,
          composedCallables,
          composedCode,
          codeLength,
          inverseRows,
          inverseCode
        );
        assert(inverse.valid);
      }

      result = publishClassicalSourceProductArtifact(
        forwardArtifact,
        forwardResult.length,
        callableCount,
        reversibleCallableCount,
        composedCallables,
        inverseRows,
        inverseCode,
        proofNames,
        proofCount,
        proofs,
        output,
        identity
      );
      drop(inverseCode);
      drop(inverseRows);
      drop(inverses);
    } else {
      long artifactByte = 0;
      while (artifactByte < forwardResult.length) limit ARTIFACT_BYTES {
        setByte(output, artifactByte, forwardArtifact[artifactByte]);
        artifactByte += 1;
      }

      long identityByte = 0;
      while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(identity, identityByte, forwardIdentity[identityByte]);
        identityByte += 1;
      }
    }

    drop(forwardIdentity);
    drop(forwardArtifact);
    drop(publication);
    return result;
  }
}
