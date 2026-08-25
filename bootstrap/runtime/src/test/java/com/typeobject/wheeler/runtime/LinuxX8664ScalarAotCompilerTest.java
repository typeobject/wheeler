package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
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

/** Verified scalar WBC lowering and native process-status evidence. */
final class LinuxX8664ScalarAotCompilerTest {
  @TempDir
  Path temporaryDirectory;

  @Test
  void lowersOneCanonicalScalarProgramDeterministically() {
    byte[] artifact = artifact(42);
    LinuxX8664ScalarAotCompiler.LoweredRuntime first =
        LinuxX8664ScalarAotCompiler.lower(artifact);
    LinuxX8664ScalarAotCompiler.LoweredRuntime second =
        LinuxX8664ScalarAotCompiler.lower(artifact.clone());

    assertEquals(identity(artifact), first.portableArtifact());
    assertEquals(42, first.processStatus());
    assertArrayEquals(first.runtimeText(), second.runtimeText());
    assertArrayEquals(LinuxX8664EntryShim.runtimeText(), first.runtimeText());
    assertEquals(
        "220690e44353796c912558f5fddd1680e4828244b899083392b1a0406d0aa954",
        identity(first.runtimeText()));

    byte[] returned = first.runtimeText();
    returned[0] ^= 1;
    assertFalse(java.util.Arrays.equals(returned, first.runtimeText()));
  }

  @Test
  void bindsTheLoweredRuntimeToTheWbcStatus() {
    var low = LinuxX8664ScalarAotCompiler.lower(artifact(17));
    var high = LinuxX8664ScalarAotCompiler.lower(artifact(73));

    assertEquals(17, low.processStatus());
    assertEquals(73, high.processStatus());
    assertNotEquals(identity(low.runtimeText()), identity(high.runtimeText()));
    assertNotEquals(low.portableArtifact(), high.portableArtifact());
  }

  @Test
  void rejectsProgramsOutsideTheClosedAotProfile() {
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(artifact(125)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(artifact("result", 42, false)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(artifact("status", 42, true)));

    byte[] damaged = artifact(42);
    damaged[damaged.length - 1] ^= 1;
    assertThrows(RuntimeException.class, () -> LinuxX8664ScalarAotCompiler.lower(damaged));
  }

  @Test
  void buildsAndLaunchesOneAotCapsuleImage() throws Exception {
    byte[] artifact = artifact(73);
    LinuxX8664ScalarAotCompiler.LoweredRuntime lowered =
        LinuxX8664ScalarAotCompiler.lower(artifact);
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(),
        fixture.abi(),
        fixture.capsule(),
        lowered.runtimeText(),
        0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());

    assertEquals(NativeImagePlan.RuntimeMode.AOT, fixture.plan().runtimeMode());
    assertArrayEquals(lowered.runtimeText(), verified.runtimeText());
    assertEquals(4096, verified.capsuleOffset());

    if (nativeLinuxHost()) {
      Path executable = writeExecutable(image);
      Process process = new ProcessBuilder(executable.toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(),
          process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  private Path writeExecutable(byte[] image) throws IOException {
    Path path = temporaryDirectory.resolve("scalar-aot");
    Files.write(path, image);
    Files.setPosixFilePermissions(path, Set.of(
        PosixFilePermission.OWNER_READ,
        PosixFilePermission.OWNER_WRITE,
        PosixFilePermission.OWNER_EXECUTE));
    return path;
  }

  private static byte[] artifact(long status) {
    return artifact("status", status, false);
  }

  private static byte[] artifact(String globalName, long status, boolean extraInstruction) {
    List<Instruction> forward = extraInstruction
        ? List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, status),
            Instruction.of(Opcode.NOP),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT))
        : List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, status),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT));
    Program program = new Program(
        "scalar-aot",
        0,
        List.of(new Global(globalName, 0)),
        List.of(new FunctionBody(
            0,
            "example.app::main",
            false,
            0,
            List.of(ValueType.SIGNED),
            null,
            forward,
            List.of())));
    return new BytecodeWriter().write(program);
  }

  private static Fixture fixture(byte[] artifact, byte[] runtime) {
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
        artifact);
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
        NativeImagePlan.RuntimeMode.AOT,
        List.of());
    ApplicationCapsule capsule = new ApplicationCapsule(
        root,
        List.of(new CapsulePackageReceipt(
            hash(8),
            "wheeler.app@1.0.0",
            hash(9),
            "release",
            hash(10),
            hash(11),
            "app",
            hash(1))),
        List.of(wbc));
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.AOT,
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

  private static boolean nativeLinuxHost() {
    String os = System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT);
    String architecture = System.getProperty("os.arch", "").toLowerCase(java.util.Locale.ROOT);
    return os.equals("linux")
        && (architecture.equals("amd64") || architecture.equals("x86_64"));
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException(exception);
    }
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private record Fixture(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      NativeImagePlan plan) {}
}
