package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.examples.NativeAggregateOperandFixture.Input;
import org.junit.jupiter.api.Test;

final class NativeCompilerAggregateOperandBoundaryExampleTest {
  @Test
  void publishesAllConstructorKindsAndWholeIdentitiesWithoutChangingTails() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      Input input = new Input(projected)
          .binding(2, 1, 7, 33).binding(2, 2, 7, 34)
          .binding(2, 3, 7, 35).binding(2, 4, 7, 36)
          .operand(0x0400, 9).operand(0x0500, 7).operand(0x0530, 7)
          .operand(0x0520, 7).operand(0x0510, 7).operand(1, 0);
      NativeAggregateOperandFixture.accepts(input);
    }
  }

  @Test
  void preservesStrictAndFilteredMissingTargetPolicies() throws Exception {
    NativeAggregateOperandFixture.accepts(new Input(true).operand(0x0500, 7));
    NativeAggregateOperandFixture.rejects(new Input(false).operand(0x0500, 7), true, false);
    NativeAggregateOperandFixture.accepts(new Input(true).binding(3, 1, 7, 33).operand(0x0500, 7));
    NativeAggregateOperandFixture.accepts(new Input(true)
        .binding(3, 1, 7, 33).binding(2, 1, 7, 34).operand(0x0500, 7));
  }

  @Test
  void rejectsLateDuplicatesWithoutPublishingAnEarlierRelocation() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      Input input = new Input(projected)
          .binding(2, 1, 7, 33).binding(2, 2, 8, 34).binding(2, 2, 8, 35)
          .operand(0x0500, 7).operand(0x0520, 8);
      NativeAggregateOperandFixture.rejects(input, !projected, false);
    }
  }

  @Test
  void checksEveryColumnAndIdentityBackingBeforeAllocatingPrivateStorage() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      for (int column = 3; column < 8; column++) {
        for (long delta : new long[] {-1, 1}) {
          Input input = sample(projected);
          input.header[column] += delta;
          NativeAggregateOperandFixture.rejects(input, true, true);
        }
      }
    }
  }

  @Test
  void rejectsInvalidCountsAndProjectedOwnersBeforeAllocatingPrivateStorage() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      for (long count : new long[] {-1, 4097, Long.MAX_VALUE}) {
        Input input = sample(projected);
        input.header[0] = count;
        NativeAggregateOperandFixture.rejects(input, true, true);
      }
      for (long count : new long[] {-1, projected ? 16385 : 65, Long.MAX_VALUE}) {
        Input input = sample(projected);
        input.header[1] = count;
        NativeAggregateOperandFixture.rejects(input, true, true);
      }
    }
    for (long owner : new long[] {-1, 512, Long.MAX_VALUE}) {
      Input input = sample(true);
      input.header[2] = owner;
      NativeAggregateOperandFixture.rejects(input, true, true);
    }
  }

  @Test
  void checksTheWholeLateOperandWindowWithoutPublishingAnEarlierMatch() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      for (long start : new long[] {-1, Long.MAX_VALUE}) {
        Input input = sample(projected).operand(0x0500, 7);
        input.starts.put(1, start);
        NativeAggregateOperandFixture.rejects(input, !projected, false);
      }
      Input shortOperand = sample(projected).operand(0x0500, 7);
      shortOperand.truncate = 1;
      NativeAggregateOperandFixture.rejects(shortOperand, !projected, false);
    }
  }

  @Test
  void validatesCompleteProjectionMetadataEvenWhenItIsNotSelected() throws Exception {
    for (long[] bad : new long[][] {
        {-1, 1, 7, 33}, {512, 1, 7, 33}, {2, 0, 7, 33}, {2, 5, 7, 33},
        {2, 1, -1, 33}, {2, 1, 7, -1}, {2, 1, 7, 4096}
    }) {
      Input input = sample(true).binding(bad[0], bad[1], bad[2], bad[3]);
      NativeAggregateOperandFixture.rejects(input, false, false);
    }
  }

  @Test
  void acceptsEmptyWindowsAndTheLastLocalDescriptorAndProjectedTarget() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      NativeAggregateOperandFixture.accepts(new Input(projected));
      NativeAggregateOperandFixture.accepts(new Input(projected).operand(1, 0));
    }
    Input last = new Input(false).operand(0x0500, 63);
    for (int row = 0; row < 64; row++) { last.binding(0, 1, row, row); }
    NativeAggregateOperandFixture.accepts(last);
    Input owner = new Input(true).binding(511, 1, 7, 4095).operand(0x0500, 7);
    owner.header[2] = 511;
    NativeAggregateOperandFixture.accepts(owner);
  }

  @Test
  void reachesTheLastInstructionWithoutAnExcessSentinelIteration() throws Exception {
    for (boolean projected : new boolean[] {false, true}) {
      Input input = new Input(projected).binding(2, 1, 7, 33);
      for (int instruction = 0; instruction < 4095; instruction++) { input.operand(1, 0); }
      input.operand(0x0500, 7);
      input.discardPreparationHistory = true;
      NativeAggregateOperandFixture.accepts(input);
    }
  }

  @Test
  void resolvesTheLastProjectedRowWithItsCompleteSelectedIdentity() throws Exception {
    Input input = new Input(true).operand(0x0500, 16383);
    for (int row = 0; row < 16384; row++) { input.binding(2, 1, row, row % 4096); }
    // Only the selected identity and sparse canaries are initialized. Every byte is compared.
    input.lastIdentityOnly = true;
    // Preparation is history-free. The complete API call and cleanup rewind to prepared storage.
    input.discardPreparationHistory = true;
    NativeAggregateOperandFixture.accepts(input);
  }

  private static Input sample(boolean projected) {
    return new Input(projected).binding(2, 1, 7, 33).operand(0x0500, 7);
  }
}
