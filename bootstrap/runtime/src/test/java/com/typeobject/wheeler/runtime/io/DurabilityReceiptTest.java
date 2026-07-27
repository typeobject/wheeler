package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.runtime.io.DurabilityEvidence.Source;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.Atomicity;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.FailureModel;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exercises monotonic, content-bound visibility and durability receipt chains. */
final class DurabilityReceiptTest {
  @Test
  void exactEvidenceBuildsOneDeterministicFilePublicationChain() {
    DurabilitySubject subject = subject("namespace:packages/demo");
    DurabilityProfile profile = profile(3, 2);
    DurabilityReceipt write = DurabilityReceiptIssuer.writeCompleted(
        subject, profile, evidence(Source.OPERATION_COMPLETION, '1'));
    DurabilityReceipt data = DurabilityReceiptIssuer.promote(
        write, Kind.DATA_STABLE, evidence(Source.DATA_FLUSH, '2'));
    DurabilityReceipt file = DurabilityReceiptIssuer.promote(
        data, Kind.FILE_STABLE, evidence(Source.METADATA_FLUSH, '3'));
    DurabilityReceipt visible = DurabilityReceiptIssuer.promote(
        file, Kind.NAMESPACE_VISIBLE, evidence(Source.ATOMIC_RENAME, '4'));
    DurabilityReceipt namespace = DurabilityReceiptIssuer.promote(
        visible, Kind.NAMESPACE_STABLE, evidence(Source.NAMESPACE_FLUSH, '5'));
    DurabilityReceipt quorum = DurabilityReceiptIssuer.promote(
        namespace, Kind.QUORUM_STABLE, evidence(Source.QUORUM_PROTOCOL, '6'));

    assertEquals(Kind.WRITE_COMPLETED, write.kind());
    assertEquals(Kind.QUORUM_STABLE, quorum.kind());
    assertEquals(6, quorum.depth());
    assertEquals(
        "4cd384b584c7b50f0fd219a787ac0f7d1c7b32c434362cf8ed8332677d9dbdae",
        quorum.identity());
    assertEquals(namespace.identity(), quorum.parentIdentity());
    assertEquals(subject, quorum.subject());
    assertEquals(profile, quorum.profile());
    assertNotEquals(write.identity(), quorum.identity());

    DurabilityReceipt repeated = fullChain(subject, profile);
    assertEquals(quorum.identity(), repeated.identity());
    assertEquals(quorum.parentIdentity(), repeated.parentIdentity());
  }

  @Test
  void noReceiptCanSkipOrMislabelAPersistenceStage() {
    DurabilityReceipt write = DurabilityReceiptIssuer.writeCompleted(
        subject("namespace:demo"),
        profile(3, 2),
        evidence(Source.OPERATION_COMPLETION, '1'));
    assertThrows(
        IllegalArgumentException.class,
        () -> DurabilityReceiptIssuer.promote(
            write, Kind.FILE_STABLE, evidence(Source.METADATA_FLUSH, '2')));
    assertThrows(
        IllegalArgumentException.class,
        () -> DurabilityReceiptIssuer.promote(
            write, Kind.DATA_STABLE, evidence(Source.ATOMIC_RENAME, '2')));
    assertThrows(
        IllegalArgumentException.class,
        () -> DurabilityReceiptIssuer.promote(
            write, Kind.DATA_STABLE, evidence(Source.DATA_FLUSH, '1')));
  }

