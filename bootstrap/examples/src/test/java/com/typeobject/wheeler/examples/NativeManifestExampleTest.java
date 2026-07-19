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

/** Differential tests for Wheeler-native parsing of canonical package YAML. */
class NativeManifestExampleTest {
  private static final String MANIFEST = """
      schema: 1
      package:
        name: "demo.native"
        version: "1.2.3-rc.1"
        profile: "bootstrap-1"
      targets:
        - kind: "deployable"
          name: "app"
          root: "src/App.w"
          module: "demo.app"
          sources:
            - "src/App.w"
            - "src/Helper.w"
          test: true
        - kind: "tool"
          name: "tool"
          root: "src/Tool.w"
          test: true
      dependencies:
        - kind: "normal"
          name: "demo.base"
          version: "^1.0.0"
        - kind: "development"
          name: "demo.extra"
          version: "~2.1.0"
      capabilities:
        - name: "fixture"
          path: "test-data"
        - name: "logs"
          path: "logs"
      """;

  @Test
  void wheelerParsesTheSameCanonicalManifestAsStageZero() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    Program program = new WheelerCompiler().compileModuleFiles(
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
    assertEquals(MANIFEST, new com.typeobject.wheeler.packageformat.PackageManifestParser()
        .parse(MANIFEST).canonicalText());
    VirtualMachine machine = vm(program, MANIFEST);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(11, machine.global("nameLength"));
    assertEquals(10, machine.global("versionLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(2, machine.global("targetCount"));
    assertEquals(2, machine.global("targetSourceCount"));
    assertEquals(2, machine.global("dependencyCount"));
    assertEquals(2, machine.global("capabilityCount"));
    assertEquals(MANIFEST, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertTraps(program, MANIFEST.replace("schema: 1", "schema: 2"));
    assertTraps(program, MANIFEST.replace("kind: \"tool\"", "kind: \"plugin\""));
    assertTraps(program, MANIFEST.replace("name: \"demo.base\"", "name: \"demo.-base\""));
    assertTraps(program, MANIFEST.replace("root: \"src/App.w\"", "root: \"../App.w\""));
  }

  private static void assertTraps(Program program, String input) {
    assertThrows(VmTrap.class, () -> vm(program, input).run());
  }

  private static VirtualMachine vm(Program program, String input) {
    byte[] bytes = input.getBytes(StandardCharsets.UTF_8);
    return new VirtualMachine(program, bytes, bytes.length);
  }
}
