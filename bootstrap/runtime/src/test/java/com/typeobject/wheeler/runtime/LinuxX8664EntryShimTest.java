package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.PlatformAbi;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Native loader entry, mapped capsule discovery, stdout, and exit evidence. */
final class LinuxX8664EntryShimTest {
  @TempDir
  Path temporaryDirectory;

  @Test
  void emitsOneStableImportFreeRuntime() {
    byte[] first = LinuxX8664EntryShim.runtimeText();
    byte[] second = LinuxX8664EntryShim.runtimeText();

    assertArrayEquals(first, second);
    assertEquals(113, first.length);
    assertEquals(
        "220690e44353796c912558f5fddd1680e4828244b899083392b1a0406d0aa954",
        LinuxX8664EntryShim.runtimeIdentity());
    assertEquals(LinuxX8664EntryShim.runtimeIdentity(), identity(first));
    first[0] ^= 1;
    assertFalse(java.util.Arrays.equals(first, LinuxX8664EntryShim.runtimeText()));
  }

  @Test
  void buildsOneCanonicalImageAroundTheMaintainedShim() {
    Fixture fixture = fixture();
    byte[] image = ElfImage.build(
        fixture.plan(),
        fixture.abi(),
        fixture.capsule(),
        LinuxX8664EntryShim.runtimeText(),
        0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());

    assertArrayEquals(LinuxX8664EntryShim.runtimeText(), verified.runtimeText());
    assertEquals(0, verified.runtimeEntryOffset());
    assertEquals(4096, verified.capsuleOffset());
    assertEquals(
        "34c250443a86328faebda523d466779c64ce1d259d21160b4fc217e9718b0a8c",
        verified.prev());
  }

  @Test
  void entersThroughTheLinuxLoaderAndRejectsDamagedMappedFraming() throws Exception {
    assumeNativeHost();
    Fixture fixture = fixture();
    byte[] image = ElfImage.build(
        fixture.plan(),
        fixture.abi(),
        fixture.capsule(),
        LinuxX8664EntryShim.runtimeText(),
        0);
    Path executable = writeExecutable("wheeler-entry", image);

    Launch accepted = launch(executable);
    assertEquals(LinuxX8664EntryShim.SUCCESS_STATUS, accepted.status());
    assertArrayEquals(LinuxX8664EntryShim.successOutput(), accepted.output());
    assertEquals(0, accepted.error().length);

    assertRejectedLaunch(
        "wheeler-entry-bad-locator",
        damaged(image, ElfImage.LOCATOR_FILE_OFFSET));
    assertRejectedLaunch(
        "wheeler-entry-bad-capsule-offset",
        damaged(
            image,
            ElfImage.LOCATOR_FILE_OFFSET + ElfImage.LOCATOR_CAPSULE_OFFSET_FIELD));
    assertRejectedLaunch(
        "wheeler-entry-bad-capsule",
        damaged(image, 4096));
  }

  private void assertRejectedLaunch(String name, byte[] image) throws Exception {
    Launch rejected = launch(writeExecutable(name, image));
    assertEquals(LinuxX8664EntryShim.MALFORMED_IMAGE_STATUS, rejected.status());
    assertEquals(0, rejected.output().length);
    assertEquals(0, rejected.error().length);
  }

  private static byte[] damaged(byte[] source, int offset) {
    byte[] result = source.clone();
    result[offset] ^= 1;
    return result;
  }

  private Path writeExecutable(String name, byte[] bytes) throws IOException {
    Path path = temporaryDirectory.resolve(name);
    Files.write(path, bytes);
    Files.setPosixFilePermissions(path, Set.of(
        PosixFilePermission.OWNER_READ,
        PosixFilePermission.OWNER_WRITE,
        PosixFilePermission.OWNER_EXECUTE));
    return path;
  }

  private static Launch launch(Path executable) throws Exception {
    Process process = new ProcessBuilder(executable.toString()).start();
    assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
    return new Launch(
        process.exitValue(),
        process.getInputStream().readAllBytes(),
        process.getErrorStream().readAllBytes());
  }

  private static void assumeNativeHost() {
    String os = System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT);
    String architecture = System.getProperty("os.arch", "").toLowerCase(java.util.Locale.ROOT);
    assumeTrue(os.equals("linux"));
    assumeTrue(architecture.equals("amd64") || architecture.equals("x86_64"));
  }

  private static Fixture fixture() {
    byte[] runtime = LinuxX8664EntryShim.runtimeText();
    PlatformAbi abi = new PlatformAbi(
        PlatformAbi.Format.ELF,
        "x86_64",
        "linux-gnu",
        64,
        PlatformAbi.Endianness.LITTLE,
        4096,
        16,
        256,
        1024 * 1024,
        4096,
        1024,
        64L * 1024 * 1024,
        List.of("x86-64-v1"),
        List.of(),
        requiredServices());
    CapsuleEntry wbc = new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/app.wbc",
        8,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        new byte[] {'W', 'B', 'C', 1});
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "app",
        wbc.name(),
        "example.app::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        abi.identity(),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of());
    CapsulePackageReceipt receipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.app@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "app",
        hash(1));
    ApplicationCapsule capsule =
        new ApplicationCapsule(root, List.of(receipt), List.of(wbc));
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        wbc.identity(),
        abi.identity(),
        capsule.identity(),
        hash(12),
        identity(runtime),
        hash(13),
        hash(14),
        hash(15),
        hash(16),
        hash(17));
    return new Fixture(abi, capsule, plan);
  }

  private static List<PlatformAbi.Service> requiredServices() {
    return List.of(
        PlatformAbi.Service.CAPABILITY_FILE_OPEN,
        PlatformAbi.Service.DIRECTORY_MANIFEST,
        PlatformAbi.Service.FILE_ATOMIC_REPLACE,
        PlatformAbi.Service.FILE_READ_AT,
        PlatformAbi.Service.MEMORY_PROTECT,
        PlatformAbi.Service.MEMORY_RELEASE,
        PlatformAbi.Service.MEMORY_RESERVE,
        PlatformAbi.Service.PROCESS_ARGUMENTS,
        PlatformAbi.Service.PROCESS_EXIT,
        PlatformAbi.Service.STDERR_WRITE,
        PlatformAbi.Service.STDIN_READ,
        PlatformAbi.Service.STDOUT_WRITE);
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException(exception);
    }
  }

  private record Fixture(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      NativeImagePlan plan) {}

  private record Launch(int status, byte[] output, byte[] error) {}
}
