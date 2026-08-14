package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.DurabilityEvidence.Source;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Atomic native rename and directory-force authority for one exact publication target. */
public final class NativeNamespacePublication {
  private final Path temporary;
  private final Path target;
  private final Path parent;
  private final String namespaceIdentity;
  private String visibleReceipt = "-";

  public NativeNamespacePublication(Path temporary, Path target) throws IOException {
    Objects.requireNonNull(temporary, "temporary");
    Objects.requireNonNull(target, "target");
    this.temporary = temporary.toAbsolutePath().normalize();
    this.target = target.toAbsolutePath().normalize();
    parent = this.target.getParent();
    if (parent == null || !parent.equals(this.temporary.getParent())
        || Files.isSymbolicLink(this.temporary) || Files.isSymbolicLink(parent)
        || !Files.isRegularFile(this.temporary, LinkOption.NOFOLLOW_LINKS)
        || Files.exists(this.target, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("native namespace publication requires one physical unpublished sibling");
    }
    namespaceIdentity = DurabilitySubject.visibleAscii(
        "namespaceIdentity", this.target.getFileName().toString(), 256, false);
  }

  /** Atomically renames one file-stable subject and issues only visibility evidence. */
  public synchronized DurabilityReceipt rename(DurabilityReceipt prior) throws IOException {
    requirePrior(prior, Kind.FILE_STABLE);
    if (!visibleReceipt.equals("-")) {
      throw new IllegalStateException("native namespace target was already published");
    }
    if (!prior.subject().namespaceIdentity().equals(namespaceIdentity)) {
      throw new IllegalArgumentException("receipt namespace does not match publication target");
    }
    Files.move(temporary, target, StandardCopyOption.ATOMIC_MOVE);
    DurabilityReceipt visible = DurabilityReceiptIssuer.promote(
        prior,
        Kind.NAMESPACE_VISIBLE,
        new DurabilityEvidence(
            Source.ATOMIC_RENAME,
            digest("native-atomic-rename-1\n" + prior.identity() + "\n"
                + namespaceIdentity + "\n"),
            "native-atomic-rename-completed"));
    visibleReceipt = visible.identity();
    return visible;
  }

  /** Forces the containing directory and promotes the exact visible receipt. */
  public synchronized DurabilityReceipt forceNamespace(DurabilityReceipt prior)
      throws IOException {
    requirePrior(prior, Kind.NAMESPACE_VISIBLE);
    if (!prior.identity().equals(visibleReceipt)
        || !Files.isRegularFile(target, LinkOption.NOFOLLOW_LINKS)) {
      throw new IllegalArgumentException("namespace force requires this publication's visible prior");
    }
    try (FileChannel directory = FileChannel.open(parent, StandardOpenOption.READ)) {
      directory.force(true);
    }
    return DurabilityReceiptIssuer.promote(
        prior,
        Kind.NAMESPACE_STABLE,
        new DurabilityEvidence(
            Source.NAMESPACE_FLUSH,
            digest("native-namespace-force-1\n" + prior.identity() + "\n"),
            "native-namespace-force-completed"));
  }

  public String namespaceIdentity() {
    return namespaceIdentity;
  }

  private void requirePrior(DurabilityReceipt prior, Kind expected) {
    Objects.requireNonNull(prior, "prior");
    if (prior.kind() != expected) {
      throw new IllegalArgumentException("namespace publication receipt has the wrong prior kind");
    }
  }

  private static String digest(String canonical) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          canonical.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
