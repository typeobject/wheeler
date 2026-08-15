//! Publishes ordinary or reversible artifacts from completed structured products.

module wheeler.compiler.closure.structured_artifact_directions;

import wheeler.compiler.closure.generated_inverse_products;
import wheeler.compiler.closure.reversible_result_composition;
import wheeler.compiler.closure.reversible_source_product_artifact;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;

classical class StructuredArtifactDirections {
  /// Stages forward products and publishes exactly one selected direction layout.
  public SourceProductArtifactPlan publishStructuredArtifactDirections(
    long callableCount,
    long reversibleCallableCount,
    long stubCount,
    borrow mut words stubParameterStarts,
    borrow mut words stubParameterCounts,
    borrow mut words stubParameterTypes,
    borrow mut words stubResultTypes,
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
    borrow mut words proofNameStarts,
    borrow mut words proofNameLengths,
    borrow mut words proofSubjects,
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

    region publication = new region(/* bytes= */ 32800, /* allocations= */ 2);
    bytes forwardArtifact = allocateBytes(publication, /* length= */ 32768);
    bytes forwardIdentity = allocateBytes(publication, /* length= */ 32);
    SourceProductArtifactPlan forwardResult = publishClassicalSourceModuleArtifactWithStubs(
      callableCount,
      reversibleCallableCount,
      stubCount,
      stubParameterStarts,
      stubParameterCounts,
      stubParameterTypes,
      stubResultTypes,
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
    if (0 < reversibleCallableCount) {
      assert(reversibleCallableCount == callableCount);
      region inverses = new region(/* bytes= */ 263680, /* allocations= */ 2);
      words inverseRows = allocate(inverses, /* length= */ 192);
      bytes inverseCode = allocateBytes(inverses, /* length= */ 262144);
      GeneratedInversePlan inverse = materializeGeneratedInverseCompositionProducts(
        callableCount,
        composedCallables,
        composedCode,
        codeLength,
        inverseRows,
        inverseCode
      );
      assert(inverse.valid);
      result = publishReversibleSourceProductArtifact(
        forwardArtifact,
        forwardResult.length,
        callableCount,
        /* ownershipEventCount= */ 0,
        composedCallables,
        inverseRows,
        inverseCode,
        proofNames,
        proofCount,
        proofNameStarts,
        proofNameLengths,
        proofSubjects,
        output,
        identity
      );
      drop(inverseCode);
      drop(inverseRows);
      drop(inverses);
    } else {
      long artifactByte = 0;
      while (artifactByte < 32768) limit 32768 {
        setByte(output, artifactByte, forwardArtifact[artifactByte]);
        artifactByte += 1;
      }

      long identityByte = 0;
      while (identityByte < 32) limit 32 {
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
