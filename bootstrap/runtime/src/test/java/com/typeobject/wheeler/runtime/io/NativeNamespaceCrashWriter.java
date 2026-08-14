package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.Atomicity;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.FailureModel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;

/** Child process that halts immediately after a native namespace force. */
public final class NativeNamespaceCrashWriter {
  private NativeNamespaceCrashWriter() {}

  public static void main(String[] arguments) throws Exception {
    if (arguments.length != 1) {
      throw new IllegalArgumentException("expected one namespace directory");
    }
    Path directory = Path.of(arguments[0]);
    Path staged = directory.resolve("release.next");
    byte[] content = "release-23".getBytes(StandardCharsets.UTF_8);
    DurabilityReceipt fileStable;
    try (NativePositionalFile file = NativePositionalFile.open(
        "namespace-crash-file", staged, NativePositionalFile.Rights.READ_WRITE, 128);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(
            new IoLimits(4, 4, 4, 4, 4, 128))) {
      NativePositionalFile.WriteCompleted written = scope
          .await(file.writeAt(0, OwnedIoBuffer.copyOf(content), 0, content.length))
          .successfulValue()
          .orElseThrow();
      DurabilitySubject subject = new DurabilitySubject(
          file.identity(), 1, 0, content.length, identity(content), "release.current");
      DurabilityProfile profile = new DurabilityProfile(
          FailureModel.PROCESS_CRASH,
          Atomicity.NAMESPACE_ENTRY,
          1,
          1,
          identity("namespace-crash-profile".getBytes(StandardCharsets.UTF_8)),
          List.of("filechannel-force-contract"));
      fileStable = file.forceMetadata(file.forceData(file.writeCompleted(
          written, subject, profile)));
    }
    NativeNamespacePublication publication = new NativeNamespacePublication(
        staged, directory.resolve("release.current"));
    publication.forceNamespace(publication.rename(fileStable));
    Runtime.getRuntime().halt(23);
  }

  private static String identity(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
