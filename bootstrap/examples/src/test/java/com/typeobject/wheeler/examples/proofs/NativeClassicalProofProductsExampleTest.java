package com.typeobject.wheeler.examples.proofs;

import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.CAPACITY;
import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.DESCRIPTOR_BYTES;
import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.MAX_PROOFS;
import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.OUTPUT_START;
import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.WORD_MAX;
import static com.typeobject.wheeler.examples.proofs.ProofProductFixture.words;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Retains split classical claims without confusing certificate shape with proof acceptance. */
final class NativeClassicalProofProductsExampleTest {
  @Test
  void rebasesEveryColumnThroughTheLastRetainedRowAndReplays() throws Exception {
    byte[] artifact = ProofProductFixture.artifact();
    for (int first : new int[] {3, MAX_PROOFS - 2}) {
      VirtualMachine machine = ProofProductFixture.machine(
          artifact, true, "firstProof = " + first + ";", CAPACITY);
      MachineSnapshot initial = machine.snapshot();
      MachineSnapshot prepared = ProofProductFixture.prepare(machine);
      byte[] output = machine.hostOutput();
      ProofProductFixture.publish(machine);
      assertEquals(first + 2, machine.global("result"));
      ProofProductFixture.checkDecoded(prepared, machine.snapshot(), artifact, first, 7, 11, 17);
      assertArrayEquals(output, machine.hostOutput());
      ProofProductFixture.finishAndReplay(machine, initial);
    }
  }

