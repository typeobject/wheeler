package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.MachOImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.NativeImageSigningRecord;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PeImage;
import com.typeobject.wheeler.packageformat.RepositoryNativeImageSignature;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.PlatformAbi;
import com.typeobject.wheeler.packageformat.UnsignedNativeImageRecord;
import com.typeobject.wheeler.runtime.LinuxX8664EntryShim;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Command evidence for nonexecuting application capsule inspection and verification. */
final class ImageCommandTest {
  @TempDir
  Path temporary;

  @Test
  void publishesTheMaintainedLinuxRuntimeAtomically() throws Exception {
    Path runtime = temporary.resolve("runtime.bin");
    CommandResult first = execute(
        "image", "runtime-elf-x86-64", "-o", runtime.toString());

    assertEquals(0, first.status());
    assertArrayEquals(LinuxX8664EntryShim.runtimeText(), Files.readAllBytes(runtime));
    assertTrue(first.output().contains(LinuxX8664EntryShim.runtimeIdentity()));
    assertEquals("", first.error());

    Files.write(runtime, new byte[] {1, 2, 3});
    CommandResult replacement = execute(
        "image", "runtime-elf-x86-64", "-o", runtime.toString());
    assertEquals(0, replacement.status());
    assertArrayEquals(LinuxX8664EntryShim.runtimeText(), Files.readAllBytes(runtime));
  }

