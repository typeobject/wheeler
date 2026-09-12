//! Owns canonical integer field widths and bytecode alignment.

module wheeler.compiler.encoding_widths;

classical class EncodingWidths {
  /// Names the canonical unsigned 16-bit field width.
  public const long ENCODING_WIDTH_U16 = 2;
  /// Names the canonical unsigned 32-bit field width.
  public const long ENCODING_WIDTH_U32 = 4;
  /// Names the canonical unsigned 64-bit field width.
  public const long ENCODING_WIDTH_U64 = 8;
  /// Counts the u16 opcode, u16 operand count, and u32 encoded instruction length.
  public const long ENCODING_INSTRUCTION_HEADER_BYTES = ENCODING_WIDTH_U16 * 2 + ENCODING_WIDTH_U32;
}
