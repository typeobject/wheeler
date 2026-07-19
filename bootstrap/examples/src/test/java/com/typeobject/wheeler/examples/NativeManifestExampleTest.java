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

/** Conformance tests for Wheeler-native package-manifest parsing and emission. */
class NativeManifestExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesTheBoundedManifest() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "ManifestEmitter.w", PackageSources.read("packages/manifest/ManifestEmitter.w"),
            "Manifest.w", PackageSources.read("packages/manifest/Manifest.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "Names.w", PackageSources.read("packages/workspace/Names.w"),
            "NativeManifest.w", Files.readString(root.resolve("NativeManifest.w")),
            "Paths.w", PackageSources.read("packages/workspace/Paths.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "Semver.w", PackageSources.read("packages/resolution/Semver.w")),
        "examples.packages.main");
    String source =
        "package \"demo.native\" version \"1.2.3-rc.1\" profile \"boot\\\"strap\"; "
            + "target deployable \"app\" root \"src/A\\\"pp.w\" "
            + "module \"demo.app\" source \"src/A\\\"pp.w\" "
            + "source \"src/Helper.w\" test; "
            + "target tool \"tool\" root \"src/Tool.w\" test; "
            + "dependency normal \"demo.base\" version \"^1.0.0\"; "
            + "dependency development \"demo.extra\" version \"~2.1.0\"; "
            + "capability \"fixture\" path \"test-data\"; "
            + "capability \"logs\" path \"logs\";";
    String input = source.replace("; target", ";   target");
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(9, machine.global("nameStart"));
    assertEquals(11, machine.global("nameLength"));
    assertEquals(10, machine.global("versionLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(3, machine.global("targetNameLength"));
    assertEquals(11, machine.global("targetRootLength"));
    assertEquals(8, machine.global("targetModuleLength"));
    assertEquals(2, machine.global("targetSourceCount"));
    assertEquals(11, machine.global("targetSourceLength"));
    assertEquals(12, machine.global("targetSecondSourceLength"));
    assertEquals(0, machine.global("targetThirdSourceLength"));
    assertEquals(0, machine.global("targetFourthSourceLength"));
    assertEquals(1, machine.global("targetTest"));
    assertEquals(2, machine.global("targetCount"));
    assertEquals(4, machine.global("secondTargetNameLength"));
    assertEquals(10, machine.global("secondTargetRootLength"));
    assertEquals(1, machine.global("secondTargetTest"));
    assertEquals(2, machine.global("dependencyCount"));
    assertEquals(9, machine.global("dependencyNameLength"));
    assertEquals(6, machine.global("dependencyVersionLength"));
    assertEquals(10, machine.global("secondDependencyNameLength"));
    assertEquals(6, machine.global("secondDependencyVersionLength"));
    assertEquals(2, machine.global("capabilityCount"));
    assertEquals(7, machine.global("capabilityNameLength"));
    assertEquals(9, machine.global("capabilityPathLength"));
    assertEquals(4, machine.global("secondCapabilityNameLength"));
    assertEquals(4, machine.global("secondCapabilityPathLength"));
    assertEquals(source.length(), machine.global("emittedLength"));
    assertEquals(input.length(), machine.global("finalCursor"));
    assertEquals(source, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertRunsCanonical(program, source.replace("target deployable", "target tool"));
    assertRunsCanonical(
        program,
        source.replace(" test", "").replace("target deployable", "target library"));
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
            + "target deployable \"app\" root \"src/App.w\"; "
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
    assertTraps(program, source.replace("demo.extra", "demo.base"));
    assertTraps(
        program,
        source.replace(
            "dependency normal \"demo.base\" version \"^1.0.0\"; "
                + "dependency development \"demo.extra\" version \"~2.1.0\";",
            "dependency development \"demo.extra\" version \"~2.1.0\"; "
                + "dependency normal \"demo.base\" version \"^1.0.0\";"));
    assertTraps(program, source.replace("target deployable", "target app"));
    assertTraps(program, source.replace("target deployable", "target library"));
    assertTraps(program, source.replace("\"tool\" root", "\"app\" root"));
    assertTraps(
        program,
        source.replace(
            "target deployable \"app\"",
            "target deployable \"zoo\""));
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
    assertTraps(
        program,
        source.replace(
            "capability \"logs\" path \"logs\"",
            "capability \"fixture\" path \"test-data\""));
    assertTraps(
        program,
        source.replace(
            "capability \"fixture\" path \"test-data\"; "
                + "capability \"logs\" path \"logs\";",
            "capability \"logs\" path \"logs\"; "
                + "capability \"fixture\" path \"test-data\";"));
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
