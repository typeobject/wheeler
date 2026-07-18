package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeManifestExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesTheBoundedManifest() throws Exception {
    Path root = Path.of("src/main/wheeler");
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "ManifestEmitter.w", Files.readString(root.resolve("packages/ManifestEmitter.w")),
            "Manifest.w", Files.readString(root.resolve("packages/Manifest.w")),
            "Names.w", Files.readString(root.resolve("packages/Names.w")),
            "NativeManifest.w", Files.readString(root.resolve("NativeManifest.w")),
            "Paths.w", Files.readString(root.resolve("packages/Paths.w")),
            "Scanner.w", Files.readString(root.resolve("lexer/Scanner.w")),
            "Semver.w", Files.readString(root.resolve("packages/Semver.w"))),
        "examples.packages.main");
    String source =
        "package \"demo.native\" version \"1.2.3-rc.1\" profile \"boot\\\"strap\"; "
            + "target example \"app\" root \"src/A\\\"pp.w\" "
            + "module \"demo.app\" source \"src/A\\\"pp.w\" "
            + "source \"src/Helper.w\"; "
            + "dependency normal \"demo.base\" version \"^1.0.0\"; "
            + "capability \"fixture\" path \"test-data\";";
    String input = source.replace("; target", ";   target");
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(9, machine.global("nameStart"));
    assertEquals(11, machine.global("nameLength"));
    assertEquals(10, machine.global("versionLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(1, machine.global("targetCount"));
    assertEquals(3, machine.global("targetNameLength"));
    assertEquals(11, machine.global("targetRootLength"));
    assertEquals(8, machine.global("targetModuleLength"));
    assertEquals(2, machine.global("targetSourceCount"));
    assertEquals(11, machine.global("targetSourceLength"));
    assertEquals(12, machine.global("targetSecondSourceLength"));
    assertEquals(0, machine.global("targetThirdSourceLength"));
    assertEquals(0, machine.global("targetFourthSourceLength"));
    assertEquals(1, machine.global("dependencyCount"));
    assertEquals(9, machine.global("dependencyNameLength"));
    assertEquals(6, machine.global("dependencyVersionLength"));
    assertEquals(1, machine.global("capabilityCount"));
    assertEquals(7, machine.global("capabilityNameLength"));
    assertEquals(9, machine.global("capabilityPathLength"));
    assertEquals(source.length(), machine.global("emittedLength"));
    assertEquals(input.length(), machine.global("finalCursor"));
    assertEquals(source, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    for (String kind : new String[] {"binary", "library", "tool", "test"}) {
      assertRunsCanonical(
          program,
          source.replace("target example", "target " + kind));
    }
    for (String kind : new String[] {"development", "build"}) {
      assertRunsCanonical(
          program,
          source.replace("dependency normal", "dependency " + kind));
    }
    String fourSources = source.replace(
        "source \"src/Helper.w\"",
        "source \"src/Helper.w\" source \"src/Other.w\" "
            + "source \"src/Zed.w\"");
    VirtualMachine fourSourceMachine = vm(program, fourSources);
    fourSourceMachine.run();
    assertEquals(4, fourSourceMachine.global("targetSourceCount"));
    assertEquals(11, fourSourceMachine.global("targetThirdSourceLength"));
    assertEquals(9, fourSourceMachine.global("targetFourthSourceLength"));
    assertEquals(
        fourSources,
        new String(fourSourceMachine.hostOutput(), StandardCharsets.UTF_8));

    String malformedSource =
        "project \"demo.native\" version \"1.2.3\" profile \"bootstrap-1\"; "
            + "target example \"app\" root \"src/App.w\"; "
            + "dependency normal \"demo.base\" version \"^1.0.0\"; "
            + "capability \"fixture\" path \"test-data\";";
    assertTraps(program, malformedSource);
    assertTraps(program, source.replace("1.2.3-rc.1", "01.2.3"));
    assertTraps(
        program,
        source.replace("1.2.3-rc.1", "9223372036854775808.2.3"));
    assertTraps(program, source.replace("1.2.3-rc.1", "1.2.3-01"));
    assertTraps(program, source.replace("demo.native", "Demo.native"));
    assertTraps(program, source.replace("demo.base", "demo.-base"));
    assertTraps(program, source.replace("target example", "target app"));
    assertTraps(program, source.replace("demo.app", "demo.-app"));
    assertTraps(
        program,
        source.replace(
            "source \"src/A\\\"pp.w\"",
            "source \"src/Other.w\""));
    assertTraps(
        program,
        source.replace(
            "source \"src/A\\\"pp.w\" source \"src/Helper.w\"",
            "source \"src/Helper.w\" source \"src/A\\\"pp.w\""));
    assertTraps(
        program,
        source.replace(
            "source \"src/Helper.w\"",
            "source \"src/A\\\"pp.w\""));
    assertTraps(program, source.replace("source \"src/A\\\"pp.w\"", "source \"../App.w\""));
    assertTraps(program, source.replace("dependency normal", "dependency runtime"));
    assertTraps(program, source.replace("src/A\\\"pp.w", "src/../App.w"));
    assertTraps(program, source.replace("test-data", "test\\\\data"));
    assertTraps(program, source.replace("boot\\\"strap", "boot\\nstrap"));
  }

  private static void assertRunsCanonical(Program program, String input) {
    VirtualMachine machine = vm(program, input);
    machine.run();
    assertEquals(input, new String(machine.hostOutput(), StandardCharsets.UTF_8));
  }

  private static void assertTraps(Program program, String input) {
    VirtualMachine machine = vm(program, input);
    assertThrows(VmTrap.class, machine::run);
  }

  private static VirtualMachine vm(Program program, String input) {
    byte[] bytes = input.getBytes(StandardCharsets.UTF_8);
    return new VirtualMachine(program, bytes, bytes.length);
  }
}
