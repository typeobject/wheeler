package com.typeobject.wheeler.examples.proofs;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import java.security.MessageDigest;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Differential publication checks for both classical proof rules and canonical string unions. */
final class NativeClassicalSourceArtifactExampleTest {
  private static final String STEP = "theorem bound proves steps(bump, 8);";
  private static final String INVERSES = "theorem first proves inverse(bump); theorem last proves inverse(invoke);";

  @Test
  void publishesGeneratedInversesAndBothRulesWithCompleteRewind() throws Exception {
    var fixture = ClassicalArtifactFixture.fixture(INVERSES + STEP, true, "");
    var program = check(fixture);
    VirtualMachine machine = new VirtualMachine(program);
    machine.invoke(1, false);
    assertEquals(3, machine.global(0));
    machine.establishEffectBoundary();
    machine.invoke(1, true);
    assertEquals(0, machine.global(0));
  }

  @Test
  void retainsOrdinaryStepClaimsAndDeduplicatesExistingNames() throws Exception {
    check(ClassicalArtifactFixture.fixture("""
        theorem zzz proves steps(bump, 8);
        theorem MidArtifact proves steps(bump, 8);
        theorem count proves steps(bump, 8);
        theorem High proves steps(bump, 8);
        theorem zero proves steps(bump, 8);
        theorem aaa proves steps(bump, 8);
        """, false, ""));
  }

  @Test
  void preservesAlreadyGeneratedInverseWindowsWhenAddingClaims() throws Exception {
    var fixture = ClassicalArtifactFixture.fixture(INVERSES + STEP, true, "");
    check(ClassicalArtifactFixture.fixture(fixture.expected(), false, ""));
  }

  @Test
  void republishesAnEmptyClaimTableWithoutChangingAnyArtifactByte() throws Exception {
    check(ClassicalArtifactFixture.fixture("", false, ""));
  }