  @Test
  void namespaceAndQuorumClaimsRequireMatchingSubjectsAndProfiles() {
    DurabilityReceipt noNamespace = toFileStable(
        subject("-"), profile(1, 1));
    assertThrows(
        IllegalArgumentException.class,
        () -> DurabilityReceiptIssuer.promote(
            noNamespace,
            Kind.NAMESPACE_VISIBLE,
            evidence(Source.ATOMIC_RENAME, '4')));

    DurabilityReceipt singleNamespace = DurabilityReceiptIssuer.promote(
        DurabilityReceiptIssuer.promote(
            toFileStable(subject("namespace:single"), profile(1, 1)),
            Kind.NAMESPACE_VISIBLE,
            evidence(Source.ATOMIC_RENAME, '4')),
        Kind.NAMESPACE_STABLE,
        evidence(Source.NAMESPACE_FLUSH, '5'));
    assertThrows(
        IllegalArgumentException.class,
        () -> DurabilityReceiptIssuer.promote(
            singleNamespace,
            Kind.QUORUM_STABLE,
            evidence(Source.QUORUM_PROTOCOL, '6')));
  }

  @Test
  void receiptInputsRejectAmbiguousIdentityRangeAndAssumptionForms() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new DurabilitySubject("bad resource", 1, 0, 1, hash('a'), "-"));
    assertThrows(
        IllegalArgumentException.class,
        () -> new DurabilitySubject("resource", 1, Long.MAX_VALUE, 1, hash('a'), "-"));
    assertThrows(
        IllegalArgumentException.class,
        () -> new DurabilityProfile(
            FailureModel.POWER_LOSS,
            Atomicity.FILE_GENERATION,
            3,
            2,
            hash('b'),
            List.of("z-last", "a-first")));
    assertThrows(
        IllegalArgumentException.class,
        () -> new DurabilityProfile(
            FailureModel.POWER_LOSS,
            Atomicity.FILE_GENERATION,
            1,
            2,
            hash('b'),
            List.of()));
  }

  private static DurabilityReceipt fullChain(
      DurabilitySubject subject, DurabilityProfile profile) {
    DurabilityReceipt write = DurabilityReceiptIssuer.writeCompleted(
        subject, profile, evidence(Source.OPERATION_COMPLETION, '1'));
    DurabilityReceipt data = DurabilityReceiptIssuer.promote(
        write, Kind.DATA_STABLE, evidence(Source.DATA_FLUSH, '2'));
    DurabilityReceipt file = DurabilityReceiptIssuer.promote(
        data, Kind.FILE_STABLE, evidence(Source.METADATA_FLUSH, '3'));
    DurabilityReceipt visible = DurabilityReceiptIssuer.promote(
        file, Kind.NAMESPACE_VISIBLE, evidence(Source.ATOMIC_RENAME, '4'));
    DurabilityReceipt namespace = DurabilityReceiptIssuer.promote(
        visible, Kind.NAMESPACE_STABLE, evidence(Source.NAMESPACE_FLUSH, '5'));
    return DurabilityReceiptIssuer.promote(
        namespace, Kind.QUORUM_STABLE, evidence(Source.QUORUM_PROTOCOL, '6'));
  }

  private static DurabilityReceipt toFileStable(
      DurabilitySubject subject, DurabilityProfile profile) {
    DurabilityReceipt write = DurabilityReceiptIssuer.writeCompleted(
        subject, profile, evidence(Source.OPERATION_COMPLETION, '1'));
    DurabilityReceipt data = DurabilityReceiptIssuer.promote(
        write, Kind.DATA_STABLE, evidence(Source.DATA_FLUSH, '2'));
    return DurabilityReceiptIssuer.promote(
        data, Kind.FILE_STABLE, evidence(Source.METADATA_FLUSH, '3'));
  }

  private static DurabilitySubject subject(String namespace) {
    return new DurabilitySubject("file:demo", 7, 0, 128, hash('a'), namespace);
  }

  private static DurabilityProfile profile(int replicas, int quorum) {
    return new DurabilityProfile(
        FailureModel.POWER_LOSS,
        Atomicity.FILE_GENERATION,
        replicas,
        quorum,
        hash('b'),
        List.of("cache-flush-verified", "independent-power-domains"));
  }

  private static DurabilityEvidence evidence(Source source, char identity) {
    return new DurabilityEvidence(source, hash(identity), "evidence:" + source);
  }

  private static String hash(char value) {
    return Character.toString(value).repeat(64);
  }
}
