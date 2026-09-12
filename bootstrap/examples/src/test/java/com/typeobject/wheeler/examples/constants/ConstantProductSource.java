package com.typeobject.wheeler.examples.constants;

/** Encodes the zero-or-one unqualified scalar used by structured-body fixtures. */
public final class ConstantProductSource {
  private static final int MAX_CONSTANTS = 1;

  private ConstantProductSource() {}

  /** Expands the explicit product-table slots in one structured-body fixture. */
  public static String expand(String source, int count) {
    return source.replace("CONSTANT_PRODUCT_LIMITS", limits())
        .replace("CONSTANT_PRODUCT_SETUP", setup(count))
        .replace("CONSTANT_PRODUCT_CLEANUP", "drop(proofConstants); drop(constantProducts);");
  }

  private static String limits() {
    return """
        private const long FIXTURE_CONSTANT_CAPACITY = %d;
        private const long FIXTURE_WORD_BYTES = %d;
        private const long FIXTURE_CONSTANT_ROWS = CONSTANT_PRODUCT_HEADER_ROWS
          + FIXTURE_CONSTANT_CAPACITY * CONSTANT_PRODUCT_COLUMNS;
        private const long FIXTURE_CONSTANT_BYTES = FIXTURE_CONSTANT_ROWS * FIXTURE_WORD_BYTES;
        private const long FIXTURE_CONSTANT_BUFFERS = 1;
        """.formatted(MAX_CONSTANTS, Long.BYTES);
  }

  // Copies fixture facts without inferring scope or resolving source expressions.
  private static String setup(int count) {
    if (count < 0 || count > MAX_CONSTANTS) {
      throw new IllegalArgumentException("Unsupported fixture constant count: " + count);
    }
    return """
        region constantProducts = new region(
          /* bytes= */ FIXTURE_CONSTANT_BYTES, /* allocations= */ FIXTURE_CONSTANT_BUFFERS);
        words proofConstants = allocate(constantProducts, FIXTURE_CONSTANT_ROWS);
        set(proofConstants, 0, %d);
        long constant = 0;
        while (constant < %d) limit FIXTURE_CONSTANT_CAPACITY {
          long base = CONSTANT_PRODUCT_HEADER_ROWS + constant * CONSTANT_PRODUCT_COLUMNS;
          set(proofConstants, base + CONSTANT_NAME_START, symbolStarts[constant]);
          set(proofConstants, base + CONSTANT_NAME_LENGTH, symbolLengths[constant]);
          set(proofConstants, base + CONSTANT_TYPE, symbolTypes[constant]);
          set(proofConstants, base + CONSTANT_VALUE, symbolValues[constant]);
          set(proofConstants, base + CONSTANT_RESOLVED, symbolResolved[constant]);
          constant += 1;
        }
        """.formatted(count, count);
  }

}
