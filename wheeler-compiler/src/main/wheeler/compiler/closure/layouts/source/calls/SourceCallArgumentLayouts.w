//! Defines the shared retained source-call argument table profile.

module wheeler.compiler.closure.source_call_argument_layouts;

classical class SourceCallArgumentLayouts {
  /// Maximum source-call rows in one module product.
  public const long SOURCE_CALL_COUNT_LIMIT = 256;
  /// Maximum ordered identifier arguments in one retained call.
  public const long SOURCE_CALL_ARITY_LIMIT = 8;
  /// Capacity of each argument column across all source calls.
  public const long SOURCE_CALL_ARGUMENT_LIMIT = SOURCE_CALL_COUNT_LIMIT * SOURCE_CALL_ARITY_LIMIT;
  /// Start of the type or defining-value offset column.
  public const long SOURCE_CALL_ARGUMENT_TYPE_ROW = SOURCE_CALL_ARGUMENT_LIMIT;
  /// Words in one two-column argument or defining-value table.
  public const long SOURCE_CALL_ARGUMENT_ROWS = SOURCE_CALL_ARGUMENT_LIMIT * 2;
}
