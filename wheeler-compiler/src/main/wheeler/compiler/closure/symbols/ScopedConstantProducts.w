//! Detaches counted scalar names and qualifiers without reading dependency bodies.

module wheeler.compiler.closure.scoped_constant_products;

import wheeler.compiler.constant_product_schema;
import wheeler.compiler.identifier_starts;
import wheeler.compiler.source_scalars;

classical class ScopedConstantProducts {
  private const long MODULE_SEPARATOR = 46;

  /// Reports the complete rebased table and appended name-byte extent.
  public record ScopedConstantProductPlan(long productCount, long nameBytes) {}

  private boolean nameValid(borrow byteview source, long start, long length, boolean qualified) {
    if (start < 0) {
      return false;
    }

    if (length < 0) {
      return false;
    }

    if (MAX_CONSTANT_NAME_BYTES < length) {
      return false;
    }

    if (bufferLength(source) < start) {
      return false;
    }

    if (bufferLength(source) - start < length) {
      return false;
    }

    if (length == 0) {
      return qualified;
    }

    boolean first = true;
    long offset = 0;
    while (offset < length) limit MAX_CONSTANT_NAME_BYTES {
      long scalar = source[start + offset];
      if (qualified) {
        if (scalar == MODULE_SEPARATOR) {
          if (first) {
            return false;
          }

          first = true;
          offset += 1;
          continue;
        }
      }

      if (identifierStart(scalar) == false) {
        if (first) {
          return false;
        }

        if (scalar < SCALAR_DIGIT_ZERO) {
          return false;
        }

        if (SCALAR_DIGIT_NINE < scalar) {
          return false;
        }
      }

      first = false;
      offset += 1;
    }

    return first == false;
  }

  /// Validates complete scalar facts and both name views before measuring copied storage.
  /// Traps on malformed rows or capacity excess without allocation or caller mutation.
  public long measureScopedConstantProducts(
    borrow byteview nameSources,
    borrow byteview qualifierSources,
    long count,
    borrow mut words sourceRows,
    long available
  ) {
    assert(-1 < count);
    assert(count < MAX_CONSTANT_PRODUCTS + 1);
    long rows = CONSTANT_PRODUCT_HEADER_ROWS + count * CONSTANT_PRODUCT_COLUMNS;
    assert(rows < bufferLength(sourceRows) + 1);
    assert(sourceRows[0] == count);
    assert(-1 < available);
    assert(available < CONSTANT_PRODUCT_NAME_BYTES + 1);
    long needed = 0;
    long product = 0;
    while (product < count) limit MAX_CONSTANT_PRODUCTS {
      long row = CONSTANT_PRODUCT_HEADER_ROWS + product * CONSTANT_PRODUCT_COLUMNS;
      long nameLength = sourceRows[row + CONSTANT_NAME_LENGTH];
      long qualifierLength = sourceRows[row + CONSTANT_MODULE_LENGTH];
      assert(nameValid(nameSources, sourceRows[row + CONSTANT_NAME_START], nameLength, false));
      assert(
        nameValid(
          qualifierSources,
          sourceRows[row + CONSTANT_MODULE_START],
          qualifierLength,
          true
        )
      );
      long type = sourceRows[row + CONSTANT_TYPE];
      if (type != CONSTANT_SIGNED) {
        assert(type == CONSTANT_BOOLEAN);
      }

      long resolved = sourceRows[row + CONSTANT_RESOLVED];
      if (resolved != 0) {
        assert(resolved == 1);
        if (type == CONSTANT_BOOLEAN) {
          long value = sourceRows[row + CONSTANT_VALUE];
          if (value != 0) {
            assert(value == 1);
          }
        }
      }

      assert(nameLength < available - needed + 1);
      needed += nameLength;
      assert(qualifierLength < available - needed + 1);
      needed += qualifierLength;
      product += 1;
    }

    return needed;
  }

  private long copyName(
    borrow byteview source,
    long start,
    long length,
    borrow mut bytes names,
    long cursor
  ) {
    long offset = 0;
    while (offset < length) limit MAX_CONSTANT_NAME_BYTES {
      setByte(names, cursor + offset, source[start + offset]);
      offset += 1;
    }

    return cursor + length;
  }

  /// Copies identifier and qualifier ranges into one detached expression-lookup view.
  /// Both input coordinate spaces remain immutable. No dependency body is scanned or copied.
  /// Resolution flags and duplicate products survive unchanged for the shared lookup owner.
  /// Effects: validates the whole batch before publishing any row or byte.
  /// Allocates the result record before publication, without new owned buffers.
  /// An empty batch writes only the zero count. Prefixes and unused tails remain unchanged.
  public ScopedConstantProductPlan copyScopedConstantProducts(
    borrow byteview nameSources,
    borrow byteview qualifierSources,
    long count,
    borrow mut words sourceRows,
    long outputStart,
    borrow mut bytes names,
    borrow mut words products
  ) {
    assert(-1 < outputStart);
    assert(outputStart < bufferLength(names) + 1);
    assert(bufferLength(names) < CONSTANT_PRODUCT_NAME_BYTES + 1);
    long needed = measureScopedConstantProducts(
      nameSources,
      qualifierSources,
      count,
      sourceRows,
      bufferLength(names) - outputStart
    );
    long rows = CONSTANT_PRODUCT_HEADER_ROWS + count * CONSTANT_PRODUCT_COLUMNS;
    assert(rows < bufferLength(products) + 1);

    ScopedConstantProductPlan result = new ScopedConstantProductPlan(count, needed);
    long cursor = outputStart;
    long product = 0;
    while (product < count) limit MAX_CONSTANT_PRODUCTS {
      long row = CONSTANT_PRODUCT_HEADER_ROWS + product * CONSTANT_PRODUCT_COLUMNS;
      long nameStart = cursor;
      cursor = copyName(
        nameSources,
        sourceRows[row + CONSTANT_NAME_START],
        sourceRows[row + CONSTANT_NAME_LENGTH],
        names,
        cursor
      );
      long qualifierStart = cursor;
      cursor = copyName(
        qualifierSources,
        sourceRows[row + CONSTANT_MODULE_START],
        sourceRows[row + CONSTANT_MODULE_LENGTH],
        names,
        cursor
      );
      long column = 0;
      while (column < CONSTANT_PRODUCT_COLUMNS) limit CONSTANT_PRODUCT_COLUMNS {
        set(products, row + column, sourceRows[row + column]);
        column += 1;
      }

      set(products, row + CONSTANT_NAME_START, nameStart);
      set(products, row + CONSTANT_MODULE_START, qualifierStart);
      product += 1;
    }

    set(products, 0, count);
    return result;
  }
}
