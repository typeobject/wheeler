//! Emits declared signed globals into the canonical source type section before verification.

module wheeler.compiler.closure.source_global_section;

import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.encoding;
import wheeler.compiler.type_codes;

classical class SourceGlobalSection {
  private const long ENCODED_WORD_BYTES = 4;
  private const long VALUE_WORDS = 2;
  private const long GLOBAL_DESCRIPTOR_WORDS = 2 + VALUE_WORDS;
  private const long GLOBAL_DESCRIPTOR_BYTES = GLOBAL_DESCRIPTOR_WORDS * ENCODED_WORD_BYTES;
  private const long EMPTY_AGGREGATE_COUNTS = 3;
  private const long TYPE_COUNT_WORDS = 1 + EMPTY_AGGREGATE_COUNTS;

  /// Validates every global name reference before writing declaration-ordered descriptors.
  /// Ordinals are implicit. Each descriptor holds a name ID, signed type, and full initial value.
  /// Effects: writes only the complete type-section extent after preflight, without allocation.
  public long writeSourceGlobalTypeSection(
    long globalCount,
    long productStart,
    borrow mut words products,
    long stringCount,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < globalCount);
    assert(globalCount < MAX_SOURCE_GLOBALS + 1);
    assert(-1 < productStart);
    assert(productStart < bufferLength(products) + 1);
    assert(SOURCE_GLOBAL_PUBLICATION_ROWS < bufferLength(products) - productStart + 1);
    assert(0 < stringCount);
    long checked = 0;
    while (checked < globalCount) limit MAX_SOURCE_GLOBALS {
      long name = products[productStart + SOURCE_GLOBAL_NAME_ID_ROW + checked];
      assert(-1 < name);
      assert(name < stringCount);
      long earlier = 0;
      while (earlier < checked) limit MAX_SOURCE_GLOBALS {
        assert(name != products[productStart + SOURCE_GLOBAL_NAME_ID_ROW + earlier]);
        earlier += 1;
      }

      checked += 1;
    }

    long sectionBytes = TYPE_COUNT_WORDS * ENCODED_WORD_BYTES + globalCount
      * GLOBAL_DESCRIPTOR_BYTES;
    assert(-1 < outputStart);
    assert(outputStart < bufferLength(output) + 1);
    assert(sectionBytes < bufferLength(output) - outputStart + 1);
    long cursor = writeUnsignedLittleEndian(
      output,
      outputStart,
      globalCount,
      ENCODED_WORD_BYTES
    );
    long global = 0;
    while (global < globalCount) limit MAX_SOURCE_GLOBALS {
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        products[productStart + SOURCE_GLOBAL_NAME_ID_ROW + global],
        ENCODED_WORD_BYTES
      );
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, ENCODED_WORD_BYTES);
      cursor = writeSignedLittleEndian(
        output,
        cursor,
        products[productStart + SOURCE_GLOBAL_VALUE_ROW + global],
        VALUE_WORDS * ENCODED_WORD_BYTES
      );
      global += 1;
    }

    long aggregate = 0;
    while (aggregate < EMPTY_AGGREGATE_COUNTS) limit EMPTY_AGGREGATE_COUNTS {
      cursor = writeUnsignedLittleEndian(output, cursor, /* count= */ 0, ENCODED_WORD_BYTES);
      aggregate += 1;
    }

    assert(cursor - outputStart == sectionBytes);
    return sectionBytes;
  }
}
