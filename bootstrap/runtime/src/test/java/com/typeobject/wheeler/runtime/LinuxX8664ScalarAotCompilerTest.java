package com.typeobject.wheeler.runtime;

import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.arithmeticArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifactWithGlobal;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.booleanParameterArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.booleanResultHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.cyclicHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.conditionalArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.dormantStatusMutationHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.controlMarkerArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.directionalCallArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.executionBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalInstructionArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalOverflowArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalReplacementArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.helperStatusMutationArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.forwardHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.helperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.instructionBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.invalidOutputWriteArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.localBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.loopArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.outputArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.parameterHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.parameterVoidHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.recursiveHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.scalarGlobalArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.selfCallingHelperArtifact;
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
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/** Verified scalar WBC lowering and native process-status evidence. */
final class LinuxX8664ScalarAotCompilerTest extends ScalarAotNativeTest {

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
  void lowersScalarGlobalInstructions() throws Exception {
    byte[] artifact = globalInstructionArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            globalOverflowArtifact(Opcode.ADD_CONST, Long.MAX_VALUE, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            globalOverflowArtifact(Opcode.SUB_CONST, Long.MIN_VALUE, 1)));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "378b6b4441e29c95d7b32051d9b8820f59c7e68c9b230c5a6297649274ac6efb",
        identity(artifact));
    assertEquals(
        "229c253086efa6127072efaa32b203fdbbc27db11f5f29f6a6d695bb63cefafe",
        lowered.runtimeIdentity());
    assertEquals(
        "845dd69143793cba8301d6865688ace9b0ee60c7b8d241ace22643c7e1d0c112",
        fixture.capsule().identity());
    assertEquals(
        "839f02237e4890afdfcab9883d3deae78ccdbc08d57d201a3dc3f05fec334628",
        fixture.plan().identity());
    assertEquals(
        "07c48c8eefa6ef31f243794aebb981cddf123a5d81a845d2c5774771f17797a6",
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
  void lowersForwardControlMarkers() throws Exception {
    byte[] artifact = controlMarkerArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(41, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "7b7f7222338a4b77b1604305eb98c20cde67693f37c99d6e6ecefece70e1f288",
        identity(artifact));
    assertEquals(
        "f3f7233445269902a30f6b0cfa71967f9e847c1eaf69d416b4ee52ca1b392737",
        lowered.runtimeIdentity());
    assertEquals(
        "2c6ce55839b61b9c1378de4c5e0d1f0d47c533de3ed6dbdbd64ea0bd7029e01d",
        fixture.capsule().identity());
    assertEquals(
        "166a7fc54958ae07d7bcbe2a52efd219aa70a9516f2c54bb5e637a38e4c41f9b",
        fixture.plan().identity());
    assertEquals(
        "811a7d9f2be0d6200c383656f27af81c041ba80fa7b3c081cb8b298634cf077a",
        verified.prev());
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
  void lowersForwardAndInverseScalarCalls() throws Exception {
    byte[] artifact = directionalCallArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(1, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "b5907c5d8e3169c09a5e5d04a3b9b7a73dbc190d6d7ba4fc8984c3fda6186763",
        identity(artifact));
    assertEquals(
        "cc5edc6502c39037e7c7eba018855b901845ef4391e69399159eb29fca036209",
        lowered.runtimeIdentity());
    assertEquals(
        "69e3db35fb636680c5e3df441e264ef27a5031863c1477a15439fad3d6367e8c",
        fixture.capsule().identity());
    assertEquals(
        "728420ab46abb7aa066b93d8e1fbc5531000570b53eb486a7f34a893de3f9fc3",
        fixture.plan().identity());
    assertEquals(
        "17723dda0eee581a9d7b5a3623cb0324098647dac057fc8e8ffdc20543c5a7c1",
        verified.prev());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(1, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersScalarGlobalReplacement() throws Exception {
    byte[] artifact = globalReplacementArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(51, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            helperStatusMutationArtifact(Opcode.SET_LOGGED)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            helperStatusMutationArtifact(Opcode.SWAP)));
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "c8536b97e8b990f2e8e830c9dfe8dcc9d443bb990462b81714cf10031dc6e3a6",
        identity(artifact));
    assertEquals(
        "be7420324c82eb8a07bf59a5285646ad3dde8e62a7db38747d43fd207629348a",
        lowered.runtimeIdentity());
    assertEquals(
        "524256617fa8ef2f9d14e2ea575d9869584c0cf947a704d323432312991a5c07",
        fixture.capsule().identity());
    assertEquals(
        "96df771e3c861ff848bfcd8f4629161b92c91527539c8fa846982dbb96079ebe",
        fixture.plan().identity());
    assertEquals(
        "a7108a33b4b5144c5e4e8b0086ee80d302ac2a95fdfcb53b375faf293b5f1895",
        verified.prev());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(51, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
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
    byte[] stackArtifact = parameterHelperArtifact(16);
    var stackParameter = LinuxX8664ScalarAotCompiler.lower(stackArtifact);
    var stackVoidParameter = LinuxX8664ScalarAotCompiler.lower(parameterVoidHelperArtifact(16));
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
        () -> LinuxX8664ScalarAotCompiler.lower(parameterHelperArtifact(17)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(dormantStatusMutationHelperArtifact()));

    Fixture fixture = fixture(stackArtifact, stackParameter.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), stackParameter.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "6940835cec9eecb155ac4de2efb9a6514b0b316dadf0f546057d1f064dff0cf1",
        identity(stackArtifact));
    assertEquals(
        "9cc36d6cfcb6e57acf2c163daf50d271ca0ce9ced3326bc0060e8acea28cc8b9",
        stackParameter.runtimeIdentity());
    assertEquals(
        "36c72ed8eb1a550bd5c25834005bdd00f50f9b7b5c1635a935b36bd4e2a42438",
        fixture.capsule().identity());
    assertEquals(
        "2e216025596f3f4c5605b088d97fee3f832ab29984570740b605b2bb6a6c93b0",
        fixture.plan().identity());
    assertEquals(
        "a3f31213083fd7208a347a252569e932367754c4cae962105876c3a819633d85",
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
  void lowersCompilerWidthFramesAndBodies() throws Exception {
    var locals = LinuxX8664ScalarAotCompiler.lower(localBoundArtifact(256));
    byte[] instructionArtifact = instructionBoundArtifact(512);
    var instructions = LinuxX8664ScalarAotCompiler.lower(instructionArtifact);

    assertEquals(73, locals.processStatus());
    assertEquals(73, instructions.processStatus());
    assertNotEquals(locals.runtimeIdentity(), instructions.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(localBoundArtifact(257)));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(instructionBoundArtifact(513)));

    Fixture fixture = fixture(instructionArtifact, instructions.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), instructions.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "b2804f1ac4c7adca624b28dd201748c3e5c54868f9db68665a07010d2234fe61",
        identity(instructionArtifact));
    assertEquals(
        "da36f19cb3a1e3a1bff0dc1c20e00b68769f4cad9c12aeb6454413ce7355bd1b",
        instructions.runtimeIdentity());
    assertEquals(
        "0150846094f14c76a4609bccb0a37c702979363bdca841e7ee1f1be25a94485e",
        fixture.capsule().identity());
    assertEquals(
        "ecf2743a5adb422d51ad4aec9fb673fd6edd5aafecba6b62e564e5ee1b66f1b7",
        fixture.plan().identity());
    assertEquals(
        "415d9635abbd85765f6e01664008c38907727187e48f09d320d61dbbf74a3ffb",
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
  void lowersBooleanResultHelpers() throws Exception {
    byte[] artifact = booleanResultHelperArtifact();
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(73, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "6dc5168e89f91976d6e30e199c786fbb11b88351a2b0dfeb01b3e4c762731e90",
        identity(artifact));
    assertEquals(
        "10cb2cfc9d342eb5f4931c004bf6e29c5b981a27aae2ff3ec245e6cbbdcbcd10",
        lowered.runtimeIdentity());
    assertEquals(
        "89bfcb13e03cd645bed30bc43a7987ae854ce6591e726539910a968f8fdd07f9",
        fixture.capsule().identity());
    assertEquals(
        "e42257216000efe849c5980eef426780d2365e659587fae905de44deae88661f",
        fixture.plan().identity());
    assertEquals(
        "35c1afdb6504e16a75bf7bb5a629567e7f46f9b83c41a1ee9869537faf31c39c",
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
  void lowersBoundedRecursiveHelperCalls() throws Exception {
    byte[] artifact = recursiveHelperArtifact(63);
    var lowered = LinuxX8664ScalarAotCompiler.lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(recursiveHelperArtifact(64)));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "1b493683700357eb469afcb02a45d06137bbb15d443e287c9677e76beb2c47bc",
        identity(artifact));
    assertEquals(
        "0f8eef2985778f5c9332b5cd3906b2ee98b220a39769ee7fd6c3c4382fabe8e4",
        lowered.runtimeIdentity());
    assertEquals(
        "8397f3b9cd6592a4a955a6c2342bd3e0755d24b01350fbed111ac570999f49e4",
        fixture.capsule().identity());
    assertEquals(
        "795acd712b7e9d2370b5372d2ce773381f1793d0c4537d2cc6a85d0bcdb3c245",
        fixture.plan().identity());
    assertEquals(
        "3974b9d50ed1a6f36ecd8620aea7ac48fd85dea43383217969f2f732cff4eadc",
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
        () -> LinuxX8664ScalarAotCompiler.lower(artifactWithGlobal("result", 42)));
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

  private record ArithmeticCase(Opcode opcode, long left, long right) {}
}
