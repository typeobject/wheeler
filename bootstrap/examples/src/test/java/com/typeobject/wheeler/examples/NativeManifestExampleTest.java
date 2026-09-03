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
import java.util.LinkedHashMap;
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
    Path root = Path.of("../wheeler-conformance/src/main/wheeler/packages");
    Map<String, String> modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.packages.manifest"));
    modules.put(
        "ManifestEmitter.w", PackageSources.read("packages/manifest/ManifestEmitter.w"));
    modules.put("NativeManifest.w", Files.readString(root.resolve("NativeManifest.w")));
    modules.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    Program program = new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.packages.main");
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

    String lateRootCoverage = MANIFEST.replace(
        "      - \"src/App.w\"\n      - \"src/Helper.w\"",
        "      - \"src/Aardvark.w\"\n      - \"src/App.w\"");
    assertEquals(lateRootCoverage, new com.typeobject.wheeler.packageformat.PackageManifestParser()
        .parse(lateRootCoverage).canonicalText());
    VirtualMachine lateRoot = vm(program, lateRootCoverage);
    lateRoot.run();
    assertEquals(2, lateRoot.global("targetSourceCount"));

    String eightTargets = manifestWithTargets(8);
    VirtualMachine larger = vm(program, eightTargets);
    larger.run();
    assertEquals(8, larger.global("targetCount"));
    assertEquals(0, larger.global("targetSourceCount"));
    assertEquals(0, larger.global("dependencyCount"));
    assertEquals(0, larger.global("capabilityCount"));
    assertEquals(6, larger.global("firstTargetNameLength"));
    assertEquals(6, larger.global("lastTargetNameLength"));
    assertEquals(eightTargets, new String(larger.hostOutput(), StandardCharsets.UTF_8));
    new com.typeobject.wheeler.packageformat.PackageManifestParser()
        .parse(larger.hostOutput());
    assertTraps(program, manifestWithTargets(9));
    assertTraps(
        program,
        manifestWithTargets(1).replace("dependencies: []", "dependencies: ["));
    assertTraps(
        program,
        manifestWithTargets(1).replace("capabilities: []", "capabilities: ["));

    assertTraps(program, MANIFEST.replace("schema: 1", "schema: 2"));
    assertTraps(program, MANIFEST.replace("kind: \"tool\"", "kind: \"plugin\""));
    assertTraps(program, MANIFEST.replace("kind: \"tool\"", "kind: \"library\""));
    assertTraps(program, MANIFEST.replace("name: \"tool\"", "name: \"aardvark\""));
    assertTraps(program, MANIFEST.replace("name: \"demo.base\"", "name: \"demo.-base\""));
    assertTraps(program, MANIFEST.replace("name: \"demo.extra\"", "name: \"demo.aaa\""));
    assertTraps(program, MANIFEST.replace("name: \"logs\"", "name: \"fixture\""));
    assertTraps(program, MANIFEST.replace("root: \"src/App.w\"", "root: \"../App.w\""));
    assertTraps(program, MANIFEST.replace("module: \"demo.app\"", "modulx: \"demo.app\""));
    assertTraps(program, MANIFEST.replace("module: \"demo.app\"", "module: \"demo.-app\""));
    assertTraps(program, MANIFEST.replace("sources:", "sourcez:"));
    assertTraps(
        program,
        MANIFEST.replace(
            "    sources:\n      - \"src/App.w\"\n      - \"src/Helper.w\"",
            "    sources: []"));
    assertTraps(program, MANIFEST.replace("test: true", "tests: true"));
    assertTraps(program, MANIFEST.replace("test: true", "test: maybe"));
    assertTraps(program, MANIFEST.replace("dependencies:", "dependencyz:"));
    assertTraps(program, MANIFEST.replace("capabilities:", "capabilityz:"));
    assertTraps(program, MANIFEST.replace("- \"src/Helper.w\"", "- \"../Helper.w\""));
    assertTraps(program, MANIFEST.replace("- \"src/App.w\"", "- \"src/Aardvark.w\""));
    assertTraps(
        program,
        MANIFEST.replace(
            "      - \"src/App.w\"\n      - \"src/Helper.w\"",
            "      - \"src/Helper.w\"\n      - \"src/App.w\""));
  }

  private static String manifestWithTargets(int count) {
    StringBuilder source = new StringBuilder("""
        schema: 1
        package:
          name: "demo.native"
          version: "1.2.3-rc.1"
          profile: "bootstrap-1"
        targets:
        """);
    for (int index = 0; index < count; index++) {
      String suffix = index < 10 ? "0" + index : Integer.toString(index);
      source.append("  - kind: \"tool\"\n")
          .append("    name: \"tool").append(suffix).append("\"\n")
          .append("    root: \"src/Tool").append(suffix).append(".w\"\n")
          .append("    test: false\n");
    }
    return source.append("dependencies: []\ncapabilities: []\n").toString();
  }

  private static void assertTraps(Program program, String input) {
    assertThrows(VmTrap.class, () -> vm(program, input).run());
  }

  private static VirtualMachine vm(Program program, String input) {
    byte[] bytes = input.getBytes(StandardCharsets.UTF_8);
    return new VirtualMachine(program, bytes, bytes.length);
  }
}
