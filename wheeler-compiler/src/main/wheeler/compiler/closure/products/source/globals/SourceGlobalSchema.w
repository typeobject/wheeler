//! Defines declared state columns and their canonical name-reference extension.

module wheeler.compiler.closure.source_global_schema;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.opcodes;

classical class SourceGlobalSchema {
  /// Bounds source globals by the native interpreter's independent global window.
  public const long MAX_SOURCE_GLOBALS = INTERPRETER_GLOBAL_COUNT;
  /// Counts copied name start, name length, and signed initial value columns.
  public const long SOURCE_GLOBAL_COLUMNS = 3;
  /// Sizes the complete source-global declaration window.
  public const long SOURCE_GLOBAL_ROWS = MAX_SOURCE_GLOBALS * SOURCE_GLOBAL_COLUMNS;
  /// Starts copied name lengths after copied name starts.
  public const long SOURCE_GLOBAL_LENGTH_ROW = MAX_SOURCE_GLOBALS;
  /// Starts signed initial values after the two name columns.
  public const long SOURCE_GLOBAL_VALUE_ROW = SOURCE_GLOBAL_LENGTH_ROW + MAX_SOURCE_GLOBALS;
  /// Bounds the copied name of each source state declaration.
  public const long SOURCE_GLOBAL_NAME_BYTES = MAX_QUALIFIED_NAME_BYTES;
  /// Reserves the largest admitted copied name for every source global.
  public const long SOURCE_GLOBAL_NAMES = MAX_SOURCE_GLOBALS * SOURCE_GLOBAL_NAME_BYTES;
  /// Starts canonical name IDs after the three declaration-product columns.
  public const long SOURCE_GLOBAL_NAME_ID_ROW = SOURCE_GLOBAL_ROWS;
  /// Sizes the complete declaration and canonical-name window.
  public const long SOURCE_GLOBAL_PUBLICATION_ROWS = SOURCE_GLOBAL_NAME_ID_ROW + MAX_SOURCE_GLOBALS;
}
