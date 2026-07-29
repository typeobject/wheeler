//! Resolves typed scalar names through prior locals and class constants.

module wheeler.compiler.scalar_references;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;

classical class ScalarReferences {
  /// Carries either a prior-local index or a substituted scalar literal.
  public record ScalarReference(long value, boolean local, boolean valid) {}

  /// Resolves one typed scalar name with lexical locals taking precedence.
  public ScalarReference resolveScalarReference(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long nameToken,
    boolean expectedSigned
  ) {
    long signedLocal = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      nameToken,
      true
    );
    long booleanLocal = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      nameToken,
      false
    );
    if (-1 < signedLocal) {
      if (-1 < booleanLocal) {
        return new ScalarReference(0, false, false);
      }

      return new ScalarReference(signedLocal, true, expectedSigned);
    }

    if (-1 < booleanLocal) {
      return new ScalarReference(booleanLocal, true, expectedSigned == false);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      nameToken,
      expectedSigned
    );
    return new ScalarReference(constant.value, false, constant.valid);
  }
}