  @ParameterizedTest
  @ValueSource(longs = {8, 4_000_000L})
  void retainsStepBoundsThroughTheFinalManifestLimit(long bound) throws Exception {
    var initial = ClassicalArtifactFixture.fixture(STEP, false, "").expected();
    var claim = initial.proofCertificates().getFirst();
    var expected = ClassicalArtifactFixture.copy(initial, initial.functions(),
        List.of(new ProofCertificate(claim.id(), claim.name(), claim.rule(), claim.subjectId(), bound)),
        initial.maxSteps());
    check(ClassicalArtifactFixture.fixture(expected, false, ""));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 0);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, -2);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 1);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 4000001);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 4294967295);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 4294967304);",
      "set(proofs, SOURCE_PROOF_ARGUMENT_ROW, 9223372036854775807);",
      "set(proofs, SOURCE_PROOF_SUBJECT_ROW, -1);",
      "set(proofs, SOURCE_PROOF_SUBJECT_ROW, 2);",
      "set(proofs, SOURCE_PROOF_SUBJECT_ROW, 1);",
      "set(proofs, SOURCE_PROOF_RULE_ROW, 1); set(proofs, SOURCE_PROOF_ARGUMENT_ROW, -1);",
      "set(proofs, SOURCE_PROOF_RULE_ROW, 2);",
      "set(proofs, SOURCE_PROOF_RULE_ROW, 3);",
      "set(proofs, SOURCE_PROOF_RULE_ROW, 5);",
      "set(proofs, 0, -1);",
      "set(proofs, 0, 9223372036854775807);",
      "set(proofs, SOURCE_PROOF_LENGTH_ROW, 0);",
      "set(proofs, SOURCE_PROOF_LENGTH_ROW, 257);",
      "claimedCount = 65;",
      "claimedCount = -1;",
      "generatedCount = 1;",
      "artifactBytes -= 1;"
  })
  void rejectsWithoutChangingCallerProductsOrPublication(String mutation) throws Exception {
    var fixture = ClassicalArtifactFixture.fixture(STEP, false, mutation);
    reject(fixture);
  }

  @Test
  void publishesEveryMaximumWidthClaimWithoutRewindHistory() throws Exception {
    int suffixBytes = Integer.toHexString(ClassicalArtifactFixture.MAX_PROOFS - 1).length();
    String suffixFormat = "%0" + suffixBytes + "x";
    String proofs = IntStream.range(0, ClassicalArtifactFixture.MAX_PROOFS)
        .map(index -> ClassicalArtifactFixture.MAX_PROOFS - index - 1)
        .mapToObj(index -> "theorem " + "x".repeat(ClassicalArtifactFixture.MAX_NAME_BYTES - suffixBytes)
            + suffixFormat.formatted(index)
            + " proves steps(bump, 8);").collect(Collectors.joining("\n"));
    check(ClassicalArtifactFixture.fixture(proofs, false, ""), false);
  }

  @Test
  void rejectsTheFirstExcessNameWithAnOtherwiseCompleteBuffer() throws Exception {
    reject(ClassicalArtifactFixture.fixture("theorem " + "x".repeat(ClassicalArtifactFixture.MAX_NAME_BYTES + 1) + " proves steps(bump, 8);", false, ""));
  }

  @Test
  void checksTerminalStringCapacityWithoutRewindHistory() throws Exception {
    String shared = "theorem count proves steps(bump, 8);";
    String base = ClassicalArtifactFixture.source(shared, false);
    var compiler = new WheelerCompiler();
    Program initial = compiler.compileLibraryModuleFiles(Map.of("Artifact.w", base), "fixture.classical_artifact");
    int capacity = ClassicalArtifactFixture.MAX_STRINGS;
    int fields = capacity - ClassicalArtifactFixture.stringCount(initial);
    String added = IntStream.range(0, fields).mapToObj(index -> ", long field" + index)
        .collect(Collectors.joining());
    String full = base.replace("record Alpha(long zero)", "record Alpha(long zero" + added + ")");
    Program expected = compiler.compileLibraryModuleFiles(Map.of("Artifact.w", full), "fixture.classical_artifact");
    assertEquals(capacity, ClassicalArtifactFixture.stringCount(expected));
    check(ClassicalArtifactFixture.fixture(expected, false, ""), false);
    Program excess = compiler.compileLibraryModuleFiles(Map.of("Artifact.w", full.replace(shared, STEP)),
        "fixture.classical_artifact");
    assertEquals(capacity + 1, ClassicalArtifactFixture.stringCount(excess));
    reject(ClassicalArtifactFixture.fixture(excess, false, ""), false);
  }

  @Test
  void rejectsAnInvalidLaterClaimWithoutPublishingTheEarlierOne() throws Exception {
    reject(ClassicalArtifactFixture.fixture(STEP + "theorem other proves steps(bump, 8);", false,
        "set(proofs, SOURCE_PROOF_ARGUMENT_ROW + 1, 1);"));
  }

  @Test
  void rejectsDuplicateProofNamesEvenWhenBothMatchAnExistingString() throws Exception {
    reject(ClassicalArtifactFixture.fixture(
        "theorem count proves steps(bump, 8); theorem other proves steps(bump, 8);", false,
        "set(proofs, 1, proofs[0]); set(proofs, SOURCE_PROOF_LENGTH_ROW + 1, proofs[SOURCE_PROOF_LENGTH_ROW]);"));
  }

  private static Program check(ClassicalArtifactFixture.Fixture fixture) throws Exception {
    return check(fixture, true);
  }

  private static Program check(ClassicalArtifactFixture.Fixture fixture, boolean rewind) throws Exception {
    VirtualMachine machine = fixture.machine();
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      step(machine, rewind);
    }
    MachineSnapshot prepared = machine.snapshot();
    while (machine.global("completed") == 0) {
      step(machine, rewind);
    }
    byte[] expected = new BytecodeWriter().write(fixture.expected());
    assertEquals(expected.length, machine.global("artifactLength"));
    assertEquals(ClassicalArtifactFixture.sectionStart(expected, BytecodeFormat.CODE), machine.global("codeStart"));
    assertEquals(fixture.expected().functions().size(), machine.global("functionCount"));
    assertEquals(fixture.expected().functions().stream().mapToInt(function -> function.localTypes().size())
        .max().orElseThrow(), machine.global("maxLocalCount"));
    assertEquals(0, machine.global("relocationCount"));
    MachineSnapshot published = machine.snapshot();
    assertEquals(prepared.regions(), published.regions().subList(0, prepared.regions().size()));
    int outputId = buffer(prepared, ClassicalArtifactFixture.ARTIFACT_BYTES).id();
    int identityId = buffer(prepared, ClassicalArtifactFixture.IDENTITY_BYTES).id();
    for (BufferValue before : prepared.buffers()) {
      if (before.id() != outputId && before.id() != identityId) {
        assertEquals(before, published.buffers().get(before.id()));
      }
    }
    BufferValue output = published.buffers().get(outputId);
    for (int index = 0; index < output.length(); index++) {
      long value = index < expected.length ? Byte.toUnsignedInt(expected[index]) : ClassicalArtifactFixture.SENTINEL;
      assertEquals(value, output.elements().get(index));
    }
    byte[] identity = MessageDigest.getInstance("SHA-256").digest(expected);
    BufferValue hash = published.buffers().get(identityId);
    for (int index = 0; index < identity.length; index++) {
      assertEquals(Byte.toUnsignedLong(identity[index]), hash.elements().get(index));
    }
    if (rewind) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      assertEquals(0, machine.historySize());
    }
    int firstPrivateRegion = prepared.buffers().stream()
        .filter(value -> value.id() != prepared.buffers().getFirst().id() && value.id() != outputId)
        .mapToInt(BufferValue::regionId).min().orElseThrow();
    for (var region : machine.snapshot().regions()) {
      if (firstPrivateRegion <= region.id()) {
        assertTrue(region.dropped());
      }
    }
    assertArrayEquals(expected, machine.hostOutput());
    var decoded = new BytecodeReader().read(machine.hostOutput());
    assertEquals(fixture.expected().proofCertificates(), decoded.proofCertificates());
    VirtualMachine executed = new VirtualMachine(decoded);
    executed.invoke(1, false);
    assertEquals(3, executed.global(0));
    if (rewind) {
      SourceProofFixture.replay(machine, initial);
    }
    return decoded;
  }

  private static void reject(ClassicalArtifactFixture.Fixture fixture) {
    reject(fixture, true);
  }

  private static void reject(ClassicalArtifactFixture.Fixture fixture, boolean rewind) {
    VirtualMachine machine = fixture.machine();
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      step(machine, rewind);
    }
    MachineSnapshot prepared = machine.snapshot();
    if (rewind) {
      assertThrows(VmTrap.class, machine::run);
    } else {
      assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    }
    MachineSnapshot rejected = machine.snapshot();
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("artifactLength"));
    for (String field : List.of("codeStart", "functionCount", "maxLocalCount", "relocationCount")) {
      assertEquals(-1, machine.global(field));
    }
    assertEquals(prepared.buffers(), rejected.buffers().subList(0, prepared.buffers().size()));
    assertEquals(prepared.regions(), rejected.regions().subList(0, prepared.regions().size()));
    if (rewind) {
      SourceProofFixture.rewind(machine, initial);
      assertThrows(VmTrap.class, machine::run);
      assertEquals(rejected, machine.snapshot());
      SourceProofFixture.rewind(machine, initial);
    } else {
      assertEquals(0, machine.historySize());
    }
  }

  private static void step(VirtualMachine machine, boolean rewind) {
    if (rewind) {
      machine.step();
    } else {
      machine.stepWithoutRewindHistory();
    }
  }

  private static BufferValue buffer(MachineSnapshot snapshot, int length) {
    return snapshot.buffers().stream().filter(buffer -> !buffer.dropped()
        && buffer.kind() == BufferKind.BYTES && buffer.length() == length).findFirst().orElseThrow();
  }
}