  @Test
  void lowersBuildsAndLaunchesOnePhysicalScalarAotImage() throws Exception {
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.hello", """
            module example.hello;
            classical class Hello {
              state long status = 0;

              long code(long left, long right) {
                return left + right;
              }

              void check(long value) {
                assert(value == 73);
              }

              void copy(
                borrow byteview input,
                borrow mut bytes output
              ) {
                long length = bufferLength(input);
                long index = 0;
                while (index < length) limit 4096 {
                  setByte(output, index, input[index]);
                  index += 1;
                }
              }

              entry void main(
                borrow byteview input,
                borrow mut bytes output
              ) {
                status = 70;
                long seed = status;
                long result = code(seed, 0);
                while (result < 73) limit 3 {
                  result += 1;
                }
                check(result);
                long outputLength = bufferLength(input);
                setOutputLength(output, outputLength);
                copy(input, output);
                status = result;
              }
            }
            """),
        "example.hello");
    Path artifactFile = write("scalar-aot.wbc", artifact);
    PlatformAbi abi = platformAbi();
    ApplicationCapsule capsule = nativeCapsule(
        artifact, abi, NativeImagePlan.RuntimeMode.AOT);
    Path capsuleFile = write("scalar-aot.capsule", capsule.canonicalBytes());
    Path runtimeFile = temporary.resolve("scalar-aot-runtime.bin");
    CommandResult lowering = execute(
        "image", "runtime-elf-x86-64-aot", artifactFile.toString(),
        "--capsule", capsuleFile.toString(), "-o", runtimeFile.toString());
    byte[] runtime = Files.readAllBytes(runtimeFile);
    assertEquals(0, lowering.status());
    assertTrue(lowering.output().contains(identity(artifact)));
    assertTrue(lowering.output().contains("input-dependent status"));
    assertTrue(lowering.output().contains("dynamic stdin/stdout"));

    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.AOT,
        true,
        true,
        capsule.entries().getFirst().identity(),
        abi.identity(),
        capsule.identity(),
        hash(92),
        identity(runtime),
        hash(93),
        hash(94),
        hash(95),
        hash(96),
        hash(97));
    Path planFile = write("scalar-aot-plan.yaml", plan.canonicalBytes());
    Path abiFile = write("scalar-aot-abi.yaml", abi.canonicalBytes());
    Path imageFile = temporary.resolve("scalar-aot-app");
    CommandResult build = execute(
        "image", "build-elf", capsuleFile.toString(),
        "--runtime", runtimeFile.toString(),
        "--entry", "0",
        "--plan", planFile.toString(),
        "--abi", abiFile.toString(),
        "-o", imageFile.toString());
    assertEquals(0, build.status());
    ElfImage.verify(Files.readAllBytes(imageFile), plan, abi);

    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(imageFile.toString()).start();
      process.getOutputStream().write(
          "Native\n".getBytes(StandardCharsets.US_ASCII));
      process.getOutputStream().close();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, process.exitValue());
      assertArrayEquals(
          "Native\n".getBytes(StandardCharsets.US_ASCII),
          process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void inspectsEveryRootReceiptAndEntryIdentityDeterministically() throws Exception {
    ApplicationCapsule capsule = capsule(validWbc(), null);
    Path file = write("hello.capsule", capsule.canonicalBytes());
    CommandResult first = execute("image", "inspect", file.toString());
    CommandResult second = execute("image", "inspect", file.toString());

    assertEquals(0, first.status());
    assertEquals(first.output(), second.output());
    assertTrue(first.output().startsWith("{\n  \"schema\": 1,\n"));
    assertTrue(first.output().contains("\"identity\": \"" + capsule.identity() + "\""));
    assertTrue(first.output().contains("\"entry\": \"example.hello::main\""));
    assertTrue(first.output().contains("\"coordinate\": \"wheeler.hello@1.0.0\""));
    assertTrue(first.output().contains("\"name\": \"resources/greeting.txt\""));
    assertEquals("", first.error());
  }

  @Test
  void verifiesEveryWbcAndTheExactRootFunction() throws Exception {
    byte[] wbc = validWbc();
    ApplicationCapsule capsule = capsule(wbc, null);
    Path file = write("hello.capsule", capsule.canonicalBytes());
    CommandResult result = execute("image", "verify", file.toString());

    assertEquals(0, result.status());
    assertEquals(
        "verified capsule " + capsule.identity() + " (2 entries, 1 WBC artifacts)\n",
        result.output());
    assertEquals("", result.error());

    CapsuleRoot wrongRoot = root("example.hello::other");
    Path wrong = write(
        "wrong-root.capsule",
        new ApplicationCapsule(wrongRoot, receipts(), entries(wbc)).canonicalBytes());
    assertThrows(
        IllegalArgumentException.class,
        () -> execute("image", "verify", wrong.toString()));
  }

  @Test
  void inspectionDoesNotLaunderMalformedWbcOrCapsuleBytes() throws Exception {
    ApplicationCapsule malformedWbc = capsule(new byte[] {'W', 'B', 'C', 1}, "fixture::main");
    Path malformed = write("malformed-wbc.capsule", malformedWbc.canonicalBytes());

    assertEquals(0, execute("image", "inspect", malformed.toString()).status());
    assertThrows(
        BytecodeException.class,
        () -> execute("image", "verify", malformed.toString()));

    byte[] corrupted = malformedWbc.canonicalBytes();
    corrupted[corrupted.length - 1] ^= 1;
    Path damaged = write("damaged.capsule", corrupted);
    assertThrows(
        PackageFormatException.class,
        () -> execute("image", "inspect", damaged.toString()));
  }

  @Test
  void lowersSharedScalarStateThroughHelpers() throws Exception {
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.state", """
            module example.state;
            classical class SharedState {
              state long status = 0;
              state long counter = 40;
              state long mask = 3;

              long update() {
                counter += 1;
                return counter ^ mask;
              }

              entry void main() {
                long result = update();
                result = update();
                status = result;
              }
            }
            """),
        "example.state");
    Path artifactFile = write("shared-state.wbc", artifact);
    Path capsuleFile = writeAotCapsule("shared-state.capsule", artifact);
    Path runtimeFile = temporary.resolve("shared-state.bin");

    CommandResult lowering = execute(
        "image", "runtime-elf-x86-64-aot", artifactFile.toString(),
        "--capsule", capsuleFile.toString(), "-o", runtimeFile.toString());

    assertEquals(0, lowering.status());
    assertTrue(lowering.output().contains("status 41"));
    assertTrue(Files.size(runtimeFile) > 0);
  }

  @Test
  void lowersStrictUtf8ThroughBorrowedHelpers() throws Exception {
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.utf8", """
            module example.utf8;
            classical class Utf8Input {
              state long status = 0;

              void validate(borrow utf8 input) {
                assert(utf8Valid(input));
                assert(utf8Count(input) == 4);
              }

              long asciiWidth(borrow utf8 input) {
                assert(utf8Scalar(input, 0) == 0x41);
                return utf8Width(input, 0);
              }

              long twoByteWidth(borrow utf8 input) {
                assert(utf8Scalar(input, 1) == 0xa2);
                return utf8Width(input, 1);
              }

              long threeByteWidth(borrow utf8 input) {
                assert(utf8Scalar(input, 3) == 0x20ac);
                return utf8Width(input, 3);
              }

              long fourByteWidth(borrow utf8 input) {
                assert(utf8Scalar(input, 6) == 0x1f642);
                return utf8Width(input, 6);
              }

              entry void main(
                borrow utf8 input,
                borrow mut bytes output
              ) {
                validate(input);
                long first = asciiWidth(input);
                long second = twoByteWidth(input);
                long third = threeByteWidth(input);
                long fourth = fourByteWidth(input);
                assert(first + second + third + fourth == 10);
                setByte(output, 0, fourth);
                setOutputLength(output, 1);
                status = fourth;
              }
            }
            """),
        "example.utf8");
    Path artifactFile = write("utf8-helper.wbc", artifact);
    Path capsuleFile = writeAotCapsule("utf8-helper.capsule", artifact);
    Path runtimeFile = temporary.resolve("utf8-helper.bin");

    CommandResult lowering = execute(
        "image", "runtime-elf-x86-64-aot", artifactFile.toString(),
        "--capsule", capsuleFile.toString(), "-o", runtimeFile.toString());

    assertEquals(0, lowering.status());
    assertTrue(lowering.output().contains("input-dependent status"));
    assertTrue(lowering.output().contains("dynamic stdin/stdout"));
    assertTrue(Files.size(runtimeFile) > 0);
  }

  @Test
  void lowersConstantOutputThroughOneBorrowedHelper() throws Exception {
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.output", """
            module example.output;
            classical class Output {
              state long status = 0;

              void write(borrow mut bytes output) {
                setByte(output, 0, 88);
              }

              entry void main(borrow mut bytes output) {
                setOutputLength(output, 1);
                write(output);
                status = 73;
              }
            }
            """),
        "example.output");
    Path artifactFile = write("constant-helper.wbc", artifact);
    Path capsuleFile = writeAotCapsule("constant-helper.capsule", artifact);
    Path runtimeFile = temporary.resolve("constant-helper.bin");

    CommandResult lowering = execute(
        "image", "runtime-elf-x86-64-aot", artifactFile.toString(),
        "--capsule", capsuleFile.toString(), "-o", runtimeFile.toString());

    assertEquals(0, lowering.status());
    assertTrue(lowering.output().contains("status 73"));
    assertTrue(lowering.output().contains("output 1 bytes"));
    assertTrue(Files.size(runtimeFile) > 0);
  }

  @Test
  void buildsInspectsVerifiesAndLaunchesOneCompleteElf() throws Exception {
    Path runtimeFile = temporary.resolve("runtime.bin");
    CommandResult runtimePublication = execute(
        "image", "runtime-elf-x86-64", "-o", runtimeFile.toString());
    assertEquals(0, runtimePublication.status());
    byte[] runtime = Files.readAllBytes(runtimeFile);
    PlatformAbi abi = platformAbi();
    ApplicationCapsule capsule = nativeCapsule(validWbc(), abi);
    CapsuleEntry rootWbc = capsule.entries().getFirst();
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        rootWbc.identity(),
        abi.identity(),
        capsule.identity(),
        hash(20),
        identity(runtime),
        hash(21),
        hash(22),
        hash(23),
        hash(24),
        hash(25));
    Path capsuleFile = write("app.capsule", capsule.canonicalBytes());
    Path planFile = write("native-image.yaml", plan.canonicalBytes());
    Path abiFile = write("platform-abi.yaml", abi.canonicalBytes());
    Path imageFile = temporary.resolve("app");

    CommandResult build = execute(
        "image", "build-elf", capsuleFile.toString(),
        "--runtime", runtimeFile.toString(),
        "--entry", "0",
        "--plan", planFile.toString(),
        "--abi", abiFile.toString(),
        "-o", imageFile.toString());
    byte[] expected = ElfImage.build(plan, abi, capsule, runtime, 0);
    assertEquals(0, build.status());
    assertArrayEquals(expected, Files.readAllBytes(imageFile));
    assertTrue(Files.isExecutable(imageFile));
    assertTrue(build.output().contains(ElfImage.verify(expected, plan, abi).prev()));

    CommandResult inspect = execute(
        "image", "inspect-elf", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertInspection(inspect, "elf", expected.length, runtime.length, 4096);

    CommandResult verify = execute(
        "image", "verify-elf", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertEquals(0, verify.status());
    assertTrue(verify.output().startsWith("verified ELF "));
    assertTrue(verify.output().contains("1 WBC artifacts"));

    Path outputRecordFile = temporary.resolve("unsigned-elf.yaml");
    CommandResult outputRecord = execute(
        "image", "record-elf", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString(),
        "-o", outputRecordFile.toString());
    UnsignedNativeImageRecord unsigned =
        UnsignedNativeImageRecord.parse(Files.readAllBytes(outputRecordFile));
    assertEquals(0, outputRecord.status());
    assertEquals(UnsignedNativeImageRecord.from(expected, plan, abi), unsigned);
    assertTrue(outputRecord.output().contains(unsigned.identity()));

    KeyPair key = KeyPairGenerator.getInstance("Ed25519").generateKeyPair();
    RepositoryNativeImageSignature authorization = RepositoryNativeImageSignature.sign(
        hash(90), unsigned, expected, key.getPrivate(), key.getPublic());
    Path signatureFile = write("elf.sig", authorization.canonicalBytes());
    RepositoryPolicy policy = new RepositoryPolicy(
        RepositoryPolicy.SCHEMA_VERSION,
        List.of(new RepositoryPolicy.Repository(
            "release",
            hash(90),
            RepositoryPolicy.Transport.FILE,
            temporary.toString(),
            true,
            List.of("*"),
            List.of(RepositoryPolicy.TrustedKey.from(key.getPublic())))));
    Path policyFile = write("repositories.yaml", policy.canonicalText().getBytes(StandardCharsets.UTF_8));
    Path signingRecordFile = temporary.resolve("signed-elf.yaml");
    CommandResult signingRecord = execute(
        "image", "record-repository-signing", outputRecordFile.toString(),
        "--unsigned", imageFile.toString(),
        "--policy", policyFile.toString(),
        "--repository", "release",
        "--signature", signatureFile.toString(),
        "--tool", hash(91),
        "-o", signingRecordFile.toString());
    NativeImageSigningRecord signing =
        NativeImageSigningRecord.parse(Files.readAllBytes(signingRecordFile));
    assertEquals(0, signingRecord.status());
    assertTrue(signingRecord.output().contains(signing.identity()));
    signing.verifyRepositoryDetached(
        hash(90), unsigned, expected, authorization, key.getPublic());

    Path opaqueOutput = temporary.resolve("opaque-signing.yaml");
    assertThrows(
        PackageFormatException.class,
        () -> execute(
            "image", "record-signing", outputRecordFile.toString(),
            "--unsigned", imageFile.toString(),
            "--method", "repository-detached",
            "--distribution", imageFile.toString(),
            "--signature", signatureFile.toString(),
            "--signer", authorization.keyIdentity(),
            "--tool", hash(91),
            "-o", opaqueOutput.toString()));
    assertFalse(Files.exists(opaqueOutput));

    RepositoryPolicy untrustedPolicy = new RepositoryPolicy(
        RepositoryPolicy.SCHEMA_VERSION,
        List.of(new RepositoryPolicy.Repository(
            "release",
            hash(90),
            RepositoryPolicy.Transport.FILE,
            temporary.toString(),
            true,
            List.of("*"),
            List.of())));
    Path untrustedPolicyFile = write(
        "untrusted-repositories.yaml",
        untrustedPolicy.canonicalText().getBytes(StandardCharsets.UTF_8));
    Path untrustedOutput = temporary.resolve("untrusted-signing.yaml");
    assertThrows(
        IllegalArgumentException.class,
        () -> execute(
            "image", "record-repository-signing", outputRecordFile.toString(),
            "--unsigned", imageFile.toString(),
            "--policy", untrustedPolicyFile.toString(),
            "--repository", "release",
            "--signature", signatureFile.toString(),
            "--tool", hash(91),
            "-o", untrustedOutput.toString()));
    assertFalse(Files.exists(untrustedOutput));

    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(imageFile.toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(LinuxX8664EntryShim.SUCCESS_STATUS, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(),
          process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }

    Path victim = write("victim", new byte[] {7, 8, 9});
    Path linkedOutput = temporary.resolve("linked-output");
    Files.createSymbolicLink(linkedOutput, victim.getFileName());
    assertThrows(
        IOException.class,
        () -> execute(
            "image", "build-elf", capsuleFile.toString(),
            "--runtime", runtimeFile.toString(),
            "--entry", "0",
            "--plan", planFile.toString(),
            "--abi", abiFile.toString(),
            "-o", linkedOutput.toString()));
    assertTrue(Files.isSymbolicLink(linkedOutput));
    assertArrayEquals(new byte[] {7, 8, 9}, Files.readAllBytes(victim));

    byte[] damaged = expected.clone();
    damaged[damaged.length - 1] ^= 1;
    Path damagedFile = write("damaged-elf", damaged);
    assertThrows(
        PackageFormatException.class,
        () -> execute(
            "image", "verify-elf", damagedFile.toString(),
            "--plan", planFile.toString(),
            "--abi", abiFile.toString()));
  }

  @Test
  void buildsAndVerifiesOneCompleteMachOFromPhysicalInputs() throws Exception {
    byte[] runtime = {
        0x00, 0x00, (byte) 0x80, (byte) 0xd2,
        0x01, 0x00, 0x00, (byte) 0xd4
    };
    PlatformAbi abi = platformAbi(
        PlatformAbi.Format.MACH_O, "aarch64", "darwin", "libsystem");
    ApplicationCapsule capsule = nativeCapsule(validWbc(), abi);
    CapsuleEntry rootWbc = capsule.entries().getFirst();
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.MACH_O,
        "aarch64-apple-darwin",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        rootWbc.identity(),
        abi.identity(),
        capsule.identity(),
        hash(30),
        identity(runtime),
        hash(31),
        hash(32),
        hash(33),
        hash(34),
        hash(35));
    Path capsuleFile = write("mac.capsule", capsule.canonicalBytes());
    Path runtimeFile = write("runtime-arm64.bin", runtime);
    Path planFile = write("native-image-mac.yaml", plan.canonicalBytes());
    Path abiFile = write("platform-abi-mac.yaml", abi.canonicalBytes());
    Path imageFile = temporary.resolve("mac-app");

    CommandResult build = execute(
        "image", "build-macho", capsuleFile.toString(),
        "--runtime", runtimeFile.toString(),
        "--entry", "0",
        "--plan", planFile.toString(),
        "--abi", abiFile.toString(),
        "-o", imageFile.toString());
    byte[] expected = MachOImage.build(plan, abi, capsule, runtime, 0);
    assertEquals(0, build.status());
    assertArrayEquals(expected, Files.readAllBytes(imageFile));
    assertTrue(Files.isExecutable(imageFile));
    assertTrue(build.output().contains(MachOImage.verify(expected, plan, abi).prev()));

    CommandResult inspect = execute(
        "image", "inspect-macho", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertInspection(inspect, "mach-o", expected.length, runtime.length, 4096);

    CommandResult verify = execute(
        "image", "verify-macho", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertEquals(0, verify.status());
    assertTrue(verify.output().startsWith("verified Mach-O "));
    assertTrue(verify.output().contains("1 WBC artifacts"));
    assertOutputRecord(
        "record-macho", "unsigned-mach-o.yaml", imageFile, planFile, abiFile,
        UnsignedNativeImageRecord.from(expected, plan, abi));
  }

  @Test
  void buildsAndVerifiesOneCompletePeFromPhysicalInputs() throws Exception {
    byte[] runtime = {(byte) 0xb8, 0x2a, 0, 0, 0, (byte) 0xc3};
    PlatformAbi abi = platformAbi(
        PlatformAbi.Format.PE_COFF, "x86_64", "windows-msvc", "kernel32");
    ApplicationCapsule capsule = nativeCapsule(validWbc(), abi);
    CapsuleEntry rootWbc = capsule.entries().getFirst();
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.PE_COFF,
        "x86_64-pc-windows-msvc",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        rootWbc.identity(),
        abi.identity(),
        capsule.identity(),
        hash(40),
        identity(runtime),
        hash(41),
        hash(42),
        hash(43),
        hash(44),
        hash(45));
    Path capsuleFile = write("windows.capsule", capsule.canonicalBytes());
    Path runtimeFile = write("runtime-x86_64-windows.bin", runtime);
    Path planFile = write("native-image-windows.yaml", plan.canonicalBytes());
    Path abiFile = write("platform-abi-windows.yaml", abi.canonicalBytes());
    Path imageFile = temporary.resolve("app.exe");

    CommandResult build = execute(
        "image", "build-pe", capsuleFile.toString(),
        "--runtime", runtimeFile.toString(),
        "--entry", "0",
        "--plan", planFile.toString(),
        "--abi", abiFile.toString(),
        "-o", imageFile.toString());
    byte[] expected = PeImage.build(plan, abi, capsule, runtime, 0);
    assertEquals(0, build.status());
    assertArrayEquals(expected, Files.readAllBytes(imageFile));
    assertTrue(Files.isExecutable(imageFile));
    assertTrue(build.output().contains(PeImage.verify(expected, plan, abi).prev()));

    CommandResult inspect = execute(
        "image", "inspect-pe", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertInspection(inspect, "pe", expected.length, runtime.length, 1024);

    CommandResult verify = execute(
        "image", "verify-pe", imageFile.toString(),
        "--plan", planFile.toString(),
        "--abi", abiFile.toString());
    assertEquals(0, verify.status());
    assertTrue(verify.output().startsWith("verified PE "));
    assertTrue(verify.output().contains("1 WBC artifacts"));
    assertOutputRecord(
        "record-pe", "unsigned-pe.yaml", imageFile, planFile, abiFile,
        UnsignedNativeImageRecord.from(expected, plan, abi));
  }

  @Test
  void rejectsUsageAndNonphysicalInput() throws Exception {
    CommandResult usage = execute("image", "run", "missing.capsule");
    assertEquals(2, usage.status());
    assertTrue(usage.error().startsWith(
        "Usage: wheeler image <inspect|verify> <application.capsule>\n"));
    assertTrue(usage.error().contains("build-elf"));
    assertTrue(usage.error().contains("verify-elf"));
    assertTrue(usage.error().contains("build-macho"));
    assertTrue(usage.error().contains("verify-macho"));
    assertTrue(usage.error().contains("build-pe"));
    assertTrue(usage.error().contains("verify-pe"));
    assertTrue(usage.error().contains("inspect-elf"));
    assertTrue(usage.error().contains("inspect-macho"));
    assertTrue(usage.error().contains("inspect-pe"));
    assertTrue(usage.error().contains("runtime-elf-x86-64"));
    assertTrue(usage.error().contains("runtime-elf-x86-64-aot"));
    assertTrue(usage.error().contains("record-elf"));
    assertTrue(usage.error().contains("record-macho"));
    assertTrue(usage.error().contains("record-pe"));
    assertTrue(usage.error().contains("record-signing"));
    assertTrue(usage.error().contains("record-repository-signing"));

    Path unbound = write("unbound.wbc", validWbc());
    CommandResult unboundResult = execute(
        "image", "runtime-elf-x86-64-aot", unbound.toString(),
        "-o", temporary.resolve("unbound.bin").toString());
    assertEquals(2, unboundResult.status());
    assertFalse(Files.exists(temporary.resolve("unbound.bin")));

    Path directory = Files.createDirectory(temporary.resolve("directory.capsule"));
    assertThrows(
        IOException.class,
        () -> execute("image", "inspect", directory.toString()));
  }

  private ApplicationCapsule capsule(byte[] wbc, String entryOverride) {
    Program program = null;
    if (entryOverride == null) {
      program = new BytecodeReader().read(wbc);
    }
    String entry = entryOverride == null
        ? program.function(program.entryFunctionId()).name()
        : entryOverride;
    return new ApplicationCapsule(root(entry), receipts(), entries(wbc));
  }

  private CapsuleRoot root(String entry) {
    return new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        entry,
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of("io:stdout/1"));
  }

  private static List<CapsulePackageReceipt> receipts() {
    return List.of(new CapsulePackageReceipt(
        hash(8),
        "wheeler.hello@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "hello",
        hash(1)));
  }

  private static List<CapsuleEntry> entries(byte[] wbc) {
    return List.of(
        new CapsuleEntry(
            CapsuleEntry.Kind.RESOURCE,
            "resources/greeting.txt",
            64,
            CapsuleEntry.REQUIRED,
            "hello\n".getBytes(StandardCharsets.UTF_8)),
        new CapsuleEntry(
            CapsuleEntry.Kind.WBC,
            "bin/hello.wbc",
            4096,
            CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
            wbc));
  }

  private static ApplicationCapsule nativeCapsule(byte[] wbc, PlatformAbi abi) {
    return nativeCapsule(wbc, abi, NativeImagePlan.RuntimeMode.EMBEDDED_VM);
  }

  private static ApplicationCapsule nativeCapsule(
      byte[] wbc,
      PlatformAbi abi,
      NativeImagePlan.RuntimeMode runtimeMode) {
    Program program = new BytecodeReader().read(wbc);
    int parameters = program.function(program.entryFunctionId()).parameterCount();
    List<String> capabilities = runtimeMode != NativeImagePlan.RuntimeMode.AOT
        || parameters == 0 ? List.of()
        : parameters == 1 ? List.of("io:stdout/1")
        : List.of("io:stdin/1", "io:stdout/1");
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        program.function(program.entryFunctionId()).name(),
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        abi.identity(),
        hash(7),
        runtimeMode,
        capabilities);
    CapsuleEntry entry = new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        root.rootWbc(),
        8,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        wbc);
    return new ApplicationCapsule(root, receipts(), List.of(entry));
  }

  private static PlatformAbi platformAbi() {
    return platformAbi(PlatformAbi.Format.ELF, "x86_64", "linux-gnu", "libc.so.6");
  }

  private static PlatformAbi platformAbi(
      PlatformAbi.Format format,
      String architecture,
      String osAbi,
      String library) {
    return new PlatformAbi(
        format,
        architecture,
        osAbi,
        64,
        PlatformAbi.Endianness.LITTLE,
        4096,
        16,
        256,
        1024 * 1024,
        4096,
        1024,
        64L * 1024 * 1024,
        List.of("baseline"),
        List.of(library),
        List.of(
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
            PlatformAbi.Service.STDOUT_WRITE));
  }

  private static byte[] validWbc() {
    String source = """
        module example.hello;
        classical class Hello {
          entry void main() {}
        }
        """;
    return new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.hello", source), "example.hello");
  }

  private Path writeAotCapsule(String name, byte[] artifact) throws IOException {
    ApplicationCapsule capsule = nativeCapsule(
        artifact, platformAbi(), NativeImagePlan.RuntimeMode.AOT);
    return write(name, capsule.canonicalBytes());
  }

  private Path write(String name, byte[] bytes) throws IOException {
    Path path = temporary.resolve(name);
    Files.write(path, bytes);
    return path;
  }

  private static CommandResult execute(String... arguments) throws Exception {
    ByteArrayOutputStream outputBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream errorBytes = new ByteArrayOutputStream();
    try (PrintStream output = new PrintStream(outputBytes, true, StandardCharsets.UTF_8);
        PrintStream error = new PrintStream(errorBytes, true, StandardCharsets.UTF_8)) {
      int status = Wheeler.execute(arguments, output, error);
      return new CommandResult(
          status,
          outputBytes.toString(StandardCharsets.UTF_8),
          errorBytes.toString(StandardCharsets.UTF_8));
    }
  }

  private void assertOutputRecord(
      String command,
      String outputName,
      Path image,
      Path plan,
      Path abi,
      UnsignedNativeImageRecord expected) throws Exception {
    Path output = temporary.resolve(outputName);
    CommandResult result = execute(
        "image", command, image.toString(),
        "--plan", plan.toString(),
        "--abi", abi.toString(),
        "-o", output.toString());
    assertEquals(0, result.status());
    UnsignedNativeImageRecord actual =
        UnsignedNativeImageRecord.parse(Files.readAllBytes(output));
    assertEquals(expected, actual);
    assertTrue(result.output().contains(actual.identity()));
  }

  private static boolean nativeLinuxHost() {
    String os = System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT);
    String architecture = System.getProperty("os.arch", "").toLowerCase(java.util.Locale.ROOT);
    return os.equals("linux")
        && (architecture.equals("amd64") || architecture.equals("x86_64"));
  }

  private static void assertInspection(
      CommandResult result,
      String format,
      int imageBytes,
      int runtimeBytes,
      int capsuleOffset) {
    assertEquals(0, result.status());
    assertTrue(result.output().startsWith("{\n  \"format\": \"" + format + "\","));
    assertTrue(result.output().contains("\n  \"bytes\": " + imageBytes + ","));
    assertTrue(result.output().contains("\n  \"runtime-bytes\": " + runtimeBytes + ","));
    assertTrue(result.output().contains("\n  \"runtime-entry-offset\": 0,"));
    assertTrue(result.output().contains("\n  \"capsule-offset\": " + capsuleOffset + "\n"));
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

  private record CommandResult(int status, String output, String error) {}
}
