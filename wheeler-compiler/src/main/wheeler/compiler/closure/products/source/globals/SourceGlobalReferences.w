//! Resolves names against validated declaration ordinals, never initializer values.

module wheeler.compiler.closure.source_global_references;

import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.source_string_ranges;
import wheeler.compiler.constant_product_schema;
import wheeler.compiler.source_identifier_ranges;

classical class SourceGlobalReferences {
  /// Validates every active copied name before any lookup can select a predecessor.
  public void requireSourceGlobalNames(
    borrow byteview names,
    long count,
    long productStart,
    borrow mut words products
  ) {
    assert(-1 < count);
    assert(count < MAX_SOURCE_GLOBALS + 1);
    assert(-1 < productStart);
    assert(productStart < bufferLength(products) + 1);
    if (0 < count) {
      assert(SOURCE_GLOBAL_ROWS < bufferLength(products) - productStart + 1);
    }

    long row = 0;
    while (row < count) limit MAX_SOURCE_GLOBALS {
      long start = products[productStart + row];
      long length = products[productStart + SOURCE_GLOBAL_LENGTH_ROW + row];
      assert(copiedSourceIdentifierValid(names, start, length));
      long prior = 0;
      while (prior < row) limit MAX_SOURCE_GLOBALS {
        assert(
          compareSourceStringRanges(
            names,
            start,
            length,
            names,
            products[productStart + prior],
            products[productStart + SOURCE_GLOBAL_LENGTH_ROW + prior]
          ) != 0
        );
        prior += 1;
      }

      row += 1;
    }
  }

  /// Rejects overlapping state and scalar namespaces before body products can publish.
  public void requireSourceGlobalScope(
    borrow byteview names,
    long count,
    long productStart,
    borrow mut words products,
    borrow byteview symbolNames,
    long moduleOwner,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths
  ) {
    requireSourceGlobalNames(names, count, productStart, products);
    assert(-1 < symbolCount);
    assert(symbolCount < MAX_CONSTANT_PRODUCTS + 1);
    assert(bufferLength(symbolOwners) == MAX_CONSTANT_PRODUCTS);
    assert(bufferLength(symbolStarts) == MAX_CONSTANT_PRODUCTS);
    assert(bufferLength(symbolLengths) == MAX_CONSTANT_PRODUCTS);
    long global = 0;
    while (global < count) limit MAX_SOURCE_GLOBALS {
      long symbol = 0;
      while (symbol < symbolCount) limit MAX_CONSTANT_PRODUCTS {
        if (symbolOwners[symbol] == moduleOwner) {
          assert(
            compareSourceStringRanges(
              names,
              products[productStart + global],
              products[productStart + SOURCE_GLOBAL_LENGTH_ROW + global],
              symbolNames,
              symbolStarts[symbol],
              symbolLengths[symbol]
            ) != 0
          );
        }

        symbol += 1;
      }

      global += 1;
    }
  }

  /// Selects an exact declared ordinal, or minus one for an absent spelling.
  public long sourceGlobalOrdinal(
    borrow utf8 source,
    long start,
    long length,
    borrow byteview names,
    long count,
    long productStart,
    borrow mut words products
  ) {
    requireSourceGlobalNames(names, count, productStart, products);
    assert(-1 < start);
    assert(start < bufferLength(source) + 1);
    assert(0 < length);
    assert(length < bufferLength(source) - start + 1);
    long row = 0;
    while (row < count) limit MAX_SOURCE_GLOBALS {
      if (
        matchesSourceIdentifier(
          source,
          start,
          length,
          names,
          products[productStart + row],
          products[productStart + SOURCE_GLOBAL_LENGTH_ROW + row]
        )
      ) {
        return row;
      }

      row += 1;
    }

    return -1;
  }
}
