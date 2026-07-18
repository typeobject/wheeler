package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.packageformat.BuildPlan.Node;
import com.typeobject.wheeler.packageformat.BuildPlan.PackageInput;
import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.util.List;
import org.junit.jupiter.api.Test;

class BuildPlanCodecTest {
  @Test
  void planIsCanonicalContentAddressedAndOrderIndependent() {
    Node compiler = Node.create(
        "wheeler.compiler",
        "0.1.0",
        "1".repeat(64),
        "compiler",
        TargetKind.TOOL,
        "2".repeat(64),
        "compiler/compiler.wbc",
        List.of(new PackageInput("wheeler.bytecode", "3".repeat(64))),
        List.of(
            new Capability("build.write", "out/**"),
            new Capability("build.read", "src/**")));
    Node runtime = Node.create(
        "wheeler.runtime",
        "0.1.0",
        "4".repeat(64),
        "runtime",
        TargetKind.LIBRARY,
        "5".repeat(64),
        "runtime/runtime.wbc",
        List.of(),
        List.of());
    BuildPlan first = new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "6".repeat(64),
        "7".repeat(64),
        "bootstrap-1",
        List.of(runtime, compiler));
    BuildPlan second = new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "6".repeat(64),
        "7".repeat(64),
        "bootstrap-1",
        List.of(compiler, runtime));
    BuildPlanCodec codec = new BuildPlanCodec();

    byte[] encoded = codec.encode(first);
    assertArrayEquals(encoded, codec.encode(second));
    assertEquals(first, codec.decode(encoded));
    assertEquals(64, codec.identity(encoded).length());
  }

  @Test
  void decoderRejectsCorruptionTrailingDataAndForgedNodeIdentity() {
    Node node = Node.create(
        "demo.package",
        "1.0.0",
        "1".repeat(64),
        "main",
        TargetKind.BINARY,
        "2".repeat(64),
        "demo/main.wbc",
        List.of(),
        List.of());
    BuildPlan plan = new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "3".repeat(64),
        "4".repeat(64),
        "bootstrap-1",
        List.of(node));
    BuildPlanCodec codec = new BuildPlanCodec();
    byte[] corrupted = codec.encode(plan);
    corrupted[corrupted.length - 1] ^= 1;

    assertThrows(PackageFormatException.class, () -> codec.decode(corrupted));
    assertThrows(
        PackageFormatException.class,
        () -> codec.decode(java.util.Arrays.copyOf(corrupted, corrupted.length + 1)));
    assertThrows(
        PackageFormatException.class,
        () -> new Node(
            "0".repeat(64),
            node.packageName(),
            node.packageVersion(),
            node.manifestIdentity(),
            node.targetName(),
            node.targetKind(),
            node.sourceIdentity(),
            node.outputPath(),
            node.packageInputs(),
            node.capabilities()));
  }
}
