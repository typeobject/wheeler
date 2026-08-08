//! Resolves exact forwarded scalar values from completed direct dependency products.

module wheeler.compiler.closure.imported_constant_values;

import wheeler.compiler.constant_declarations;
import wheeler.compiler.constant_expressions;

classical class ImportedConstantValues {
  private const long MODULE_SYMBOL_SIGNED = 1;

  /// Resolves one exact unqualified expression token from direct public products.
  public ExpressionResolution directImportedResolution(
    borrow byteview archive,
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long expressionStart,
    long expressionEnd,
    long expectedType,
    long firstImport,
    long directImportCount,
    borrow mut words edgeTargets,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved
  ) {
    if (expressionStart + 1 == expressionEnd) {} else {
      return new ExpressionResolution(0, false, false, true);
    }

    long selectedValue = 0;
    long selectedType = 0;
    long selectedResolved = 0;
    long candidates = 0;
    long rank = 0;
    while (rank < directImportCount) limit 64 {
      long dependency = edgeTargets[firstImport + rank];
      if (-1 < dependency) {
        long first = moduleFirstSymbols[dependency];
        long count = moduleSymbolCounts[dependency];
        long offset = 0;
        while (offset < count) limit MAX_CLASS_CONSTANTS {
          long symbol = first + offset;
          if (symbolVisibilities[symbol] == 1) {
            long nameLength = symbolLengths[symbol];
            if (nameLength == tokenLengths[expressionStart]) {
              boolean same = true;
              long nameByte = 0;
              while (nameByte < nameLength) limit 256 {
                if (
                  archive[symbolStarts[symbol] + nameByte] == utf8Scalar(
                    source,
                    tokenStarts[expressionStart] + nameByte
                  )
                ) {} else {
                  same = false;
                }

                nameByte += 1;
              }

              if (same) {
                candidates += 1;
                selectedValue = symbolValues[symbol];
                selectedType = symbolTypes[symbol];
                selectedResolved = symbolResolved[symbol];
              }
            }
          }

          offset += 1;
        }
      }

      rank += 1;
    }

    if (candidates == 1) {
      if (selectedResolved == 1) {
        if (selectedType == expectedType) {
          return new ExpressionResolution(
            selectedValue,
            true,
            selectedType == MODULE_SYMBOL_SIGNED,
            true
          );
        }
      }

      return new ExpressionResolution(0, true, false, false);
    }

    if (candidates == 0) {
      return new ExpressionResolution(0, false, false, true);
    }

    return new ExpressionResolution(0, true, false, false);
  }
}
