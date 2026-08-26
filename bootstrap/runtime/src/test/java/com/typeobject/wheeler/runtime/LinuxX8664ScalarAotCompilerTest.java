package com.typeobject.wheeler.runtime;

import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.arithmeticArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.booleanParameterArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.cyclicHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.conditionalArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dormantUnsupportedHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.executionBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.forwardHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.helperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.invalidOutputWriteArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.loopArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.outputArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.parameterHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.parameterVoidHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.scalarGlobalArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.selfCallingHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.stateCheckArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.uncheckedBackwardBranchArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.utf8IoArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.voidHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.zeroOutputArtifact;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.runtime.aot.ScalarAotMachine;
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
    assertFalse(first.writesApplicationOutput());
    assertThrows(IllegalStateException.class, first::applicationOutput);
    assertArrayEquals(first.runtimeText(), second.runtimeText());
    assertNotEquals(
        identity(LinuxX8664EntryShim.runtimeText()),
        identity(first.runtimeText()));
    assertEquals(
        "8fec2bdc281a22469752ddefb169a213c59f3c3d3623833a4932a9dd358ab4c3",
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
  void lowersCheckedArithmeticAndBitwiseOperations() {
    for (ArithmeticCase operation : List.of(
        new ArithmeticCase(Opcode.LOCAL_ADD, 34, 8),
        new ArithmeticCase(Opcode.LOCAL_SUB, 50, 8),
        new ArithmeticCase(Opcode.LOCAL_MUL, 6, 7),
        new ArithmeticCase(Opcode.LOCAL_DIV, 84, 2),
        new ArithmeticCase(Opcode.LOCAL_MOD, 100, 58),
        new ArithmeticCase(Opcode.LOCAL_AND, 47, 58),
        new ArithmeticCase(Opcode.LOCAL_XOR, 16, 58),
        new ArithmeticCase(Opcode.LOCAL_ROTR32, 0x540, 5))) {
      var lowered = LinuxX8664ScalarAotCompiler.lower(
          arithmeticArtifact(operation.opcode(), operation.left(), operation.right()));
      assertEquals(42, lowered.processStatus());
      assertNotEquals(
          identity(LinuxX8664ScalarAotCompiler.lower(artifact(42)).runtimeText()),
          lowered.runtimeIdentity());
    }
  }

  @Test
  void lowersComparisonsAndForwardConditionalBranches() {
    var less = LinuxX8664ScalarAotCompiler.lower(
        conditionalArtifact(Opcode.LOCAL_LT, 70, 71));
    var notLess = LinuxX8664ScalarAotCompiler.lower(
        conditionalArtifact(Opcode.LOCAL_LT, 71, 70));
    var equal = LinuxX8664ScalarAotCompiler.lower(
        conditionalArtifact(Opcode.LOCAL_EQ, 73, 73));
    var unequal = LinuxX8664ScalarAotCompiler.lower(
        conditionalArtifact(Opcode.LOCAL_EQ, 73, 74));

    assertEquals(73, less.processStatus());
    assertEquals(74, notLess.processStatus());
    assertEquals(73, equal.processStatus());
    assertEquals(74, unequal.processStatus());
    assertNotEquals(less.runtimeIdentity(), notLess.runtimeIdentity());
    assertNotEquals(equal.runtimeIdentity(), unequal.runtimeIdentity());
  }

  @Test
  void lowersStatusStateRotationsAndAssertions() {
    var lowered = LinuxX8664ScalarAotCompiler.lower(stateCheckArtifact(42));
    var terminalRotation = LinuxX8664ScalarAotCompiler.lower(
        arithmeticArtifact(Opcode.LOCAL_ROTR32, 0x8000_0000L, 31));

    assertEquals(73, lowered.processStatus());
    assertEquals(1, terminalRotation.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(stateCheckArtifact(41)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            arithmeticArtifact(Opcode.LOCAL_ROTR32, 42, 32)));
  }

  @Test
  void lowersBoundedScalarLoops() {
    var shortLoop = LinuxX8664ScalarAotCompiler.lower(loopArtifact(3, 70));
    var terminalBound = LinuxX8664ScalarAotCompiler.lower(loopArtifact(4096, -4023));

    assertEquals(73, shortLoop.processStatus());
    assertEquals(73, terminalBound.processStatus());
    assertNotEquals(shortLoop.runtimeIdentity(), terminalBound.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(loopArtifact(2, 70)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(loopArtifact(4097, 70)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(uncheckedBackwardBranchArtifact()));
  }

  @Test
  void lowersBoundedPriorHelperCalls() throws Exception {
    var nested = LinuxX8664ScalarAotCompiler.lower(helperArtifact(3));
    byte[] terminalArtifact = helperArtifact(24);
    var terminal = LinuxX8664ScalarAotCompiler.lower(terminalArtifact);
    var registerParameters = LinuxX8664ScalarAotCompiler.lower(parameterHelperArtifact(6));
    byte[] stackArtifact = parameterHelperArtifact(7);
    var stackParameter = LinuxX8664ScalarAotCompiler.lower(stackArtifact);
    var stackVoidParameter = LinuxX8664ScalarAotCompiler.lower(parameterVoidHelperArtifact(7));
    var booleanParameter = LinuxX8664ScalarAotCompiler.lower(booleanParameterArtifact());

    assertEquals(73, nested.processStatus());
    assertEquals(73, terminal.processStatus());
    assertEquals(73, registerParameters.processStatus());
    assertEquals(73, stackParameter.processStatus());
    assertEquals(73, stackVoidParameter.processStatus());
    assertEquals(73, booleanParameter.processStatus());
    assertNotEquals(nested.runtimeIdentity(), terminal.runtimeIdentity());
    assertNotEquals(registerParameters.runtimeIdentity(), stackParameter.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(helperArtifact(25)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(parameterHelperArtifact(8)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(dormantUnsupportedHelperArtifact()));

    Fixture fixture = fixture(stackArtifact, stackParameter.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), stackParameter.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "39fa0ef551020f30afc0a7d2c81b34e65330e3a7ae20d3b6d38db7bfb0e34b11",
        identity(stackArtifact));
    assertEquals(
        "e0b6bf9c822359d43495ac305a3e1c49fb54f283276e0c98ce6a60d778dee97f",
        stackParameter.runtimeIdentity());
    assertEquals(
        "e17bcfd33634ed7c3e38ec2d075ed3c77a1a59f99766ada479c50bfb85b3d907",
        fixture.capsule().identity());
    assertEquals(
        "810b549d557a3ace9a6918d979574157a15f2432821e5209b2da00cf29540bd8",
        fixture.plan().identity());
    assertEquals(
        "38b9e08e56f24613c57b667e5d368aa7a34617814f82292b4222d3537410484e",
        verified.prev());

    Fixture terminalFixture = fixture(terminalArtifact, terminal.runtimeText());
    byte[] terminalImage = ElfImage.build(
        terminalFixture.plan(),
        terminalFixture.abi(),
        terminalFixture.capsule(),
        terminal.runtimeText(),
        0);
    ElfImage.VerifiedImage terminalVerified = ElfImage.verify(
        terminalImage, terminalFixture.plan(), terminalFixture.abi());
    assertEquals(
        "582736d63c4d58465e0cd68b633c4d7e315c56817cf2d011db2a3ae6fda05084",
        identity(terminalArtifact));
    assertEquals(
        "a8e0dfd175d35bc84e04ef3bea2cb1ca271ccdc006d5e6b25cc39e89363e4b16",
        terminal.runtimeIdentity());
    assertEquals(
        "4896f1b210c3b6ac0f405164467ac2f27f263aed30a6e6150f3679907beb795b",
        terminalFixture.capsule().identity());
    assertEquals(
        "1fb2f458bff81b0534ccfcb119fd8dde7fe202bad1e345dc89f02b0ef53ca565",
        terminalFixture.plan().identity());
    assertEquals(
        "fa543a706e5907aca33fd6c415c0d238cbd95eaa833cec6d6c8e04dc37c610f6",
        terminalVerified.prev());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);

      Process terminalProcess =
          new ProcessBuilder(writeExecutable(terminalImage).toString()).start();
      assertTrue(terminalProcess.waitFor(
          Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, terminalProcess.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(),
          terminalProcess.getInputStream().readAllBytes());
      assertEquals(0, terminalProcess.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersAcyclicForwardHelperCalls() throws Exception {
    byte[] artifact = forwardHelperArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(cyclicHelperArtifact()));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(selfCallingHelperArtifact()));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "9920c68d45d4a1ec1870cf62950cb8c08ba25549c9c28dffe3ae9c14367e21e4",
        identity(artifact));
    assertEquals(
        "d731526c670d251e0b2d65e22a33615c5b43743b2bea968ad0fd4634a3ffdd00",
        lowered.runtimeIdentity());
    assertEquals(
        "7a348327fb9386bb1899edefd0d6da3c8095dc4a238a1d1bf547143645008d8f",
        fixture.capsule().identity());
    assertEquals(
        "c76d9538d1ea8bf1e584cab8276fb2ac6cef23440a59ff432d555f8b60305589",
        fixture.plan().identity());
    assertEquals(
        "d6365e30ee0494041b65304508d6b49eee45591b66774e8a3caffaa47aaa0271",
        verified.prev());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersParameterizedVoidHelperChecks() {
    var lowered = LinuxX8664ScalarAotCompiler.lower(voidHelperArtifact(73));

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(voidHelperArtifact(72)));
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
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            arithmeticArtifact(Opcode.LOCAL_ADD, Long.MAX_VALUE, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            arithmeticArtifact(Opcode.LOCAL_DIV, 42, 0)));

    byte[] damaged = artifact(42);
    damaged[damaged.length - 1] ^= 1;
    assertThrows(RuntimeException.class, () -> LinuxX8664ScalarAotCompiler.lower(damaged));
  }

  @Test
  void lowersBoundedApplicationOutput() {
    byte[] message = "Native Wheeler\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    var lowered = LinuxX8664ScalarAotCompiler.lower(outputArtifact(message));
    var changed = LinuxX8664ScalarAotCompiler.lower(outputArtifact(
        "Native wheeler\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII)));

    assertEquals(73, lowered.processStatus());
    assertTrue(lowered.writesApplicationOutput());
    assertArrayEquals(message, lowered.applicationOutput());
    assertNotEquals(lowered.runtimeIdentity(), changed.runtimeIdentity());
    byte[] returned = lowered.applicationOutput();
    returned[0] ^= 1;
    assertArrayEquals(message, lowered.applicationOutput());
    assertEquals(
        4096,
        LinuxX8664ScalarAotCompiler.lower(zeroOutputArtifact(4096))
            .applicationOutput().length);
    assertEquals(
        1,
        LinuxX8664ScalarAotCompiler.lower(zeroOutputArtifact(1, 64))
            .applicationOutput().length);
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(zeroOutputArtifact(0)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(zeroOutputArtifact(4097)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(zeroOutputArtifact(1, 65)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(invalidOutputWriteArtifact(4096, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(invalidOutputWriteArtifact(0, 256)));
  }

  @Test
  void lowersBoundedSharedScalarGlobals() throws Exception {
    byte[] artifact = scalarGlobalArtifact(3);
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);
    var terminal = LinuxX8664ScalarAotCompiler.lower(scalarGlobalArtifact(32));

    assertEquals(41, lowered.processStatus());
    assertEquals(41, terminal.processStatus());
    assertNotEquals(lowered.runtimeIdentity(), terminal.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(scalarGlobalArtifact(33)));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(41, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void decodesStrictUtf8ApplicationInput() throws Exception {
    byte[] artifact = utf8IoArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    if (nativeLinuxHost()) {
      Process valid = new ProcessBuilder(writeExecutable(image).toString()).start();
      valid.getOutputStream().write("A🙂".getBytes(java.nio.charset.StandardCharsets.UTF_8));
      valid.getOutputStream().close();
      assertTrue(valid.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(4, valid.exitValue());
      assertArrayEquals(new byte[] {0, 4}, valid.getInputStream().readAllBytes());
      assertEquals(0, valid.getErrorStream().readAllBytes().length);

      Process malformed = new ProcessBuilder(writeExecutable(image).toString()).start();
      malformed.getOutputStream().write(new byte[] {(byte) 0xc0, (byte) 0x80});
      malformed.getOutputStream().close();
      assertTrue(malformed.waitFor(
          Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(ScalarAotMachine.EXECUTION_TRAP_STATUS, malformed.exitValue());
      assertEquals(0, malformed.getInputStream().readAllBytes().length);
      assertEquals(0, malformed.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void enforcesOneSharedExecutionBound() throws Exception {
    byte[] terminalArtifact = executionBoundArtifact(false, 71);
    var terminal = LinuxX8664ScalarAotCompiler.lower(terminalArtifact);
    assertEquals(73, terminal.processStatus());
    Fixture terminalFixture = fixture(terminalArtifact, terminal.runtimeText());
    byte[] terminalImage = ElfImage.build(
        terminalFixture.plan(),
        terminalFixture.abi(),
        terminalFixture.capsule(),
        terminal.runtimeText(),
        0);
    ElfImage.verify(terminalImage, terminalFixture.plan(), terminalFixture.abi());
    IllegalArgumentException rejected = assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(executionBoundArtifact(false, 72)));
    assertTrue(rejected.getMessage().contains("execution bound"));

    byte[] artifact = executionBoundArtifact(true, 72);
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    if (nativeLinuxHost()) {
      Process terminalProcess =
          new ProcessBuilder(writeExecutable(terminalImage).toString()).start();
      assertTrue(terminalProcess.waitFor(
          Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(73, terminalProcess.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(),
          terminalProcess.getInputStream().readAllBytes());
      assertEquals(0, terminalProcess.getErrorStream().readAllBytes().length);

      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      process.getOutputStream().close();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(ScalarAotMachine.EXECUTION_TRAP_STATUS, process.exitValue());
      assertEquals(0, process.getInputStream().readAllBytes().length);
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void passesDynamicInputAndOutputBorrowsThroughHelpers() throws Exception {
    byte[] artifact = dynamicIoHelperArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertTrue(lowered.usesDynamicApplicationIo());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      process.getOutputStream().write('Q');
      process.getOutputStream().close();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals('Q', process.exitValue());
      assertArrayEquals(new byte[] {'Q'}, process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersAndLaunchesDynamicApplicationIo() throws Exception {
    byte[] artifact = dynamicIoArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertTrue(lowered.usesDynamicApplicationIo());
    assertFalse(lowered.hasStaticProcessStatus());
    assertFalse(lowered.writesApplicationOutput());
    assertThrows(IllegalStateException.class, lowered::processStatus);

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      process.getOutputStream().write('Z');
      process.getOutputStream().close();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals('Z', process.exitValue());
      assertArrayEquals(new byte[] {'Z'}, process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void buildsAndLaunchesOneAotCapsuleImage() throws Exception {
    byte[] artifact = outputArtifact(
        "Native Wheeler\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
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
          lowered.applicationOutput(),
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

  private record ArithmeticCase(Opcode opcode, long left, long right) {}

  private record Fixture(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      NativeImagePlan plan) {}
}
