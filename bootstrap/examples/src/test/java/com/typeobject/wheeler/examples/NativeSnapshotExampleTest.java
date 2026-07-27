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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for the Wheeler-native immutable repository snapshot codec. */
final class NativeSnapshotExampleTest {
  private static final Path FIXTURE = Path.of(
      "src/main/wheeler/native/packages/NativeSnapshot.w");

  @Test
  void parsesCanonicalSnapshotsIntoBoundedCallerTables() throws Exception {
    Program program = program();
    RepositorySnapshot snapshot = new RepositorySnapshot(List.of(
        entry("demo.alpha", "1.2.0", '1'),
        entry("demo.alpha", "1.10.0", '3'),
        entry("demo.beta", "2.0.0-preview.1", '5')));
    byte[] canonical = snapshot.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(canonical, machine.hostOutput());
    assertEquals(3, machine.global("releaseCount"));
    assertEquals("demo.alpha".length(), machine.global("firstPackageLength"));
    assertEquals("2.0.0-preview.1".length(), machine.global("lastVersionLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] empty = new RepositorySnapshot(List.of()).canonicalBytes();
    VirtualMachine emptyMachine = vm(program, empty);
    emptyMachine.run();
    assertArrayEquals(empty, emptyMachine.hostOutput());
    assertEquals(0, emptyMachine.global("releaseCount"));

    byte[] prereleases = new RepositorySnapshot(List.of(
        entry("demo.preview", "1.0.0-alpha", '7'),
        entry("demo.preview", "1.0.0-alpha.2", '9'),
        entry("demo.preview", "1.0.0-alpha.10", 'b'),
        entry("demo.preview", "1.0.0-beta", 'd'),
        entry("demo.preview", "1.0.0", '1'))).canonicalBytes();
    VirtualMachine preview = vm(program, prereleases);
    preview.run();
    assertArrayEquals(prereleases, preview.hostOutput());
    assertEquals(5, preview.global("releaseCount"));

    byte[] eight = snapshot(8).canonicalBytes();
    VirtualMachine full = vm(program, eight);
    full.run();
    assertArrayEquals(eight, full.hostOutput());
    assertEquals(8, full.global("releaseCount"));

    byte[] nine = snapshot(9).canonicalBytes();
    VirtualMachine overflow = vm(program, nine);
    assertThrows(VmTrap.class, overflow::run);
    assertArrayEquals(new byte[nine.length], overflow.hostOutput());

    byte[] noncanonical = snapshot.canonicalText()
        .replace("schema: 1", "schema:  1")
        .getBytes(StandardCharsets.UTF_8);
    VirtualMachine malformed = vm(program, noncanonical);
    assertThrows(VmTrap.class, malformed::run);
    assertArrayEquals(new byte[noncanonical.length], malformed.hostOutput());
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeSnapshot.w", Files.readString(FIXTURE),
            "Snapshot.w", PackageSources.read("packages/repository/Snapshot.w"),
            "Semver.w", PackageSources.read("packages/resolution/Semver.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "LineEmitter.w", PackageSources.read("packages/manifest/LineEmitter.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w")),
        "examples.packages.snapshot");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return new VirtualMachine(program, source, source.length);
  }

  private static RepositorySnapshot snapshot(int count) {
    List<Entry> entries = new ArrayList<>();
    for (int index = 0; index < count; index++) {
      String suffix = index < 10 ? "0" + index : Integer.toString(index);
      entries.add(entry("demo.p" + suffix, "1.0.0", hex(index)));
    }
    return new RepositorySnapshot(entries);
  }

  private static Entry entry(String name, String version, char identity) {
    return new Entry(
        name,
        version,
        Character.toString(identity).repeat(64),
        Character.toString(nextHex(identity)).repeat(64));
  }

  private static char hex(int index) {
    return "0123456789abcdef".charAt(index % 16);
  }

  private static char nextHex(char value) {
    int index = "0123456789abcdef".indexOf(value);
    return hex(index + 1);
  }
}
