//! Resolves one expression token from a packed direct-import scalar product view.

module wheeler.compiler.product_constant_lookup;

import wheeler.compiler.constant_product_schema;

classical class ProductConstantLookup {
  /// Carries one imported product lookup without a value sentinel.
  public record ProductConstantResolution(
    long value,
    boolean found,
    boolean signed,
    boolean valid
  ) {}

  /// Carries one qualified product expression and its first unread token.
  public record ProductConstantExpression(
    long value,
    long next,
    boolean found,
    boolean signed,
    boolean valid
  ) {}

  private boolean sameName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    borrow byteview importedNames,
    long importedStart,
    long importedLength
  ) {
    if (tokenLengths[token] == importedLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < importedLength) limit MAX_CONSTANT_NAME_BYTES {
      if (
        utf8Scalar(source, tokenStarts[token] + cursor) == importedNames[importedStart + cursor]
      ) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean identifierToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long cursor = 0;
    while (cursor < tokenLengths[token]) limit MAX_CONSTANT_NAME_BYTES {
      long scalar = utf8Scalar(source, tokenStarts[token] + cursor);
      boolean valid = scalar == 95;
      if (64 < scalar) {
        if (scalar < 91) {
          valid = true;
        }
      }

      if (96 < scalar) {
        if (scalar < 123) {
          valid = true;
        }
      }

      if (0 < cursor) {
        if (47 < scalar) {
          if (scalar < 58) {
            valid = true;
          }
        }
      }

      if (valid) {} else {
        return false;
      }

      cursor += 1;
    }

    return 0 < cursor;
  }

  private boolean sameImportedRange(
    borrow utf8 source,
    long sourceStart,
    long sourceLength,
    borrow byteview importedNames,
    long importedStart,
    long importedLength
  ) {
    if (sourceLength == importedLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < sourceLength) limit 256 {
      if (
        utf8Scalar(source, sourceStart + cursor) == importedNames[importedStart + cursor]
      ) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  /// Resolves one exact `module::name` product expression.
  public ProductConstantExpression lookupQualifiedProductConstant(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long start,
    long end,
    borrow byteview importedNames,
    borrow mut words importedRows
  ) {
    if (identifierToken(source, tokenStarts, tokenLengths, start)) {} else {
      return new ProductConstantExpression(0, start, false, false, true);
    }

    long cursor = start + 1;
    long priorEnd = tokenStarts[start] + tokenLengths[start];
    long moduleEnd = -1;
    long symbolToken = -1;
    boolean expectName = false;
    while (cursor + 2 < end) limit 128 {
      if (expectName) {
        if (identifierToken(source, tokenStarts, tokenLengths, cursor)) {} else {
          return new ProductConstantExpression(0, start, false, false, true);
        }

        if (tokenStarts[cursor] == priorEnd + 1) {} else {
          return new ProductConstantExpression(0, start, false, false, true);
        }

        priorEnd = tokenStarts[cursor] + tokenLengths[cursor];
        expectName = false;
        cursor += 1;
      } else {
        long scalar = utf8Scalar(source, tokenStarts[cursor]);
        if (scalar == 46) {
          if (tokenStarts[cursor] == priorEnd) {} else {
            return new ProductConstantExpression(0, start, false, false, true);
          }

          expectName = true;
          cursor += 1;
        } else {
          if (scalar == 58) {
            if (tokenStarts[cursor] == priorEnd) {
              if (utf8Scalar(source, tokenStarts[cursor + 1]) == 58) {
                if (tokenStarts[cursor + 1] == tokenStarts[cursor] + 1) {
                  if (identifierToken(source, tokenStarts, tokenLengths, cursor + 2)) {
                    moduleEnd = tokenStarts[cursor];
                    symbolToken = cursor + 2;
                  }
                }
              }
            }
          }

          break;
        }
      }
    }

    if (-1 < symbolToken) {} else {
      return new ProductConstantExpression(0, start, false, false, true);
    }

    long count = importedRows[0];
    long candidates = 0;
    long selectedType = 0;
    long selectedValue = 0;
    long selectedResolved = 0;
    long row = 0;
    while (row < count) limit MAX_CONSTANT_PRODUCTS {
      long base = CONSTANT_PRODUCT_HEADER_ROWS + row * CONSTANT_PRODUCT_COLUMNS;
      boolean moduleMatches = sameImportedRange(
        source,
        tokenStarts[start],
        moduleEnd - tokenStarts[start],
        importedNames,
        importedRows[base + CONSTANT_MODULE_START],
        importedRows[base + CONSTANT_MODULE_LENGTH]
      );
      if (moduleMatches) {
        if (
          sameName(
            source,
            tokenStarts,
            tokenLengths,
            symbolToken,
            importedNames,
            importedRows[base + CONSTANT_NAME_START],
            importedRows[base + CONSTANT_NAME_LENGTH]
          )
        ) {
          candidates += 1;
          selectedType = importedRows[base + CONSTANT_TYPE];
          selectedValue = importedRows[base + CONSTANT_VALUE];
          selectedResolved = importedRows[base + CONSTANT_RESOLVED];
        }
      }

      row += 1;
    }

    if (candidates == 1) {
      if (selectedResolved == 1) {
        return new ProductConstantExpression(
          selectedValue,
          symbolToken + 1,
          true,
          selectedType == CONSTANT_SIGNED,
          true
        );
      }
    }

    return new ProductConstantExpression(0, symbolToken + 1, true, false, false);
  }

  /// Finds one unique imported public scalar product by unqualified name.
  public ProductConstantResolution lookupProductConstant(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName,
    borrow byteview importedNames,
    borrow mut words importedRows
  ) {
    long count = importedRows[0];
    if (-1 < count) {} else {
      return new ProductConstantResolution(0, false, false, false);
    }

    if (count < MAX_CONSTANT_PRODUCTS + 1) {} else {
      return new ProductConstantResolution(0, false, false, false);
    }

    long candidates = 0;
    long selectedType = 0;
    long selectedValue = 0;
    long selectedResolved = 0;
    long row = 0;
    while (row < count) limit MAX_CONSTANT_PRODUCTS {
      long base = CONSTANT_PRODUCT_HEADER_ROWS + row * CONSTANT_PRODUCT_COLUMNS;
      if (
        sameName(
          source,
          tokenStarts,
          tokenLengths,
          assertedName,
          importedNames,
          importedRows[base + CONSTANT_NAME_START],
          importedRows[base + CONSTANT_NAME_LENGTH]
        )
      ) {
        candidates += 1;
        selectedType = importedRows[base + CONSTANT_TYPE];
        selectedValue = importedRows[base + CONSTANT_VALUE];
        selectedResolved = importedRows[base + CONSTANT_RESOLVED];
      }

      row += 1;
    }

    if (candidates == 1) {
      if (selectedResolved == 1) {
        return new ProductConstantResolution(
          selectedValue,
          true,
          selectedType == CONSTANT_SIGNED,
          true
        );
      }

      return new ProductConstantResolution(0, true, false, false);
    }

    if (candidates == 0) {
      return new ProductConstantResolution(0, false, false, true);
    }

    return new ProductConstantResolution(0, true, false, false);
  }
}
