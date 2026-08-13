//! Defines fixed row layouts and bounds for direct loop-body products.

module wheeler.compiler.closure.loop_body_layouts;

classical class LoopBodyLayouts {
  /// Number of rows in one direct loop-body product table.
  public const long BODY_ROWS = 20480;
  /// Row containing each statement's first private local.
  public const long BODY_LOCAL_BASE_ROW = 4096;
  /// Row containing each closed body opcode.
  public const long BODY_OPCODE_ROW = 8192;
  /// Row containing each operand form.
  public const long BODY_OPERAND_KIND_ROW = 12288;
  /// Row containing each closed operand.
  public const long BODY_OPERAND_ROW = 16384;
  /// Bytes reserved by the atomic body-resolution arena.
  public const long LOOP_BODY_RESOLUTION_ARENA_BYTES = 460288;
  /// Number of rows in the structured statement product table.
  public const long LOOP_STATEMENT_ROWS = 28672;
  /// Row containing callable-local statement ordinals.
  public const long LOOP_STATEMENT_ORDINAL_ROW = 8192;
  /// Row containing source starts.
  public const long LOOP_STATEMENT_START_ROW = 12288;
  /// Row containing source lengths.
  public const long LOOP_STATEMENT_LENGTH_ROW = 16384;
  /// Row containing direct child counts.
  public const long LOOP_STATEMENT_CHILD_COUNT_ROW = 24576;
  /// Maximum counted callable values.
  public const long LOOP_VALUE_COUNT_LIMIT = 1024;
  /// Number of rows in the callable value product table.
  public const long LOOP_VALUE_ROWS = 7168;
}
