package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeManifestExampleTest {
  @Test
  void wheelerParsesTheCanonicalPackageHeader() throws Exception {
    Path root = Path.of("src/main/wheeler");
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeManifest.w", Files.readString(root.resolve("NativeManifest.w")),
            "Manifest.w", Files.readString(root.resolve("packages/Manifest.w")),
            "Scanner.w", Files.readString(root.resolve("lexer/Scanner.w"))),
        "examples.packages.main");
    String source =
        "package \"demo.native\" version \"1.2.3\" profile \"bootstrap-1\"; "
            + "target example \"app\" root \"src/App.w\"; "
            + "dependency runtime \"demo.base\" version \"^1.0.0\";";
    VirtualMachine machine = new VirtualMachine(
        program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();

    machine.run();

    assertEquals(9, machine.global("nameStart"));
    assertEquals(11, machine.global("nameLength"));
    assertEquals(5, machine.global("versionLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(1, machine.global("targetCount"));
    assertEquals(3, machine.global("targetNameLength"));
    assertEquals(9, machine.global("targetRootLength"));
    assertEquals(1, machine.global("dependencyCount"));
    assertEquals(9, machine.global("dependencyNameLength"));
    assertEquals(6, machine.global("dependencyVersionLength"));
    assertEquals(source.length(), machine.global("finalCursor"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    VirtualMachine malformed = new VirtualMachine(
        program,
        ("project \"demo.native\" version \"1.2.3\" "
            + "profile \"bootstrap-1\"; target example \"app\" "
            + "root \"src/App.w\"; dependency runtime \"demo.base\" "
            + "version \"^1.0.0\";")
            .getBytes(StandardCharsets.UTF_8));
    assertThrows(VmTrap.class, malformed::run);
  }
}
