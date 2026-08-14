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
}
