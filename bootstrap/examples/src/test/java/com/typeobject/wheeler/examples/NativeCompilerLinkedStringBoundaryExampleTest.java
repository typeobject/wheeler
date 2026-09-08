package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.examples.NativeLinkedStringFixture.Input;
import com.typeobject.wheeler.examples.NativeLinkedStringFixture.Window;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exact prefix ordering, complete byte windows, counted maps, and publication. */
final class NativeCompilerLinkedStringBoundaryExampleTest {
  @Test
  void ordersBothPrefixWordsAndTheirUncachedSuffixes() throws Exception {
    List<String> names = new ArrayList<>();
    for (int length : new int[] {1, 7, 8, 9, 15, 16, 17, 31, 32, 33}) {
      names.add("q".repeat(length));
      names.add("q".repeat(length - 1) + "p");
      names.add("q".repeat(length - 1) + "r");
    }
    names.add("q".repeat(16) + "za");
    names.add("q".repeat(16) + "az");
    names.add("\u007f".repeat(16));
    names.add("\u007f".repeat(15) + "\u0001");
    names.add("\u0001".repeat(16));
    names.add("q".repeat(33));
    names.add("q".repeat(8));
    Collections.reverse(names);
    Input input = new Input(names.toArray(String[]::new));
    input.outputCapacity = 2048;
    NativeLinkedStringFixture.accepts(input);
  }

  @Test
  void retainsAllLongSuffixBytesAndRejectsTheirFirstExcess() throws Exception {
    Input input = new Input("x".repeat(4096), "x".repeat(4095) + "w");
    input.outputCapacity = 16384;
    NativeLinkedStringFixture.accepts(input);
    Input excess = new Input("a", "x".repeat(4097));
    excess.outputCapacity = 8192;
    NativeLinkedStringFixture.rejects(excess);
  }

  @Test
  void acceptsTheFinalOutputByteAndRejectsShortOrInvalidWindows() throws Exception {
    Input exact = new Input("beta", "alpha", "beta");
    exact.outputCapacity = 32;
    NativeLinkedStringFixture.accepts(exact);
    for (long start : new long[] {-1, 12, 32, 33, Long.MAX_VALUE}) {
      Input invalid = new Input("beta", "alpha", "beta");
      invalid.outputCapacity = 32;
      invalid.outputStart = start;
      NativeLinkedStringFixture.rejects(invalid);
    }
    Input large = new Input("beta", "alpha", "beta");
    large.outputCapacity = 1_048_576;
    large.outputStart = large.outputCapacity - 21;
    NativeLinkedStringFixture.accepts(large);
    large.outputStart++;
    NativeLinkedStringFixture.rejects(large);
  }

  @Test
  void rejectsMalformedLaterNamesBeforeChangingAnyCallerCell() throws Exception {
    for (int position : new int[] {0, 7, 8, 15, 16, 31}) {
      for (int invalid : new int[] {0, 128, 255}) {
        Input input = new Input("valid", "x".repeat(32));
        input.archive[5 + position] = (byte) invalid;
        NativeLinkedStringFixture.rejects(input);
      }
    }
    for (long start : new long[] {-1, 130, 131, Long.MAX_VALUE}) {
      Input invalid = new Input("valid", "later");
      invalid.windows.set(1, new Window(1, start, 5));
      NativeLinkedStringFixture.rejects(invalid);
    }
    for (long length : new long[] {-1, 0, 6, Long.MAX_VALUE}) {
      Input invalid = new Input("valid", "later");
      invalid.windows.set(1, new Window(1, 125, length));
      NativeLinkedStringFixture.rejects(invalid);
    }
  }

  @Test
  void checksEveryColumnDimensionAndCompleteArchiveExtent() throws Exception {
    for (int column = 0; column < 3; column++) {
      for (int size : new int[] {16383, 16385}) {
        Input invalid = new Input("beta", "alpha");
        invalid.columns[column] = size;
        NativeLinkedStringFixture.rejects(invalid);
      }
    }
    for (long extent : new long[] {-1, 0, 128, 130, Long.MAX_VALUE}) {
      Input invalid = new Input("beta", "alpha");
      invalid.archiveBytes = extent;
      NativeLinkedStringFixture.rejects(invalid);
    }
    for (long count : new long[] {-1, 0, 16385, Long.MAX_VALUE}) {
      Input invalid = new Input("beta", "alpha");
      invalid.count = count;
      NativeLinkedStringFixture.rejects(invalid);
    }
  }

  @Test
  void boundsTheWholeSectionIndependentlyOfOutputBackingWithoutRewindHistory() throws Exception {
    String[] names = new String[256];
    for (int row = 0; row < names.length; row++) {
      int length = row == 255 ? 3068 : 4096;
      names[row] = "%04d".formatted(row) + "x".repeat(length - 4);
    }
    Input exact = new Input(names);
    exact.outputStart = 0;
    exact.outputCapacity = 1_048_576;
    NativeLinkedStringFixture.acceptsWithoutRewind(exact);
    names[255] += "x";
    Input excess = new Input(names);
    excess.outputStart = 0;
    excess.outputCapacity = 1_048_577;
    NativeLinkedStringFixture.rejectsWithoutRewind(excess);
  }

  @Test
  void mapsTheLastCountedRowWithoutRewindHistoryOrAnExtraIteration() throws Exception {
    NativeLinkedStringFixture.acceptsWithoutRewind(new Input().repeated(16384));
  }
}
