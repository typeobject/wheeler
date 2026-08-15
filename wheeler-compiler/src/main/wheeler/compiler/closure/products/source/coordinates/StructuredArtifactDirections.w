//! Publishes ordinary or reversible artifacts from completed structured products.

module wheeler.compiler.closure.structured_artifact_directions;

import wheeler.compiler.closure.generated_inverse_products;
import wheeler.compiler.closure.reversible_source_product_artifact;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;

classical class StructuredArtifactDirections {
  private const long MAX_CALLABLES = 64;

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
    borrow byteview composedCode,
    long codeLength,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    region publication = new region(/* bytes= */ 32800, /* allocations= */ 2);
    bytes forwardArtifact = allocateBytes(publication, /* length= */ 32768);
    bytes forwardIdentity = allocateBytes(publication, /* length= */ 32);
    SourceProductArtifactPlan forwardResult = publishClassicalSourceModuleArtifactWithStubs(
      callableCount,
      stubCount,
      stubParameterStarts,
      stubParameterCounts,
      stubParameterTypes,
      stubResultTypes,
      composedCallables,
      parameterCounts,
      functionResultTypes,
      functionNameIds,
      typeCount,
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
      long reversibleCallable = 0;
      while (reversibleCallable < callableCount) limit MAX_CALLABLES {
        assert(functionResultTypes[reversibleCallable] == 0);
        reversibleCallable += 1;
      }

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
      result = publishReversibleVoidSourceProductArtifact(
        forwardArtifact,
        forwardResult.length,
        callableCount,
        /* ownershipEventCount= */ 0,
        composedCallables,
        inverseRows,
        inverseCode,
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
