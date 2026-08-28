//! Defines canonical resolved direct loop-body opcode columns.

module wheeler.compiler.loop_body_opcodes;

classical class LoopBodyOpcodes {
  /// Starts equality assertions over one signed local and one literal.
  public const long BODY_ASSERT_EQ_LITERAL_BASE = 32768;
  /// Starts less-than assertions over one signed local and one literal.
  public const long BODY_ASSERT_LT_LITERAL_BASE = 33024;
  /// Declares one Boolean local from a literal.
  public const long BODY_BOOLEAN_LITERAL = 33280;
  /// Asserts one Boolean local.
  public const long BODY_ASSERT_BOOLEAN = 33281;
  /// Starts Boolean-local assignments from literals.
  public const long BODY_ASSIGN_BOOLEAN_LITERAL_BASE = 33536;
  /// Starts Boolean-local assignments from prior locals.
  public const long BODY_ASSIGN_BOOLEAN_LOCAL_BASE = 33792;
  /// Loads one signed local from an owned or borrowed word buffer.
  public const long BODY_WORDS_GET = 34048;
  /// Stores one signed local in an owned or borrowed word buffer.
  public const long BODY_WORDS_SET = 34049;
  /// Copies one indexed word between owned or borrowed buffers.
  public const long BODY_WORDS_COPY = 34050;
  /// Loads one signed local from owned or borrowed byte storage.
  public const long BODY_BYTES_GET = 34051;
  /// Stores one signed local in owned or borrowed byte storage.
  public const long BODY_BYTES_SET = 34052;
  /// Copies one indexed byte between owned or borrowed byte buffers.
  public const long BODY_BYTES_COPY = 34053;
  /// Loads one signed local from an immutable byte view.
  public const long BODY_BYTEVIEW_GET = 34054;
  /// Copies one immutable byte-view value into mutable byte storage.
  public const long BODY_BYTEVIEW_TO_BYTES_COPY = 34055;
  /// Starts Boolean declarations comparing one signed local to one literal.
  public const long BODY_BOOLEAN_EQ_LITERAL_BASE = 34304;
  /// Starts assertions comparing one signed literal below one signed local.
  public const long BODY_ASSERT_LITERAL_LT_BASE = 34560;
  /// Starts assertions comparing one signed local below another.
  public const long BODY_ASSERT_LOCAL_LT_BASE = 34816;
  /// Loads one word through a literal-plus-local index.
  public const long BODY_WORDS_GET_OFFSET = 35072;
  /// Copies one byte-view value through a local-plus-local read index.
  public const long BODY_BYTEVIEW_TO_BYTES_COPY_SUM = 35073;
  /// Reads one UTF-8 scalar through a signed byte index.
  public const long BODY_UTF8_SCALAR = 35074;
  /// Reads one UTF-8 scalar width through a signed byte index.
  public const long BODY_UTF8_WIDTH = 35075;
  /// Starts checked multiplication declarations with literal right operands.
  public const long BODY_LONG_MUL_LITERAL_BASE = 35328;
  /// Starts checked addition declarations with prior-local right operands.
  public const long BODY_LONG_ADD_LOCAL_BASE = 35584;
}
