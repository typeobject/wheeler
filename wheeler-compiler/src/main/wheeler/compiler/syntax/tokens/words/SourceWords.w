//! Admits exact source words without treating a hash as lexical identity.

module wheeler.compiler.source_words;

import wheeler.compiler.source_long_words;
import wheeler.compiler.source_short_words;

classical class SourceWords {
  /// Classifies one scanner-owned ASCII range, or returns zero without publication.
  /// Each base-128 lane starts with a one digit, retaining its exact length.
  /// Eight head bytes and five tail bytes require at most 57 and 36 bits respectively.
  public long sourceWordCode(borrow utf8 source, long start, long length) {
    if (start < 0) {
      return 0;
    }

    if (length < 1) {
      return 0;
    }

    long maximumWordLength = 13;
    if (maximumWordLength < length) {
      return 0;
    }

    long capacity = bufferLength(source);
    long lastStart = capacity - length;
    if (lastStart < start) {
      return 0;
    }

    long head = 1;
    long tail = 1;
    long offset = 0;
    boolean ascii = true;
    long lastAscii = 127;
    while (offset < length) limit 13 {
      long index = start + offset;
      long scalar = utf8Scalar(source, index);
      long nextHead = appendWordHead(head, scalar, offset);
      head = nextHead;
      long nextTail = appendWordTail(tail, scalar, offset);
      tail = nextTail;
      offset += 1;
      if (lastAscii < scalar) {
        ascii = false;
        offset = length;
      }
    }

    long word = completedSourceWord(head, tail, ascii);
    return word;
  }

  private long appendWordHead(long head, long scalar, long offset) {
    long lastHeadOffset = 7;
    if (lastHeadOffset < offset) {
      return head;
    }

    long prefix = head * 128;
    return prefix + scalar;
  }

  private long appendWordTail(long tail, long scalar, long offset) {
    if (offset < 8) {
      return tail;
    }

    long prefix = tail * 128;
    return prefix + scalar;
  }

  private long completedSourceWord(long head, long tail, boolean ascii) {
    if (ascii == false) {
      return 0;
    }

    long unknown = 0;
    long shortWord = sourceShortWordCode(head, tail);
    if (unknown < shortWord) {
      return shortWord;
    }

    long longWord = sourceLongWordCode(head, tail);
    return longWord;
  }
}
