package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.io.DurabilityEvidence.Source;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.Atomicity;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.FailureModel;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differentially checks Wheeler-native and stage-0 durability receipt identities. */
final class NativeDurabilityReceiptExampleTest {
  private static final Path CORE = Path.of("../wheeler-core/src/main/wheeler");
  private static final Path RUNTIME = Path.of("../wheeler-runtime/src/main/wheeler");
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/io/NativeDurabilityReceipts.w");

  @Test
  void wheelerReproducesTheClosedReceiptChain() throws Exception {
    DurabilitySubject subject = new DurabilitySubject(
        "file:demo",
        7,
        0,
        128,
        hash('a'),
        "namespace:packages/demo");
    DurabilityProfile profile = new DurabilityProfile(
        FailureModel.POWER_LOSS,
        Atomicity.FILE_GENERATION,
        3,
        2,
        hash('b'),
        List.of("cache-flush-verified", "independent-power-domains"));
    DurabilityEvidence[] evidence = {
        evidence(Source.OPERATION_COMPLETION, '1'),
        evidence(Source.DATA_FLUSH, '2'),
        evidence(Source.METADATA_FLUSH, '3'),
        evidence(Source.ATOMIC_RENAME, '4'),
        evidence(Source.NAMESPACE_FLUSH, '5'),
        evidence(Source.QUORUM_PROTOCOL, '6')
    };
    DurabilityReceipt[] receipts = chain(subject, profile, evidence);
    Program program = program();

    for (int index = 0; index < receipts.length; index++) {
      byte[] input = input(subject, profile, evidence, receipts, index, index + 1);
      VirtualMachine machine = VirtualMachine.withBinaryInput(program, input, 32);
      var initial = machine.snapshot();
      machine.run();
      assertArrayEquals(
          HexFormat.of().parseHex(receipts[index].identity()),
          machine.hostOutput(),
          "receipt stage " + (index + 1));
      assertEquals(1, machine.global("accepted"));
      assertEquals(index + 1, machine.global("finalKind"));
      assertEquals(index + 1, machine.global("finalDepth"));
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }

    byte[] skippedInput = input(subject, profile, evidence, receipts, 1, 3);
    skippedInput[3] = 3;
    VirtualMachine skipped = VirtualMachine.withBinaryInput(program, skippedInput, 32);
    skipped.run();
    assertEquals(0, skipped.global("accepted"));
    assertArrayEquals(new byte[32], skipped.hostOutput());
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeDurabilityReceipts.w", Files.readString(FIXTURE),
            "Receipts.w", Files.readString(RUNTIME.resolve("runtime/io/Receipts.w")),
            "Sha256.w", Files.readString(CORE.resolve("crypto/Sha256.w"))),
        "wheeler.conformance.io.durability_receipts");
  }

  private static DurabilityReceipt[] chain(
      DurabilitySubject subject,
      DurabilityProfile profile,
      DurabilityEvidence[] evidence) {
    DurabilityReceipt[] receipts = new DurabilityReceipt[6];
    receipts[0] = DurabilityReceiptIssuer.writeCompleted(subject, profile, evidence[0]);
    for (int index = 1; index < receipts.length; index++) {
      receipts[index] = DurabilityReceiptIssuer.promote(
          receipts[index - 1], Kind.values()[index], evidence[index]);
    }
    return receipts;
  }

  private static byte[] input(
      DurabilitySubject subject,
      DurabilityProfile profile,
      DurabilityEvidence[] evidence,
      DurabilityReceipt[] receipts,
      int evidenceIndex,
      int targetKind) {
    byte[] input = new byte[168];
    if (evidenceIndex > 0) {
      input[0] = (byte) evidenceIndex;
      input[1] = (byte) evidenceIndex;
      byte[] priorEvidence = HexFormat.of().parseHex(
          evidence[evidenceIndex - 1].evidenceIdentity());
      byte[] parent = HexFormat.of().parseHex(receipts[evidenceIndex - 1].identity());
      System.arraycopy(priorEvidence, 0, input, 104, 32);
      System.arraycopy(parent, 0, input, 136, 32);
    }
    input[2] = (byte) targetKind;
    input[3] = (byte) (evidenceIndex + 1);
    input[4] = 1;
    input[5] = 3;
    input[6] = 2;
    System.arraycopy(DurabilityReceiptIssuer.subjectIdentity(subject), 0, input, 8, 32);
    System.arraycopy(DurabilityReceiptIssuer.profileIdentity(profile), 0, input, 40, 32);
    byte[] currentEvidence = HexFormat.of().parseHex(evidence[evidenceIndex].evidenceIdentity());
    System.arraycopy(currentEvidence, 0, input, 72, 32);
    return input;
  }

  private static DurabilityEvidence evidence(Source source, char identity) {
    return new DurabilityEvidence(source, hash(identity), "evidence:" + source);
  }

  private static String hash(char value) {
    return Character.toString(value).repeat(64);
  }
}
