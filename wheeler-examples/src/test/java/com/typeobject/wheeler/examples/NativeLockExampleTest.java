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

/** Conformance tests for Wheeler-native dependency-lock parsing and emission. */
class NativeLockExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesABoundedLock() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Lock.w", Files.readString(root.resolve("packages/Lock.w")),
            "LineEmitter.w", Files.readString(root.resolve("packages/LineEmitter.w")),
            "ManifestTokens.w", Files.readString(root.resolve("packages/ManifestTokens.w")),
            "Names.w", Files.readString(root.resolve("packages/Names.w")),
            "NativeLock.w", Files.readString(root.resolve("NativeLock.w")),
            "Scanner.w", Files.readString(root.resolve("lexer/Scanner.w")),
            "Semver.w", Files.readString(root.resolve("packages/Semver.w"))),
        "examples.packages.lock_main");
    String a = "a".repeat(64);
    String b = "b".repeat(64);
    String c = "c".repeat(64);
    String d = "d".repeat(64);
    String e = "e".repeat(64);
    String canonical =
        "lock 1 root \"" + a + "\";\n"
            + "package \"demo.app\" version \"1.0.0\" archive \"" + b
            + "\" manifest \"" + c + "\";\n"
            + "package \"demo.base\" version \"2.1.0\" archive \"" + d
            + "\" manifest \"" + e + "\";\n"
            + "edge \"demo.app\" \"demo.base\";\n";
    String input = canonical.replace(" package", "  package")
        .replace("\n", "\n  ");
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(13, machine.global("rootStart"));
    assertEquals(2, machine.global("packageCount"));
    assertEquals(8, machine.global("firstNameLength"));
    assertEquals(5, machine.global("firstVersionLength"));
    assertEquals(9, machine.global("secondNameLength"));
    assertEquals(1, machine.global("edgeCount"));
    assertEquals(canonical.length(), machine.global("emittedLength"));
    assertEquals(input.length(), machine.global("finalCursor"));
    assertEquals(canonical, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    new PackageLockParser().parse(machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertTraps(program, canonical.replace("lock 1", "lock 2"));
    assertTraps(program, canonical.replace(a, "A" + a.substring(1)));
    assertTraps(
        program,
        canonical.replace(
            "package \"demo.app\" version \"1.0.0\"",
            "package \"demo.base\" version \"1.0.0\""));
    assertTraps(
        program,
        canonical.replace(
            "edge \"demo.app\" \"demo.base\"",
            "edge \"demo.base\" \"demo.app\""));
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
