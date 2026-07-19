package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical-YAML dependency locks. */
class NativeLockExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesABoundedLock() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Lock.w", PackageSources.read("packages/resolution/Lock.w"),
            "LineEmitter.w", PackageSources.read("packages/manifest/LineEmitter.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "Names.w", PackageSources.read("packages/workspace/Names.w"),
            "NativeLock.w", Files.readString(root.resolve("NativeLock.w")),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "Semver.w", PackageSources.read("packages/resolution/Semver.w")),
        "examples.packages.lock_main");
    String a = "a".repeat(64);
    String b = "b".repeat(64);
    String c = "c".repeat(64);
    String d = "d".repeat(64);
    String e = "e".repeat(64);
    String canonical =
        "schema: 2\n"
            + "root: \"" + a + "\"\n"
            + "packages:\n"
            + "  - name: \"demo.app\"\n"
            + "    version: \"1.0.0\"\n"
            + "    repository: \"" + a + "\"\n"
            + "    archive: \"" + b + "\"\n"
            + "    manifest: \"" + c + "\"\n"
            + "    dependencies:\n"
            + "      - \"demo.base\"\n"
            + "  - name: \"demo.base\"\n"
            + "    version: \"2.1.0\"\n"
            + "    repository: \"" + a + "\"\n"
            + "    archive: \"" + d + "\"\n"
            + "    manifest: \"" + e + "\"\n"
            + "    dependencies: []\n";
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(17, machine.global("rootStart"));
    assertEquals(2, machine.global("packageCount"));
    assertEquals(8, machine.global("firstNameLength"));
    assertEquals(5, machine.global("firstVersionLength"));
    assertEquals(9, machine.global("secondNameLength"));
    assertEquals(1, machine.global("edgeCount"));
    assertEquals(canonical.length(), machine.global("emittedLength"));
    assertEquals(canonical.length(), machine.global("finalCursor"));
    assertEquals(canonical, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    new PackageLockParser().parse(machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String eightPackages = lockWithPackages(8, a, b, c);
    VirtualMachine larger = vm(program, eightPackages);
    larger.run();
    assertEquals(8, larger.global("packageCount"));
    assertEquals(8, larger.global("lastNameLength"));
    assertEquals(0, larger.global("edgeCount"));
    assertEquals(eightPackages, new String(larger.hostOutput(), StandardCharsets.UTF_8));
    new PackageLockParser().parse(larger.hostOutput());
    assertTraps(program, lockWithPackages(9, a, b, c));

    String empty = "schema: 2\nroot: \"" + a + "\"\npackages: []\n";
    VirtualMachine emptyMachine = vm(program, empty);
    emptyMachine.run();
    assertEquals(0, emptyMachine.global("packageCount"));
    new PackageLockParser().parse(emptyMachine.hostOutput());

    assertTraps(program, canonical.replace("schema: 2", "schema: 1"));
    assertTraps(program, canonical.replace(a, "A" + a.substring(1)));
    assertTraps(
        program,
        canonical.replace("name: \"demo.app\"", "name: \"demo.base\""));
    assertTraps(
        program,
        canonical.replace("      - \"demo.base\"", "      - \"demo.missing\""));
    assertTraps(
        program,
        canonical.replace(
            "      - \"demo.base\"\n",
            "      - \"demo.base\"\n      - \"demo.app\"\n"));
  }

  private static String lockWithPackages(
      int count, String repository, String archive, String manifest) {
    StringBuilder source = new StringBuilder()
        .append("schema: 2\nroot: \"").append(repository).append("\"\npackages:\n");
    for (int index = 0; index < count; index++) {
      String suffix = index < 10 ? "0" + index : Integer.toString(index);
      source.append("  - name: \"demo.p").append(suffix).append("\"\n")
          .append("    version: \"1.0.0\"\n")
          .append("    repository: \"").append(repository).append("\"\n")
          .append("    archive: \"").append(archive).append("\"\n")
          .append("    manifest: \"").append(manifest).append("\"\n")
          .append("    dependencies: []\n");
    }
    return source.toString();
  }

  private static void assertTraps(Program program, String source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
  }

  private static VirtualMachine vm(Program program, String source) {
    byte[] input = source.getBytes(StandardCharsets.UTF_8);
    return new VirtualMachine(program, input, input.length);
  }
}
