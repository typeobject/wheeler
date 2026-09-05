//! Classifies long source words through exact length-bearing ASCII lanes.

module wheeler.compiler.source_long_words;

import wheeler.compiler.keyword_tokens;

classical class SourceLongWords {
  private boolean sameWordLanes(long head, long tail, long expectedHead, long expectedTail) {
    boolean sameHead = head == expectedHead;
    if (sameHead == false) {
      return false;
    }
    return tail == expectedTail;
  }

  /// Classifies the exact two-lane spellings longer than eight ASCII bytes.
  public long sourceLongWordCode(long head, long tail) {
    if (tail < 128) {
      return 0;
    }
    long allocateBytesHead = 127142469400296037;
    long allocateBytesTail = 52332147443;
    boolean allocateBytesWord = sameWordLanes(head, tail, allocateBytesHead, allocateBytesTail);
    if (allocateBytesWord == true) {
      return TOKEN_ALLOCATE_BYTES;
    }
    long bufferLengthHead = 127744793202435685;
    long bufferLengthTail = 500824680;
    boolean bufferLengthWord = sameWordLanes(head, tail, bufferLengthHead, bufferLengthTail);
    if (bufferLengthWord == true) {
      return TOKEN_BUFFER_LENGTH;
    }
    long classicalHead = 128267992457441761;
    long classicalTail = 236;
    boolean classicalWord = sameWordLanes(head, tail, classicalHead, classicalTail);
    if (classicalWord == true) {
      return TOKEN_CLASSICAL;
    }
    long freezeUtf8Head = 129983364292242164;
    long freezeUtf8Tail = 29496;
    boolean freezeUtf8Word = sameWordLanes(head, tail, freezeUtf8Head, freezeUtf8Tail);
    if (freezeUtf8Word == true) {
      return TOKEN_FREEZE_UTF8;
    }
    long rotateRight32Head = 136726083903514985;
    long rotateRight32Tail = 62228601266;
    boolean rotateRight32Word = sameWordLanes(head, tail, rotateRight32Head, rotateRight32Tail);
    if (rotateRight32Word == true) {
      return TOKEN_ROTATE_RIGHT_32;
    }
    long utf8ScalarHead = 138436431884906732;
    long utf8ScalarTail = 28914;
    boolean utf8ScalarWord = sameWordLanes(head, tail, utf8ScalarHead, utf8ScalarTail);
    if (utf8ScalarWord == true) {
      return TOKEN_UTF8_SCALAR;
    }
    long utf8WidthHead = 138436431893394036;
    long utf8WidthTail = 232;
    boolean utf8WidthWord = sameWordLanes(head, tail, utf8WidthHead, utf8WidthTail);
    if (utf8WidthWord == true) {
      return TOKEN_UTF8_WIDTH;
    }
    return 0;
  }
}
