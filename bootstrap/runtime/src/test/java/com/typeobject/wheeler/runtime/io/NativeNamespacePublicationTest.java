package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.Atomicity;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.FailureModel;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Native atomic-rename and directory-force receipt evidence. */
final class NativeNamespacePublicationTest {
  @Test
  void atomicRenameAndDirectoryForceKeepVisibilityAndStabilityDistinct(@TempDir Path temporary)
      throws Exception {
    Path staged = temporary.resolve("index.next");
    Path target = temporary.resolve("index.current");
    byte[] content = "root-11".getBytes(StandardCharsets.UTF_8);
    DurabilityReceipt fileStable;
    try (NativePositionalFile file = NativePositionalFile.open(
        "native-namespace-file", staged, NativePositionalFile.Rights.READ_WRITE, 128);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(
            new IoLimits(4, 4, 4, 4, 4, 128))) {
      OwnedIoBuffer source = OwnedIoBuffer.copyOf(content);
      NativePositionalFile.WriteCompleted written = scope
          .await(file.writeAt(0, source, 0, content.length))
          .successfulValue()
          .orElseThrow();
      DurabilitySubject subject = new DurabilitySubject(
          file.identity(), 1, 0, content.length, identity(content), "index.current");
      DurabilityProfile profile = new DurabilityProfile(
          FailureModel.PROCESS_CRASH,
          Atomicity.NAMESPACE_ENTRY,
          1,
          1,
          identity("native-namespace-profile".getBytes(StandardCharsets.UTF_8)),
          List.of("filechannel-force-contract"));
      DurabilityReceipt completed = file.writeCompleted(written, subject, profile);
      fileStable = file.forceMetadata(file.forceData(completed));
    }

    NativeNamespacePublication publication = new NativeNamespacePublication(staged, target);
    DurabilityReceipt visible = publication.rename(fileStable);
    assertEquals(Kind.NAMESPACE_VISIBLE, visible.kind());
    assertEquals("index.current", publication.namespaceIdentity());
    assertFalse(Files.exists(staged));
    assertTrue(Files.isRegularFile(target));
    assertArrayEquals(content, Files.readAllBytes(target));
    assertThrows(IllegalStateException.class, () -> publication.rename(fileStable));

    DurabilityReceipt stable = publication.forceNamespace(visible);
    assertEquals(Kind.NAMESPACE_STABLE, stable.kind());
    assertEquals(visible.identity(), stable.parentIdentity());
  }

  private static String identity(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
