package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.DurabilityEvidence.Source;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Runtime authority for monotonic, evidence-bound file durability transitions. */
final class DurabilityReceiptIssuer {
  private static final String DOMAIN = "wheeler-durability-receipt-1";

  private DurabilityReceiptIssuer() {}

  static DurabilityReceipt writeCompleted(
      DurabilitySubject subject,
      DurabilityProfile profile,
      DurabilityEvidence evidence) {
    Objects.requireNonNull(subject, "subject");
    Objects.requireNonNull(profile, "profile");
    requireSource(evidence, Source.OPERATION_COMPLETION);
    return issue(Kind.WRITE_COMPLETED, subject, profile, evidence, "-", 1);
  }

  static DurabilityReceipt promote(
      DurabilityReceipt prior,
      Kind target,
      DurabilityEvidence evidence) {
    Objects.requireNonNull(prior, "prior");
    Objects.requireNonNull(target, "target");
    Source expected = expectedSource(prior.kind(), target);
    requireSource(evidence, expected);
    if (evidence.evidenceIdentity().equals(prior.evidence().evidenceIdentity())) {
      throw new IllegalArgumentException("durability promotion requires new evidence");
    }
    if (target == Kind.NAMESPACE_VISIBLE && !prior.subject().hasNamespace()) {
      throw new IllegalArgumentException("namespace visibility requires a named namespace subject");
    }
    if (target == Kind.QUORUM_STABLE) {
      DurabilityProfile profile = prior.profile();
      if (profile.replicas() < 2 || profile.quorum() < 2) {
        throw new IllegalArgumentException("quorum evidence requires a replicated quorum profile");
      }
    }
    return issue(
        target,
        prior.subject(),
        prior.profile(),
        evidence,
        prior.identity(),
        prior.depth() + 1);
  }

  private static Source expectedSource(Kind prior, Kind target) {
    if (prior == Kind.WRITE_COMPLETED && target == Kind.DATA_STABLE) {
      return Source.DATA_FLUSH;
    }
    if (prior == Kind.DATA_STABLE && target == Kind.FILE_STABLE) {
      return Source.METADATA_FLUSH;
    }
    if (prior == Kind.FILE_STABLE && target == Kind.NAMESPACE_VISIBLE) {
      return Source.ATOMIC_RENAME;
    }
    if (prior == Kind.NAMESPACE_VISIBLE && target == Kind.NAMESPACE_STABLE) {
      return Source.NAMESPACE_FLUSH;
    }
    if (prior == Kind.NAMESPACE_STABLE && target == Kind.QUORUM_STABLE) {
      return Source.QUORUM_PROTOCOL;
    }
    throw new IllegalArgumentException("durability receipt transition is not monotonic");
  }

  private static void requireSource(DurabilityEvidence evidence, Source expected) {
    Objects.requireNonNull(evidence, "evidence");
    if (evidence.source() != expected) {
      throw new IllegalArgumentException("durability evidence source does not match transition");
    }
  }

  private static DurabilityReceipt issue(
      Kind kind,
      DurabilitySubject subject,
      DurabilityProfile profile,
      DurabilityEvidence evidence,
      String parent,
      int depth) {
    StringBuilder canonical = new StringBuilder()
        .append(DOMAIN).append('\n')
        .append("kind=").append(kind).append('\n')
        .append("resource=").append(subject.resourceIdentity()).append('\n')
        .append("generation=").append(subject.generation()).append('\n')
        .append("offset=").append(subject.offset()).append('\n')
        .append("length=").append(subject.length()).append('\n')
        .append("content=").append(subject.contentIdentity()).append('\n')
        .append("namespace=").append(subject.namespaceIdentity()).append('\n')
        .append("failure=").append(profile.failureModel()).append('\n')
        .append("atomicity=").append(profile.atomicity()).append('\n')
        .append("replicas=").append(profile.replicas()).append('\n')
        .append("quorum=").append(profile.quorum()).append('\n')
        .append("backend=").append(profile.backendProfileIdentity()).append('\n');
    for (String assumption : profile.assumptions()) {
      canonical.append("assumption=").append(assumption).append('\n');
    }
    canonical.append("evidence-source=").append(evidence.source()).append('\n')
        .append("evidence=").append(evidence.evidenceIdentity()).append('\n')
        .append("detail=").append(evidence.detail()).append('\n')
        .append("parent=").append(parent).append('\n')
        .append("depth=").append(depth).append('\n');
    String identity = sha256(canonical.toString().getBytes(StandardCharsets.UTF_8));
    return new DurabilityReceipt(kind, subject, profile, evidence, parent, identity, depth);
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
