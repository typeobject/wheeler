package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Native manifest and lock dependency policy evidence. */
final class NativeTestDependencyLockExampleTest {
  private static final String MANIFEST = """
      schema: 1
      package:
        name: "pkg"
        version: "1.0.0"
        profile: "bootstrap-1"
      targets:
        - kind: "deployable"
          name: "test"
          root: "src/Test.w"
          module: "pkg.test"
          sources:
            - "src/Test.w"
          test: true
      dependencies: []
      capabilities: []
      """;
  private static final String SOURCE = """
      module pkg.test;
      classical class DeclaredTest {
        test void passes() {
          assert(true);
        }
      }
      """;

  @Test
  void validatesNativeDependencyLockEntries() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String manifest = dependencyManifest("^1.0.0");
    byte[] lock = dependencyLock(manifest, "demo.dep", "1.0.0");

    assertPassing(runner, manifest, lock);
    assertPassing(runner, manifest, dependencyLockWithEdge(manifest, true));
    assertRejected(runner, manifest, dependencyLockWithEdge(manifest, false));
    assertRejected(runner, manifest, dependencyLockWithUnreachablePackage(manifest));
    assertRejected(runner, manifest, dependencyLockWithCycle(manifest));

    byte[] mismatchedLock = new String(lock, StandardCharsets.UTF_8)
        .replace("demo.dep", "demo.bad")
        .getBytes(StandardCharsets.UTF_8);
    assertRejected(runner, manifest, mismatchedLock);
    assertRejected(runner, manifest, dependencyLock(manifest, "demo.dep", "2.0.0"));
  }

  @Test
  void acceptsNativeStableDependencyConstraintKinds() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    for (String constraint : List.of("=1.0.0", "~1.0.0")) {
      String manifest = dependencyManifest(constraint);
      assertPassing(runner, manifest, dependencyLock(manifest, "demo.dep", "1.0.0"));
    }
  }

  @Test
  void enforcesNativePrereleaseDependencyConstraints() throws Exception {
    Program runner = NativeCoverageRunExampleTest.nativeTestRunner();
    String previewManifest = dependencyManifest("^1.0.0-beta.2");
    assertPassing(
        runner,
        previewManifest,
        dependencyLock(previewManifest, "demo.dep", "1.0.0-beta.11"));

    String stableManifest = dependencyManifest("^1.0.0");
    assertRejected(
        runner,
        stableManifest,
        dependencyLock(stableManifest, "demo.dep", "1.1.0-beta"));
  }

  private static void assertPassing(Program runner, String manifest, byte[] lock) {
    byte[] report = execute(runner, transport(manifest, lock));
    assertEquals(1, report[32]);
    assertEquals(1, report[34]);
  }

  private static void assertRejected(Program runner, String manifest, byte[] lock) {
    VirtualMachine invalid = VirtualMachine.withBinaryInput(runner, transport(manifest, lock), 39);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(invalid));
    assertArrayEquals(new byte[39], invalid.hostOutput());
  }

  private static byte[] transport(String manifest, byte[] lock) {
    byte[] plan = NativeTestSourcePlan.write(
        List.of(new NativeTestSourcePlan.Source("src/Test.w", SOURCE)));
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0).putShort((short) 1).array());
    writeShortText(input, "pkg");
    writeShortText(input, "1.0.0");
    writeShortText(input, "test");
    writeBytes(input, manifest.getBytes(StandardCharsets.UTF_8));
    writeBytes(input, lock);
    input.write(0);
    writeBytes(input, plan);
    input.write(0);
    input.write(255);
    return input.toByteArray();
  }

  private static String dependencyManifest(String constraint) {
    return MANIFEST.replace(
        "dependencies: []",
        "dependencies:\n"
            + "  - kind: \"normal\"\n"
            + "    name: \"demo.dep\"\n"
            + "    version: \"" + constraint + "\"");
  }

  private static byte[] dependencyLock(String manifest, String name, String version) {
    String root = new String(
        NativeTestManifestInput.emptyLock(manifest), StandardCharsets.UTF_8).substring(17, 81);
    String digest = "0".repeat(64);
    return ("""
        schema: 3
        root: "%s"
        packages:
          - name: "%s"
            version: "%s"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(root, name, version, digest, digest, digest, digest)
        .getBytes(StandardCharsets.UTF_8);
  }

  private static byte[] dependencyLockWithEdge(String manifest, boolean includeTarget) {
    String lock = new String(
        dependencyLock(manifest, "demo.dep", "1.0.0"), StandardCharsets.UTF_8);
    String edge = "    dependencies:\n      - \"demo.transitive\"\n";
    if (includeTarget) {
      edge += lockedPackage("demo.transitive", "    dependencies: []\n");
    }
    return lock.replace("    dependencies: []\n", edge)
        .getBytes(StandardCharsets.UTF_8);
  }

  private static byte[] dependencyLockWithUnreachablePackage(String manifest) {
    String lock = new String(
        dependencyLock(manifest, "demo.dep", "1.0.0"), StandardCharsets.UTF_8);
    return lock.replace(
        "    dependencies: []\n",
        "    dependencies: []\n" + lockedPackage("demo.extra", "    dependencies: []\n"))
        .getBytes(StandardCharsets.UTF_8);
  }

  private static byte[] dependencyLockWithCycle(String manifest) {
    String lock = new String(
        dependencyLockWithEdge(manifest, true), StandardCharsets.UTF_8);
    return lock.replace(
        "    dependencies: []\n",
        "    dependencies:\n      - \"demo.dep\"\n")
        .getBytes(StandardCharsets.UTF_8);
  }

  private static String lockedPackage(String name, String dependencies) {
    String digest = "0".repeat(64);
    return ("  - name: \"%s\"\n"
        + "    version: \"1.0.0\"\n"
        + "    repository: \"%s\"\n"
        + "    snapshot: \"%s\"\n"
        + "    archive: \"%s\"\n"
        + "    manifest: \"%s\"\n"
        + dependencies).formatted(name, digest, digest, digest, digest);
  }

  private static void writeShortText(ByteArrayOutputStream output, String text) {
    byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeBytes(ByteArrayOutputStream output, byte[] bytes) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(bytes.length).array());
    output.writeBytes(bytes);
  }

  private static byte[] execute(Program runner, byte[] input) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(runner, input, 39);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }
}
