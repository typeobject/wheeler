package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.runtime.io.DeterministicIo;
import com.typeobject.wheeler.runtime.io.DurabilityProfile;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt;
import com.typeobject.wheeler.runtime.io.DurabilitySubject;
import com.typeobject.wheeler.runtime.io.IoCompletion;
import com.typeobject.wheeler.runtime.io.IoLimits;
import com.typeobject.wheeler.runtime.io.IoScope;
import com.typeobject.wheeler.runtime.io.NativePositionalFile;
import com.typeobject.wheeler.runtime.io.OwnedIoBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;

/** Abrupt child-process writer used only by transactional index recovery evidence. */
public final class TransactionalIndexCrashWriter {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 128);

  private TransactionalIndexCrashWriter() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      throw new IllegalArgumentException("expected one index path");
    }
    NativePositionalFile file = NativePositionalFile.open(
        "transactional-index",
        Path.of(args[0]),
        NativePositionalFile.Rights.READ_WRITE,
        64);
    IoScope scope = new DeterministicIo(DeterministicIo.Delivery.INLINE).scope(LIMITS);
    DurabilityProfile profile = new DurabilityProfile(
        DurabilityProfile.FailureModel.PROCESS_CRASH,
        DurabilityProfile.Atomicity.RANGE,
        1,
        1,
        identity("transactional-index-profile".getBytes(StandardCharsets.UTF_8)),
        List.of("filechannel-force-contract"));

    writeAndForce(file, scope, profile, 0, new byte[] {7, 0, 1}, true);
    writeAndForce(file, scope, profile, 3, new byte[] {11, 1}, false);
    writeAndForce(file, scope, profile, 5, new byte[] {1}, true);
    writeAndForce(file, scope, profile, 6, new byte[] {19, 2}, false);
    Runtime.getRuntime().halt(0);
  }

  private static void writeAndForce(
      NativePositionalFile file,
      IoScope scope,
      DurabilityProfile profile,
      long position,
      byte[] bytes,
      boolean metadata) throws Exception {
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(bytes);
    IoCompletion<NativePositionalFile.WriteCompleted> completion =
        scope.await(file.writeAt(position, source, 0, bytes.length));
    DurabilitySubject subject = new DurabilitySubject(
        file.identity(),
        position,
        position,
        bytes.length,
        identity(bytes),
        "-");
    DurabilityReceipt completed = file.writeCompleted(
        completion.successfulValue().orElseThrow(), subject, profile);
    DurabilityReceipt stable = file.forceData(completed);
    if (metadata) {
      file.forceMetadata(stable);
    }
  }

  private static String identity(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
