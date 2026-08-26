package com.typeobject.wheeler.runtime;

import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.arithmeticArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifactWithGlobal;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.booleanParameterArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.booleanResultHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.cyclicHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.conditionalArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.dormantParameterizedInverseArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.controlMarkerArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.directionalCallArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.dynamicIoHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.executionBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalInstructionArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalOverflowArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.globalReplacementArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.helperStatusArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.forwardHelperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.helperArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.instructionBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.invalidOutputWriteArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.localBoundArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.loopArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.noStatusWriterArtifact;
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
        lower(artifact);
    LinuxX8664ScalarAotCompiler.LoweredRuntime second =
        lower(artifact.clone());

    assertEquals(identity(artifact), first.portableArtifact());
    assertEquals(42, first.processStatus());
    assertFalse(first.writesApplicationOutput());
    assertThrows(IllegalStateException.class, first::applicationOutput);
    assertArrayEquals(first.runtimeText(), second.runtimeText());
    assertNotEquals(
        identity(LinuxX8664EntryShim.runtimeText()),
        identity(first.runtimeText()));
    assertEquals(
        "93829ef0261d6361a5bed20640fea3be2f8cf4093d7a3d878a5ae32cfaf81f1e",
        identity(first.runtimeText()));

    byte[] returned = first.runtimeText();
    returned[0] ^= 1;
    assertFalse(java.util.Arrays.equals(returned, first.runtimeText()));
  }

  @Test
  void bindsTheLoweredRuntimeToTheWbcStatus() {
    var low = lower(artifact(17));
    var high = lower(artifact(73));

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
      var lowered = lower(
          arithmeticArtifact(operation.opcode(), operation.left(), operation.right()));
      assertEquals(42, lowered.processStatus());
      assertNotEquals(
          identity(lower(artifact(42)).runtimeText()),
          lowered.runtimeIdentity());
    }
  }

  @Test
  void lowersCanonicalRemainderEdge() throws Exception {
    byte[] artifact = arithmeticArtifact(Opcode.LOCAL_MOD, Long.MIN_VALUE, -1);
    var lowered = lower(artifact);

    assertEquals(0, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "b58f22ae80febf5f4eb312ffe55b2bb6137db3f60f9fa695ffafbac1fe7b7b98",
        identity(artifact));
    assertEquals(
        "db700e89962bb623920677eb978c4cf5a430c951b24de1e78f1db0452a290482",
        lowered.runtimeIdentity());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(0, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersComparisonsAndForwardConditionalBranches() {
    var less = lower(
        conditionalArtifact(Opcode.LOCAL_LT, 70, 71));
    var notLess = lower(
        conditionalArtifact(Opcode.LOCAL_LT, 71, 70));
    var equal = lower(
        conditionalArtifact(Opcode.LOCAL_EQ, 73, 73));
    var unequal = lower(
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
    var lowered = lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(
            globalOverflowArtifact(Opcode.ADD_CONST, Long.MAX_VALUE, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(
            globalOverflowArtifact(Opcode.SUB_CONST, Long.MIN_VALUE, 1)));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "378b6b4441e29c95d7b32051d9b8820f59c7e68c9b230c5a6297649274ac6efb",
        identity(artifact));
    assertEquals(
        "057c1b85b48a29c7c373ebf8699f748bd31b0fb47a6a36b6af4bba667c641a68",
        lowered.runtimeIdentity());
    assertEquals(
        "845dd69143793cba8301d6865688ace9b0ee60c7b8d241ace22643c7e1d0c112",
        fixture.capsule().identity());
    assertEquals(
        "91f376e5c967d5e502e9a6294c44e93a3fe8535d97a8b5e6b87d17b3f3d8ad14",
        fixture.plan().identity());
    assertEquals(
        "ef3029999b2b079bdc7bb7a5601bef9f5a7c6d4922859e2ca959632a9f3fadbc",
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
  void publishesStatusThroughDirectionalHelpers() throws Exception {
    byte[] artifact = helperStatusArtifact();
    var lowered = lower(artifact);

    assertEquals(1, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(noStatusWriterArtifact()));
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "ede040399a9e6f3e37c4a47856ca4e6b8e620be87cdd6c74e03c0c54b686dd7c",
        identity(artifact));
    assertEquals(
        "8080b55ad8724f148f857273b42341328d51057fe8dc42865f646173842e96d5",
        lowered.runtimeIdentity());
    assertEquals(
        "ef1d0ec4128b0f79d3f42cdef45893c12e5a443b8e775108c14b0f47b012aa44",
        fixture.capsule().identity());
    assertEquals(
        "0fbedea0eface26051ba4faf0d639c03af6b930bbd6f04266e31361bc34e63a6",
        fixture.plan().identity());
    assertEquals(
        "55cccb4b0e7780dce302b0be50a113db4c32bac98efe1370fcf496dc6452b847",
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
  void lowersForwardControlMarkers() throws Exception {
    byte[] artifact = controlMarkerArtifact();
    var lowered = lower(artifact);

    assertEquals(41, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "7b7f7222338a4b77b1604305eb98c20cde67693f37c99d6e6ecefece70e1f288",
        identity(artifact));
    assertEquals(
        "3edc4e58f037392d63fd5e823c1ab395b4e75ac086f1a5859404f242a17cf741",
        lowered.runtimeIdentity());
    assertEquals(
        "2c6ce55839b61b9c1378de4c5e0d1f0d47c533de3ed6dbdbd64ea0bd7029e01d",
        fixture.capsule().identity());
    assertEquals(
        "f52e0e561e04374b5e626b51691fe74c8b689b80a8aa29e1f69a4c1948649c12",
        fixture.plan().identity());
    assertEquals(
        "dec745548190f7f59a27cd33ac9b86df8788918b2ae1b57ebcef13cdfb7e83f8",
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
    var lowered = lower(artifact);

    assertEquals(1, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "b5907c5d8e3169c09a5e5d04a3b9b7a73dbc190d6d7ba4fc8984c3fda6186763",
        identity(artifact));
    assertEquals(
        "555ce2b4b14a0cb04cd1130ef9dc29cf90f9cf5d1db620e48da74cf2a51a8915",
        lowered.runtimeIdentity());
    assertEquals(
        "69e3db35fb636680c5e3df441e264ef27a5031863c1477a15439fad3d6367e8c",
        fixture.capsule().identity());
    assertEquals(
        "fc57f075e085da5b8397aa5b0ce7f5e2db237ed2a17a05f251e8d69d168a0d09",
        fixture.plan().identity());
    assertEquals(
        "222e85033fe43ddaa9d7dbf042e87576593510140af5f2461fd988958d441689",
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
    var lowered = lower(artifact);

    assertEquals(51, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "c8536b97e8b990f2e8e830c9dfe8dcc9d443bb990462b81714cf10031dc6e3a6",
        identity(artifact));
    assertEquals(
        "bfb148909213143318d0b39316de7094f75679b3c868237399b8012d6b54fb18",
        lowered.runtimeIdentity());
    assertEquals(
        "524256617fa8ef2f9d14e2ea575d9869584c0cf947a704d323432312991a5c07",
        fixture.capsule().identity());
    assertEquals(
        "e849cccdf7e3b36ad0260c266583889636e0565ff42d62eceeb6a8a094820232",
        fixture.plan().identity());
    assertEquals(
        "4324c04fb30dd57d9b160482912835340673d05c5afcb7557d4bf18af26d4255",
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
    var lowered = lower(stateCheckArtifact(42));
    var terminalRotation = lower(
        arithmeticArtifact(Opcode.LOCAL_ROTR32, 0x8000_0000L, 31));

    assertEquals(73, lowered.processStatus());
    assertEquals(1, terminalRotation.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(stateCheckArtifact(41)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(
            arithmeticArtifact(Opcode.LOCAL_ROTR32, 42, 32)));
  }

  @Test
  void lowersBoundedScalarLoops() {
    var shortLoop = lower(loopArtifact(3, 70));
    var terminalBound = lower(loopArtifact(4096, -4023));

    assertEquals(73, shortLoop.processStatus());
    assertEquals(73, terminalBound.processStatus());
    assertNotEquals(shortLoop.runtimeIdentity(), terminalBound.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(loopArtifact(2, 70)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(loopArtifact(4097, 70)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(uncheckedBackwardBranchArtifact()));
  }

  @Test
  void lowersBoundedPriorHelperCalls() throws Exception {
    var nested = lower(helperArtifact(3));
    byte[] terminalArtifact = helperArtifact(24);
    var terminal = lower(terminalArtifact);
    var registerParameters = lower(parameterHelperArtifact(6));
    byte[] stackArtifact = parameterHelperArtifact(16);
    var stackParameter = lower(stackArtifact);
    var stackVoidParameter = lower(parameterVoidHelperArtifact(16));
    var booleanParameter = lower(booleanParameterArtifact());

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
        () -> lower(helperArtifact(25)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(parameterHelperArtifact(17)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(dormantParameterizedInverseArtifact()));

    Fixture fixture = fixture(stackArtifact, stackParameter.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), stackParameter.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "6940835cec9eecb155ac4de2efb9a6514b0b316dadf0f546057d1f064dff0cf1",
        identity(stackArtifact));
    assertEquals(
        "65cffb9320ded62993da55b2945d9309f675c8f89883d1f06076125be79d6d7e",
        stackParameter.runtimeIdentity());
    assertEquals(
        "36c72ed8eb1a550bd5c25834005bdd00f50f9b7b5c1635a935b36bd4e2a42438",
        fixture.capsule().identity());
    assertEquals(
        "6c5e5073b7520a3f95baa665dd3204fb373f326418974da62a199d87f5c1f1e0",
        fixture.plan().identity());
    assertEquals(
        "243ca19309b6037d9df1a46d66dc5342b3db9dca1417679dff2e867ee2f11ed7",
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
        "dae64eb303909a71f7cfbf57914e9375bec59472c60b6326cfafa3c5e313aa4c",
        terminal.runtimeIdentity());
    assertEquals(
        "4896f1b210c3b6ac0f405164467ac2f27f263aed30a6e6150f3679907beb795b",
        terminalFixture.capsule().identity());
    assertEquals(
        "4305d67e7d68db434c4ca22609c97a6e782e520f2f63406556db6b8432ca07d1",
        terminalFixture.plan().identity());
    assertEquals(
        "357624a9ae08755079a5e1e6ad3c59c8f751037df78a13f1370cba0df4dd970a",
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
    var lowered = lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(cyclicHelperArtifact()));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(selfCallingHelperArtifact()));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "9920c68d45d4a1ec1870cf62950cb8c08ba25549c9c28dffe3ae9c14367e21e4",
        identity(artifact));
    assertEquals(
        "453d23715ac38900700f7845efe96349a74bb387e428bbba72bf3546600eca32",
        lowered.runtimeIdentity());
    assertEquals(
        "7a348327fb9386bb1899edefd0d6da3c8095dc4a238a1d1bf547143645008d8f",
        fixture.capsule().identity());
    assertEquals(
        "d7acb94fa6901b2f99ea2310cedb7eff1c7228b52d7e76609d2942815f8facbe",
        fixture.plan().identity());
    assertEquals(
        "828b992025104f768ec699ad2258a00c26406f8f65b1eef1e2ecc3710e4bff9f",
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
    var locals = lower(localBoundArtifact(256));
    byte[] instructionArtifact = instructionBoundArtifact(512);
    var instructions = lower(instructionArtifact);

    assertEquals(73, locals.processStatus());
    assertEquals(73, instructions.processStatus());
    assertNotEquals(locals.runtimeIdentity(), instructions.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(localBoundArtifact(257)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(instructionBoundArtifact(513)));

    Fixture fixture = fixture(instructionArtifact, instructions.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), instructions.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "b2804f1ac4c7adca624b28dd201748c3e5c54868f9db68665a07010d2234fe61",
        identity(instructionArtifact));
    assertEquals(
        "61054c91676da459114a52ca9ecdaa1c7ab240644a8735fc6571c4d7f90adfec",
        instructions.runtimeIdentity());
    assertEquals(
        "0150846094f14c76a4609bccb0a37c702979363bdca841e7ee1f1be25a94485e",
        fixture.capsule().identity());
    assertEquals(
        "923d2a75e8d39c8fbd1bb7483b96dffaf7ed475169a74caad3854f2e923d8730",
        fixture.plan().identity());
    assertEquals(
        "313bc2cd71e0047069f815a45efba04a5ce232e3d9f3ee33d5b2524e708d0fed",
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
    var lowered = lower(artifact);

    assertEquals(73, lowered.processStatus());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "6dc5168e89f91976d6e30e199c786fbb11b88351a2b0dfeb01b3e4c762731e90",
        identity(artifact));
    assertEquals(
        "8b638ff9d1792a5ea3f0a1ba73d719f98c4373ef48d7de09123e53751f879670",
        lowered.runtimeIdentity());
    assertEquals(
        "89bfcb13e03cd645bed30bc43a7987ae854ce6591e726539910a968f8fdd07f9",
        fixture.capsule().identity());
    assertEquals(
        "eb44bd6f497b9d96b7d61826784962ae0207f4bf5f343d5e6fcbfe4f5c58f556",
        fixture.plan().identity());
    assertEquals(
        "f3b9229f666be998376c754655e6434c18914ec08eaa9e328b6fa897772fc2d8",
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
    var lowered = lower(artifact);

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(recursiveHelperArtifact(64)));

    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "1b493683700357eb469afcb02a45d06137bbb15d443e287c9677e76beb2c47bc",
        identity(artifact));
    assertEquals(
        "78407f68225aa0b9cf500ea4bfbabf42f740ee62d4b357867874c7405142c047",
        lowered.runtimeIdentity());
    assertEquals(
        "8397f3b9cd6592a4a955a6c2342bd3e0755d24b01350fbed111ac570999f49e4",
        fixture.capsule().identity());
    assertEquals(
        "d1cd444773b02a01c55cf55aa8d6ab046d10cd63fcc18e91f491d7b40aec45ef",
        fixture.plan().identity());
    assertEquals(
        "ca9bce8267fb7147847b27ccd1a7d689964631ae3db701cd1e322cfa6ad94167",
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
    var lowered = lower(voidHelperArtifact(73));

    assertEquals(73, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(voidHelperArtifact(72)));
  }

  @Test
  void rejectsProgramsOutsideTheClosedAotProfile() {
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(artifact(125)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(artifactWithGlobal("result", 42)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(
            arithmeticArtifact(Opcode.LOCAL_ADD, Long.MAX_VALUE, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(
            arithmeticArtifact(Opcode.LOCAL_DIV, 42, 0)));

    byte[] damaged = artifact(42);
    damaged[damaged.length - 1] ^= 1;
    assertThrows(RuntimeException.class, () -> lower(damaged));
  }

  @Test
  void lowersBoundedApplicationOutput() {
    byte[] message = "Native Wheeler\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    var lowered = lower(outputArtifact(message));
    var changed = lower(outputArtifact(
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
        lower(zeroOutputArtifact(4096))
            .applicationOutput().length);
    assertEquals(
        1,
        lower(zeroOutputArtifact(1, 64))
            .applicationOutput().length);
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(zeroOutputArtifact(0)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(zeroOutputArtifact(4097)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(zeroOutputArtifact(1, 65)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(invalidOutputWriteArtifact(4096, 1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(invalidOutputWriteArtifact(0, 256)));
  }

  @Test
  void lowersBoundedSharedScalarGlobals() throws Exception {
    byte[] artifact = scalarGlobalArtifact(3);
    var lowered = lower(artifact);
    var terminal = lower(scalarGlobalArtifact(32));

    assertEquals(41, lowered.processStatus());
    assertEquals(41, terminal.processStatus());
    assertNotEquals(lowered.runtimeIdentity(), terminal.runtimeIdentity());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(scalarGlobalArtifact(33)));

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
    var lowered = lower(artifact);
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
    var terminal = lower(terminalArtifact);
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
        () -> lower(executionBoundArtifact(false, 72)));
    assertTrue(rejected.getMessage().contains("execution bound"));

    byte[] artifact = executionBoundArtifact(true, 72);
    var lowered = lower(artifact);
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
    var lowered = lower(artifact);

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
    var lowered = lower(artifact);

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
        lower(artifact);
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
