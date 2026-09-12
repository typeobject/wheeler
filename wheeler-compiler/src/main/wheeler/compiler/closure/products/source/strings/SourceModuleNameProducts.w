//! Joins declared globals and callable names in private source-module emission storage.

module wheeler.compiler.closure.source_module_name_products;

import wheeler.compiler.closure.source_global_products;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.source_module_strings;
import wheeler.compiler.compiler_token_limits;

classical class SourceModuleNameProducts {
  /// Places source globals after the complete private string-order workspace.
  public const long SOURCE_MODULE_GLOBAL_START = SOURCE_MODULE_STRING_ROWS;
  /// Sizes the directory workspace and complete global publication window.
  public const long SOURCE_MODULE_NAME_ROWS = SOURCE_MODULE_GLOBAL_START
    + SOURCE_GLOBAL_PUBLICATION_ROWS;
  private const long MAX_CALLABLES = 64;
  private const long LIBRARY_NAME_ID = 0;
  private const long CLASS_NAME_ID = LIBRARY_NAME_ID + 1;
  private const long FIRST_CALLABLE_NAME = CLASS_NAME_ID + 1;
  private const long LIBRARY_NAME_BYTES = 8;
  private const long QUALIFIER_BYTES = 2;

  /// Reports canonical private names, the class ID, and the declaration-ordered global count.
  public record SourceModuleNamePlan(
    long stringBytes,
    long stringCount,
    long classNameId,
    long globalCount
  ) {}

  private long copyName(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    assert(-1 < start);
    assert(0 < length);
    assert(length < MAX_QUALIFIED_NAME_BYTES + 1);
    assert(start < bufferLength(input) + 1);
    assert(length < bufferLength(input) - start + 1);
    assert(length < bufferLength(output) - cursor + 1);
    long copied = 0;
    while (copied < length) limit MAX_QUALIFIED_NAME_BYTES {
      setByte(output, cursor + copied, input[start + copied]);
      copied += 1;
    }

    return cursor + length;
  }

  /// Prepares private names and globals for either callable or callable-free publication.
  /// Every output is compiler scratch. A rejected call must not publish any of these products.
  /// The caller lends three scanner columns and a callable-ID column for transient front indexing.
  public SourceModuleNamePlan materializeSourceModuleNames(
    borrow utf8 source,
    borrow byteview archive,
    long classNameStart,
    long classNameLength,
    borrow byteview moduleNames,
    long moduleNameStart,
    long moduleNameLength,
    long firstCallable,
    long callableCount,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow byteview constantNames,
    borrow mut words constants,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut bytes strings,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut words products
  ) {
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(functionNameIds) == MAX_CALLABLES);
    assert(SOURCE_MODULE_NAME_ROWS < bufferLength(products) + 1);
    SourceGlobalPlan globals = materializeSourceGlobalProducts(
      source,
      constantNames,
      constants,
      kinds,
      starts,
      lengths,
      functionNameIds,
      /* nameStart= */ 0,
      strings,
      SOURCE_MODULE_GLOBAL_START,
      products
    );
    assert(globals.valid);
    long cursor = globals.nameBytes;
    writeAscii(strings, cursor, "$library");
    set(stringStarts, LIBRARY_NAME_ID, cursor);
    set(stringLengths, LIBRARY_NAME_ID, LIBRARY_NAME_BYTES);
    cursor += LIBRARY_NAME_BYTES;
    set(stringStarts, CLASS_NAME_ID, cursor);
    set(stringLengths, CLASS_NAME_ID, classNameLength);
    cursor = copyName(archive, classNameStart, classNameLength, strings, cursor);
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long original = firstCallable + callable;
      long id = FIRST_CALLABLE_NAME + callable;
      set(stringStarts, id, cursor);
      cursor = copyName(moduleNames, moduleNameStart, moduleNameLength, strings, cursor);
      writeAscii(strings, cursor, "::");
      cursor += QUALIFIER_BYTES;
      cursor = copyName(
        callableNames,
        callableNameStarts[original],
        callableNameLengths[original],
        strings,
        cursor
      );
      set(stringLengths, id, cursor - stringStarts[id]);
      callable += 1;
    }

    long firstGlobalName = FIRST_CALLABLE_NAME + callableCount;
    long global = 0;
    while (global < globals.globalCount) limit MAX_SOURCE_GLOBALS {
      set(stringStarts, firstGlobalName + global, products[SOURCE_MODULE_GLOBAL_START + global]);
      set(
        stringLengths,
        firstGlobalName + global,
        products[SOURCE_MODULE_GLOBAL_START + SOURCE_GLOBAL_LENGTH_ROW + global]
      );
      global += 1;
    }

    long stringCount = materializeSourceModuleStringOrder(
      strings,
      cursor,
      firstGlobalName + globals.globalCount,
      stringStarts,
      stringLengths,
      products
    );
    long mappedCallable = 0;
    while (mappedCallable < callableCount) limit MAX_CALLABLES {
      set(functionNameIds, mappedCallable, products[FIRST_CALLABLE_NAME + mappedCallable]);
      mappedCallable += 1;
    }

    long mappedGlobal = 0;
    while (mappedGlobal < globals.globalCount) limit MAX_SOURCE_GLOBALS {
      set(
        products,
        SOURCE_MODULE_GLOBAL_START + SOURCE_GLOBAL_NAME_ID_ROW + mappedGlobal,
        products[firstGlobalName + mappedGlobal]
      );
      mappedGlobal += 1;
    }

    return new SourceModuleNamePlan(
      cursor,
      stringCount,
      products[CLASS_NAME_ID],
      globals.globalCount
    );
  }
}
