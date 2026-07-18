package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class Utf8Test {
  @Test
  void acceptsCanonicalOneThroughFourByteScalars() {
    Utf8.Analysis analysis = Utf8.analyze(List.of(
        0x41L,
        0xc2L, 0xa2L,
        0xe2L, 0x82L, 0xacL,
        0xf0L, 0x90L, 0x8dL, 0x88L));

    assertTrue(analysis.valid());
    assertEquals(4, analysis.scalarCount());
    assertTrue(Utf8.analyze(List.of()).valid());
    assertEquals(0, Utf8.analyze(List.of()).scalarCount());
  }

  @Test
  void rejectsOverlongSurrogateOutOfRangeStrayAndTruncatedSequences() {
    List<List<Long>> malformed = List.of(
        List.of(0x80L),
        List.of(0xc0L, 0x80L),
        List.of(0xe0L, 0x80L, 0x80L),
        List.of(0xedL, 0xa0L, 0x80L),
        List.of(0xf0L, 0x80L, 0x80L, 0x80L),
        List.of(0xf4L, 0x90L, 0x80L, 0x80L),
        List.of(0xf5L, 0x80L, 0x80L, 0x80L),
        List.of(0xc2L),
        List.of(0xe2L, 0x82L),
        List.of(0xf0L, 0x90L, 0x8dL));

    for (List<Long> value : malformed) {
      assertFalse(Utf8.analyze(value).valid(), value.toString());
    }
  }
}
