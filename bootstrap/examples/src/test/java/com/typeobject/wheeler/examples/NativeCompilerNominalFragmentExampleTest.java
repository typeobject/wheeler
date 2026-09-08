package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.examples.NativeNominalFragmentFixture.Input;
import com.typeobject.wheeler.examples.NativeNominalFragmentFixture.Selection;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Independent byte, projection, publication, and limit oracles for nominal fragments. */
final class NativeCompilerNominalFragmentExampleTest {
  private static final long TYPE_IDS = 0x10000000L;

  @Test
  void emitsSortedFragmentsWithIndependentTypeCountersAndFullRewind() throws Exception {
    NativeNominalFragmentFixture.accepts(new Input());
    Input input = new Input();
    input.capacity = 1024;
    input.owner = 0;
    input.selections.clear();
    for (int target : new int[] {4095, 1000, 999, 100, 99, 10, 9, 0}) {
      input.selections.add(new Selection(target, 1, target % 2 == 0 ? 1 : 4));
    }
    NativeNominalFragmentFixture.accepts(input);
  }

  @Test
  void emitsAllSixtyFourSelectionsIncludingTheLastTarget() throws Exception {
    Input input = selected(64);
    input.firstRecord = TYPE_IDS - 32;
    input.firstVariant = TYPE_IDS - 32;
    NativeNominalFragmentFixture.accepts(input);
  }

  @Test
  void rejectsFirstExcessSelectionAndMalformedLaterBitsOrKinds() throws Exception {
    NativeNominalFragmentFixture.rejects(selected(65));
    for (long bit : new long[] {-1, 2, Long.MAX_VALUE}) {
      Input input = new Input();
      input.selections = List.of(new Selection(3, 1, 1), new Selection(4095, bit, 4));
      NativeNominalFragmentFixture.rejects(input);
    }
    for (long kind : new long[] {0, 2, 3, 5, Long.MAX_VALUE}) {
      Input input = new Input();
      input.selections = List.of(new Selection(3, 1, 1), new Selection(4095, 1, kind));
      NativeNominalFragmentFixture.rejects(input);
    }
  }

  @Test
  void boundsBothTypeWindowsWithoutAliasingKindTags() throws Exception {
    Input last = new Input();
    last.firstRecord = TYPE_IDS - 1;
    last.firstVariant = TYPE_IDS - 1;
    NativeNominalFragmentFixture.accepts(last);
    Input empty = new Input();
    empty.selections = List.of();
    empty.firstRecord = TYPE_IDS;
    empty.firstVariant = TYPE_IDS;
    NativeNominalFragmentFixture.accepts(empty);
    for (boolean record : new boolean[] {true, false}) {
      for (long first : new long[] {-1, TYPE_IDS, TYPE_IDS + 1, Long.MAX_VALUE}) {
        Input input = new Input();
        if (record) { input.firstRecord = first; } else { input.firstVariant = first; }
        NativeNominalFragmentFixture.rejects(input);
      }
      Input crossing = new Input();
      crossing.selections.add(new Selection(4095, 1, record ? 1 : 4));
      if (record) { crossing.firstRecord = TYPE_IDS - 1; }
      else { crossing.firstVariant = TYPE_IDS - 1; }
      NativeNominalFragmentFixture.rejects(crossing);
    }
  }

  @Test
  void boundsTheEntireByteWindowBeforePublishingItsFirstDeclaration() throws Exception {
    Input exact = new Input();
    exact.capacity = 117;
    NativeNominalFragmentFixture.accepts(exact);
    exact.capacity--;
    NativeNominalFragmentFixture.rejects(exact);
    Input last = new Input();
    last.capacity = 32768;
    last.outputStart = 32662;
    NativeNominalFragmentFixture.accepts(last);
    last.outputStart++;
    NativeNominalFragmentFixture.rejects(last);
    for (long start : new long[] {-1, 256, 257, Long.MAX_VALUE}) {
      Input input = new Input();
      input.outputStart = start;
      NativeNominalFragmentFixture.rejects(input);
    }
    Input empty = new Input();
    empty.selections = List.of();
    empty.outputStart = empty.capacity;
    NativeNominalFragmentFixture.accepts(empty);
    empty.capacity = 32769;
    NativeNominalFragmentFixture.rejects(empty);
  }

  @Test
  void rejectsEveryShortAndLongColumnWithoutAllocatingScratch() throws Exception {
    for (int column = 0; column < 3; column++) {
      for (int difference : new int[] {-1, 1}) {
        Input input = new Input();
        input.columns[column] += difference;
        NativeNominalFragmentFixture.rejects(input);
      }
    }
  }

  @Test
  void writesDecimalNameBoundariesAtTheLastByteAndRejectsTheFirstExcess() throws Exception {
    for (int target : new int[] {0, 9, 10, 99, 100, 999, 1000, 4095}) {
      Input input = new Input();
      input.mode = 1;
      input.nameTarget = target;
      input.capacity = 25 + Integer.toString(target).length();
      NativeNominalFragmentFixture.accepts(input);
    }
    for (long target : new long[] {-1, 4096, Long.MAX_VALUE}) {
      Input input = new Input();
      input.mode = 1;
      input.nameTarget = target;
      NativeNominalFragmentFixture.rejects(input);
    }
    Input last = new Input();
    last.mode = 1;
    last.capacity = 32768;
    last.outputStart = 32750;
    NativeNominalFragmentFixture.accepts(last);
    Input shortOutput = new Input();
    shortOutput.mode = 1;
    shortOutput.capacity = 28;
    NativeNominalFragmentFixture.rejects(shortOutput);
    for (long start : new long[] {-1, 256, Long.MAX_VALUE}) {
      Input input = new Input();
      input.mode = 1;
      input.outputStart = start;
      NativeNominalFragmentFixture.rejects(input);
    }
  }

  @Test
  void rejectsInvalidModuleOwnersEvenForEmptyFragments() throws Exception {
    for (long owner : new long[] {-1, 512, Long.MAX_VALUE}) {
      Input input = new Input();
      input.owner = owner;
      NativeNominalFragmentFixture.rejects(input);
      input.selections = List.of();
      NativeNominalFragmentFixture.rejects(input);
    }
  }

  private static Input selected(int count) {
    Input input = new Input();
    input.capacity = 8192;
    input.selections = new ArrayList<>();
    for (int index = 0; index < count; index++) {
      input.selections.add(new Selection(4095 - index, 1, index % 2 == 0 ? 1 : 4));
    }
    return input;
  }
}