  @ParameterizedTest
  @ValueSource(longs = {1, 4294967295L, 4294967296L, Long.MAX_VALUE})
  void retainsAndEmitsBothArgumentWordsWithoutClaimingAValidFinalBound(long bound)
      throws Exception {
    byte[] artifact = ProofProductFixture.artifact();
    int proofStart = ProofProductFixture.section(artifact, 10);
    words(artifact).putLong(proofStart + Integer.BYTES + DESCRIPTOR_BYTES + 4 * Integer.BYTES,
        bound);
    VirtualMachine decoder = ProofProductFixture.machine(artifact, true, "", CAPACITY);
    MachineSnapshot initial = decoder.snapshot();
    MachineSnapshot prepared = ProofProductFixture.prepare(decoder);
    ProofProductFixture.publish(decoder);
    ProofProductFixture.checkDecoded(prepared, decoder.snapshot(), artifact, 3, 7, 11, 17);
    ProofProductFixture.finishAndReplay(decoder, initial);

    String changes = "set(rows, PROOF_ARGUMENT_LOW_ROW + 1, " + (bound & WORD_MAX) + ");"
        + "set(rows, PROOF_ARGUMENT_HIGH_ROW + 1, " + (bound >>> Integer.SIZE) + ");";
    VirtualMachine emitter = ProofProductFixture.machine(new byte[1], false, changes, CAPACITY);
    initial = emitter.snapshot();
    prepared = ProofProductFixture.prepare(emitter);
    byte[] expected = emitter.hostOutput();
    var bytes = words(expected);
    bytes.putInt(OUTPUT_START, 2);
    long[][] descriptors = {{0, 23, 1, 18, WORD_MAX, WORD_MAX},
        {1, 29, 4, 17, bound & WORD_MAX, bound >>> Integer.SIZE}};
    for (int proof = 0; proof < descriptors.length; proof++) {
      for (int column = 0; column < descriptors[proof].length; column++) {
        bytes.putInt(OUTPUT_START + Integer.BYTES + proof * DESCRIPTOR_BYTES
            + column * Integer.BYTES, (int) descriptors[proof][column]);
      }
    }
    ProofProductFixture.publish(emitter);
    assertEquals(Integer.BYTES + 2 * DESCRIPTOR_BYTES, emitter.global("result"));
    assertArrayEquals(expected, emitter.hostOutput());
    assertEquals(ProofProductFixture.tables(prepared),
        ProofProductFixture.tables(emitter.snapshot()));
    assertEquals(prepared.buffers().getFirst(), emitter.snapshot().buffers().getFirst());
    ProofProductFixture.finishAndReplay(emitter, initial);
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "set(rows, PROOF_RULE_ROW + 1, 0);",
      "set(rows, PROOF_RULE_ROW + 1, 2);",
      "set(rows, PROOF_RULE_ROW + 1, 3);",
      "set(rows, PROOF_RULE_ROW + 1, 5);",
      "set(rows, PROOF_RULE_ROW + 1, 9223372036854775807);",
      "set(rows, PROOF_ARGUMENT_LOW_ROW, 0);",
      "set(rows, PROOF_ARGUMENT_HIGH_ROW, 0);",
      "set(rows, PROOF_ARGUMENT_LOW_ROW + 1, 0);",
      "set(rows, PROOF_ARGUMENT_LOW_ROW + 1, -1);",
      "set(rows, PROOF_ARGUMENT_HIGH_ROW + 1, -1);",
      "set(rows, PROOF_ARGUMENT_LOW_ROW + 1, 4294967296);",
      "set(rows, PROOF_ARGUMENT_HIGH_ROW + 1, 4294967296);",
      "set(rows, PROOF_ARGUMENT_HIGH_ROW + 1, 2147483648);",
      "set(rows, PROOF_ARGUMENT_LOW_ROW + 1, 9223372036854775807);",
      "set(rows, PROOF_ARGUMENT_HIGH_ROW + 1, 9223372036854775807);",
      "set(rows, PROOF_NAME_ROW + 1, -1);",
      "set(rows, PROOF_NAME_ROW + 1, 64);",
      "set(rows, PROOF_SUBJECT_ROW + 1, -1);",
      "set(rows, PROOF_SUBJECT_ROW + 1, 64);",
      "set(strings, 12, -1);",
      "set(strings, 12, 64);",
      "proofCount = 0;", "proofCount = 4097;",
      "functionCount = 0;", "functionCount = 4097;",
      "stringCount = 0;", "stringCount = 16385;",
      "outputStart = -1;", "outputStart = 9223372036854775807;"
  })
  void rejectsMalformedFinalRowsBeforeWritingTheCountOrAnyEarlierDescriptor(String changes)
      throws Exception {
    ProofProductFixture.reject(ProofProductFixture.machine(new byte[1], false, changes, CAPACITY));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "firstProof = -1;", "firstProof = 4095;", "firstProof = 4097;",
      "moduleOwner = -1;", "moduleOwner = 512;",
      "stringBase = -1;", "stringBase = 16385;", "stringBase = 16321;",
      "stringBase = 9223372036854775807;",
      "stringCount = -1;", "stringCount = 16374;",
      "firstFunction = -1;", "firstFunction = 4097;", "firstFunction = 4033;",
      "firstFunction = 9223372036854775807;",
      "functionCount = 0;", "functionCount = 4080;",
      "artifactLength -= 1;", "artifactLength += 1;"
  })
  void rejectsIncompleteSourceWindowsWithoutAppendingEvenTheFirstRow(String changes)
      throws Exception {
    ProofProductFixture.reject(ProofProductFixture.machine(
        ProofProductFixture.artifact(), true, changes, CAPACITY));
  }

  @ParameterizedTest
  @ValueSource(ints = {0, 2, 3, 5, -1})
  void rejectsCircuitAndUnknownRulesRatherThanRebasingTheirSubjectsAsFunctions(int rule)
      throws Exception {
    byte[] artifact = ProofProductFixture.artifact();
    int last = ProofProductFixture.section(artifact, 10) + Integer.BYTES + DESCRIPTOR_BYTES;
    words(artifact).putInt(last + 2 * Integer.BYTES, rule);
    ProofProductFixture.reject(ProofProductFixture.machine(artifact, true, "", CAPACITY));
  }

  @ParameterizedTest
  @ValueSource(longs = {0, -1, Long.MIN_VALUE})
  void rejectsNonpositiveSourceStepArgumentsAfterAnOtherwiseValidInverseRow(long bound)
      throws Exception {
    byte[] artifact = ProofProductFixture.artifact();
    int last = ProofProductFixture.section(artifact, 10) + Integer.BYTES + DESCRIPTOR_BYTES;
    words(artifact).putLong(last + 4 * Integer.BYTES, bound);
    ProofProductFixture.reject(ProofProductFixture.machine(artifact, true, "", CAPACITY));
  }

  @ParameterizedTest
  @ValueSource(strings = {"id", "name", "subject", "inverseArgument", "emptySection"})
  void rejectsMalformedSourceDescriptorsWithoutPublishingTheirValidPredecessor(String field)
      throws Exception {
    byte[] artifact = ProofProductFixture.artifact();
    int proofStart = ProofProductFixture.section(artifact, 10);
    int last = proofStart + Integer.BYTES + DESCRIPTOR_BYTES;
    switch (field) {
      case "id" -> words(artifact).putInt(last, 0);
      case "name" -> words(artifact).putInt(last + Integer.BYTES, 64);
      case "subject" -> words(artifact).putInt(last + 3 * Integer.BYTES, 64);
      case "inverseArgument" -> words(artifact).putInt(last + 2 * Integer.BYTES, 1);
      case "emptySection" -> {
        words(artifact).putInt(proofStart, 0);
        int directoryCount = words(artifact).getInt(24);
        int proofDirectory = 40 + (directoryCount - 1) * 32;
        assertEquals(10, words(artifact).getInt(proofDirectory));
        words(artifact).putLong(proofDirectory + 16, Integer.BYTES);
      }
      default -> throw new AssertionError(field);
    }
    ProofProductFixture.reject(ProofProductFixture.machine(artifact, true, "", CAPACITY));
  }

  @Test
  void rejectsTheFirstMissingOutputByteWithoutChangingCallerStorage() throws Exception {
    ProofProductFixture.reject(ProofProductFixture.machine(new byte[1], false, "",
        OUTPUT_START + Integer.BYTES + 2 * DESCRIPTOR_BYTES - 1));
  }
}
