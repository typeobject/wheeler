package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlan.ExecutionLimits;
import com.typeobject.wheeler.packageformat.BuildPlan.Node;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical build-plan identities. */
final class NativePlanIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "src/main/wheeler/native/packages/NativePlanIdentity.w");

  @Test
  void validatesBeforePublishingTheCanonicalPlanIdentity() throws Exception {
    Program program = program();
    Node node = Node.create(
        "demo.plan",
        "1.2.3",
        "1".repeat(64),
        "main",
        TargetKind.TOOL,
        "2".repeat(64),
        "build/main.wbc",
        List.of(),
        List.of(),
        new ExecutionLimits(1_000, 2_000, 3_000, 4_000, 5_000),
        List.of());
    BuildPlanCodec codec = new BuildPlanCodec();
    byte[] plan = codec.encode(new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "3".repeat(64),
        "4".repeat(64),
        "bootstrap-1",
        List.of(node)));
    VirtualMachine machine = vm(program, plan);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(plan);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(codec.identity(plan), HexFormat.of().formatHex(expected));
    assertEquals("demo.plan".length(), machine.global("packageLength"));
    assertEquals("main".length(), machine.global("targetLength"));
    assertEquals(plan.length, machine.global("sourceLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] damaged = plan.clone();
    damaged[damaged.length - 1] ^= 1;
    assertNoIdentity(program, damaged);
    assertNoIdentity(program, new byte[4097]);
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativePlanIdentity.w", Files.readString(FIXTURE),
            "Plan.w", PackageSources.read("packages/resolution/Plan.w"),
            "PlanIdentity.w", PackageSources.read("packages/resolution/PlanIdentity.w"),
            "Binary.w", CoreSources.read("encoding/Binary.w"),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "examples.packages.plan_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
  }
}
