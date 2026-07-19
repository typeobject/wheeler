package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlan.ExecutionLimits;
import com.typeobject.wheeler.packageformat.BuildPlan.Node;
import com.typeobject.wheeler.packageformat.BuildPlan.PackageInput;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for Wheeler-native build-plan verification. */
class NativePlanExampleTest {
  @Test
  void wheelerInspectsOneDigestCheckedBuildNode() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    Program inspector = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Binary.w", CoreSources.read("encoding/Binary.w"),
            "NativePlan.w", Files.readString(root.resolve("NativePlan.w")),
            "Plan.w", PackageSources.read("packages/resolution/Plan.w"),
            "PlanIdentity.w", PackageSources.read("packages/resolution/PlanIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "examples.packages.plan_main");
    Node node = Node.create(
        "demo.plan",
        "1.2.3",
        "1".repeat(64),
        "main",
        TargetKind.DEPLOYABLE,
        "2".repeat(64),
        "build/main.wbc",
        List.of(),
        List.of(),
        new ExecutionLimits(1_000, 2_000, 3_000, 4_000, 5_000),
        List.of());
    byte[] encoded = new BuildPlanCodec().encode(new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "6".repeat(64),
        "7".repeat(64),
        "bootstrap-1",
        List.of(node)));
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, encoded);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(11, machine.global("profileLength"));
    assertEquals(9, machine.global("packageLength"));
    assertEquals(5, machine.global("versionLength"));
    assertEquals(4, machine.global("targetLength"));
    assertEquals(14, machine.global("outputLength"));
    assertEquals(2, machine.global("targetKind"));
    assertEquals(0, machine.global("inputCount"));
    assertEquals(0, machine.global("requestCount"));
    assertEquals(0, machine.global("grantCount"));
    assertEquals(1_000, machine.global("maxSteps"));
    assertEquals(5_000, machine.global("timeout"));
    assertEquals(encoded.length, machine.global("finalLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    Node bounded = Node.create(
        "demo.plan",
        "1.2.3",
        "1".repeat(64),
        "main",
        TargetKind.DEPLOYABLE,
        "2".repeat(64),
        "build/main.wbc",
        List.of(new PackageInput("demo.input", "3".repeat(64))),
        List.of(new Capability("build.read", "src/**")),
        new ExecutionLimits(1_000, 2_000, 3_000, 4_000, 5_000),
        List.of(new Capability("build.read", "src/**")));
    byte[] boundedEncoded = new BuildPlanCodec().encode(new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "6".repeat(64),
        "7".repeat(64),
        "bootstrap-1",
        List.of(bounded)));
    VirtualMachine boundedMachine = VirtualMachine.withBinaryInput(
        inspector, boundedEncoded);
    boundedMachine.run();
    assertEquals(1, boundedMachine.global("inputCount"));
    assertEquals(1, boundedMachine.global("requestCount"));
    assertEquals(1, boundedMachine.global("grantCount"));
    new BuildPlanCodec().decode(boundedEncoded);
    byte[] expandedGrant = boundedEncoded.clone();
    expandedGrant[grantPatternOffset(expandedGrant)] = 'b';
    resignPayload(expandedGrant);
    assertRejected(inspector, expandedGrant);

    byte[] corruptPayload = encoded.clone();
    corruptPayload[80] ^= 1;
    assertRejected(inspector, corruptPayload);
    byte[] corruptDigest = encoded.clone();
    corruptDigest[corruptDigest.length - 1] ^= 1;
    assertRejected(inspector, corruptDigest);
    byte[] invalidKind = encoded.clone();
    ByteBuffer.wrap(invalidKind)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(targetKindOffset(invalidKind), 0);
    resignPayload(invalidKind);
    assertRejected(inspector, invalidKind);
    byte[] forgedNodeIdentity = encoded.clone();
    forgedNodeIdentity[nodeIdentityOffset(forgedNodeIdentity)] ^= 1;
    resignPayload(forgedNodeIdentity);
    assertRejected(inspector, forgedNodeIdentity);
  }

  private static void assertRejected(Program inspector, byte[] plan) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, plan);
    assertThrows(VmTrap.class, machine::run);
  }

  private static int nodeIdentityOffset(byte[] plan) {
    ByteBuffer bytes = ByteBuffer.wrap(plan).order(ByteOrder.LITTLE_ENDIAN);
    int cursor = 80;
    cursor += Integer.BYTES + bytes.getInt(cursor);
    cursor += Integer.BYTES;
    return cursor;
  }

  private static int targetKindOffset(byte[] plan) {
    ByteBuffer bytes = ByteBuffer.wrap(plan).order(ByteOrder.LITTLE_ENDIAN);
    int cursor = 80;
    cursor += Integer.BYTES + bytes.getInt(cursor);
    cursor += Integer.BYTES;
    cursor += 32;
    cursor += Integer.BYTES + bytes.getInt(cursor);
    cursor += Integer.BYTES + bytes.getInt(cursor);
    cursor += 32;
    cursor += Integer.BYTES + bytes.getInt(cursor);
    return cursor;
  }

  private static int grantPatternOffset(byte[] plan) {
    ByteBuffer bytes = ByteBuffer.wrap(plan).order(ByteOrder.LITTLE_ENDIAN);
    int cursor = targetKindOffset(plan) + Integer.BYTES + 32;
    cursor += Integer.BYTES + bytes.getInt(cursor);
    int inputCount = bytes.getInt(cursor);
    cursor += Integer.BYTES;
    if (inputCount == 1) {
      cursor += Integer.BYTES + bytes.getInt(cursor) + 32;
    }
    int requestCount = bytes.getInt(cursor);
    cursor += Integer.BYTES;
    if (requestCount == 1) {
      cursor += Integer.BYTES + bytes.getInt(cursor);
      cursor += Integer.BYTES + bytes.getInt(cursor);
    }
    cursor += 5 * Long.BYTES;
    int grantCount = bytes.getInt(cursor);
    cursor += Integer.BYTES;
    if (grantCount != 1) {
      throw new AssertionError("missing grant");
    }
    cursor += Integer.BYTES + bytes.getInt(cursor);
    return cursor + Integer.BYTES;
  }

  private static void resignPayload(byte[] plan) throws Exception {
    ByteBuffer bytes = ByteBuffer.wrap(plan).order(ByteOrder.LITTLE_ENDIAN);
    int payloadLength = bytes.getInt(12);
    byte[] digest = MessageDigest.getInstance("SHA-256")
        .digest(java.util.Arrays.copyOfRange(plan, 16, 16 + payloadLength));
    System.arraycopy(digest, 0, plan, 16 + payloadLength, digest.length);
  }
}
