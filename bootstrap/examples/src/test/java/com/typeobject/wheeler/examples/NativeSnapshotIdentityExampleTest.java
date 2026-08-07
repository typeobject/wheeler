package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.RepositorySnapshot;
import com.typeobject.wheeler.packageformat.RepositorySnapshot.Entry;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native repository snapshot identities. */
final class NativeSnapshotIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/packages/identity/NativeSnapshotIdentity.w");

  @Test
  void validatesBeforePublishingTheCanonicalSnapshotIdentity() throws Exception {
    Program program = program();
    RepositorySnapshot snapshot = snapshot(3);
    byte[] canonical = snapshot.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical), machine.hostOutput());
    assertEquals(snapshot.identity(), java.util.HexFormat.of().formatHex(machine.hostOutput()));
    assertEquals(3, machine.global("releaseCount"));
    assertEquals(canonical.length, machine.global("sourceLength"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] empty = new RepositorySnapshot(List.of()).canonicalBytes();
    VirtualMachine emptyMachine = vm(program, empty);
    emptyMachine.run();
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(empty), emptyMachine.hostOutput());
    assertEquals(0, emptyMachine.global("releaseCount"));

    byte[] noncanonical = snapshot.canonicalText()
        .replace("schema: 1", "schema:  1")
        .getBytes(StandardCharsets.UTF_8);
    VirtualMachine malformed = vm(program, noncanonical);
    assertThrows(VmTrap.class, malformed::run);
    assertArrayEquals(new byte[32], malformed.hostOutput());

    byte[] four = snapshot(4).canonicalBytes();
    VirtualMachine full = vm(program, four);
    assertThrows(VmTrap.class, full::run);
    assertArrayEquals(new byte[32], full.hostOutput());

    VirtualMachine oversized = vm(program, new byte[2049]);
    assertThrows(VmTrap.class, oversized::run);
    assertArrayEquals(new byte[32], oversized.hostOutput());
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeSnapshotIdentity.w", Files.readString(FIXTURE),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Snapshot.w", PackageSources.read("packages/repository/Snapshot.w"),
            "Semver.w", PackageSources.read("packages/resolution/Semver.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.packages.snapshot_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static RepositorySnapshot snapshot(int count) {
    List<Entry> entries = new ArrayList<>();
    for (int index = 0; index < count; index++) {
      entries.add(new Entry(
          "demo.p0" + index,
          "1.0." + index,
          Integer.toHexString(index).repeat(64),
          Integer.toHexString(index + 1).repeat(64)));
    }
    return new RepositorySnapshot(entries);
  }
}
