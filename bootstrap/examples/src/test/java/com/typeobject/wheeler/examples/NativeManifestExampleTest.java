package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

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
    Program program = program();
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
    assertEquals(10, machine.global("dependencyCellsWritten"));
    assertEquals(1, machine.global("firstDependencyKind"));
    assertEquals(2, machine.global("lastDependencyKind"));
    assertEquals(-1, machine.global("parseErrorOffset"));
    assertEquals(2, machine.global("capabilityCount"));
    assertEquals(8, machine.global("capabilityCellsWritten"));
    assertEquals(MANIFEST, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    assertTargetTables(machine, MANIFEST);
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

  @Test
  void sourceCollectionsPreserveTargetOffsetsAndAdmittedPrefixes() throws Exception {
    Program program = program();
    String firstTarget = "- kind: \"deployable\"";
    String selectors = "      - \"src/App.w\"\n      - \"src/Helper.w\"";
    assertSourceFailure(program, MANIFEST.replace(selectors, ""), firstTarget, 0, 0);
    assertSourceFailure(program, MANIFEST.replace(selectors, "      - App"), firstTarget, 0, 0);
    assertSourceFailure(program, MANIFEST.replace("- \"src/Helper.w\"", "-"), firstTarget, 1, 0);
    assertSourceFailure(program, MANIFEST.replace("- \"src/Helper.w\"", "- \"../Helper.w\""),
        firstTarget, 1, 0);
    assertSourceFailure(program, MANIFEST.replace("- \"src/Helper.w\"", "- \"src/App.w\""),
        firstTarget, 1, 0);
    assertSourceFailure(program, MANIFEST.replace(selectors,
        "      - \"src/Helper.w\"\n      - \"src/App.w\""), firstTarget, 1, 0);
    assertSourceFailure(program, MANIFEST.replace("- \"src/App.w\"", "- \"src/Aardvark.w\""),
        firstTarget, 2, 0);
    assertSourceFailure(program, MANIFEST.replaceFirst("test: true", "test: maybe"),
        firstTarget, 2, 0);

    String twoCollections = manifestWithTwoSourceCollections();
    VirtualMachine accepted = vm(program, twoCollections);
    accepted.run();
    assertEquals(3, accepted.global("targetSourceCount"));
    assertEquals(6, accepted.global("sourceCellsWritten"));
    assertEquals(twoCollections, new String(accepted.hostOutput(), StandardCharsets.UTF_8));
    assertTargetTables(accepted, twoCollections);
    assertEquals(twoCollections, new com.typeobject.wheeler.packageformat.PackageManifestParser()
        .parse(twoCollections).canonicalText());
    assertSourceFailure(program, twoCollections.replace("- \"a/Tool.w\"", "- \"b/Tool.w\""),
        "- kind: \"tool\"", 3, 9);
    assertSourceFailure(program, twoCollections.replace("      - \"a/Tool.w\"", ""),
        "- kind: \"tool\"", 2, 9);
  }

  @Test
  void targetAdmissionPreservesCapacityFieldAndOrderingPrecedence() throws Exception {
    Program program = program();
    String excess = manifestWithTargets(9)
        .replace("kind: \"tool\"\n    name: \"tool08\"",
            "kind: \"broken\"\n    name: \"tool00\"")
        .replace("root: \"src/Tool08.w\"", "root: \"../bad\"");
    assertSourceFailure(program, excess, "- kind: \"broken\"", 0, 40);

    String disorder = manifestWithTwoSourceCollections()
        .replace("name: \"tool\"", "name: \"app\"");
    assertTargetFailure(program, disorder, disorder.lastIndexOf("\"app\""), 3, 9);
    assertSourceFailure(program, disorder.replace("    test: true\ndependencies:",
        "    test: maybe\ndependencies:"), "- kind: \"tool\"", 3, 9);
    assertSourceFailure(program, disorder.replace("module: \"demo.tool\"",
        "module: \"bad..tool\""), "- kind: \"tool\"", 2, 9);
  }

  @Test
  void sourceCapacityRejectsBeforePublishingTheTarget() throws Exception {
    Program program = program();
    StringBuilder selectors = new StringBuilder();
    for (int index = 0; index < 32; index++) {
      selectors.append("      - \"src/A%02d.w\"\n".formatted(index));
    }
    String full = MANIFEST.replace("root: \"src/App.w\"", "root: \"src/A00.w\"")
        .replace("      - \"src/App.w\"\n      - \"src/Helper.w\"\n", selectors);
    VirtualMachine accepted = vm(program, full);
    accepted.run();
    assertEquals(32, accepted.global("targetSourceCount"));
    assertEquals(64, accepted.global("sourceCellsWritten"));
    assertEquals(full, new String(accepted.hostOutput(), StandardCharsets.UTF_8));
    String excess = full.replaceFirst("    test: true", "      - \"src/A32.w\"\n    test: true");
    assertSourceFailure(program, excess, "- kind: \"deployable\"", 32, 0);
  }

  private static void assertSourceFailure(
      Program program, String source, String target, int selectors, int targetCells) {
    assertTargetFailure(program, source, source.indexOf(target), selectors, targetCells);
  }

  private static void assertTargetFailure(
      Program program, String source, int offset, int selectors, int targetCells) {
    assertTrue(0 <= offset);
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(offset, machine.global("parseErrorOffset"));
    assertEquals(selectors * 2, machine.global("sourceCellsWritten"));
    assertEquals(targetCells, machine.global("targetCellsWritten"));
    assertEquals(0, machine.global("targetSourceCount"));
    assertEquals(0, machine.global("targetCount"));
    assertArrayEquals(new byte[source.getBytes(StandardCharsets.UTF_8).length], machine.hostOutput());
  }

  @Test
  void dependencyAdmissionPreservesKindsAndDiagnosticPrecedence() throws Exception {
    Program program = program();
    String[] kinds = {"normal", "development", "build"};
    for (int index = 0; index < kinds.length; index++) {
      String source = MANIFEST.replace("kind: \"normal\"", "kind: \"" + kinds[index] + "\"");
      VirtualMachine machine = vm(program, source);
      machine.run();
      assertEquals(index + 1, machine.global("firstDependencyKind"));
      assertEquals(2, machine.global("dependencyCount"));
      assertEquals(10, machine.global("dependencyCellsWritten"));
      assertEquals(source, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    }

    String firstRow = "- kind: \"normal\"";
    String secondRow = "- kind: \"development\"";
    assertDependencyFailure(program,
        MANIFEST.replace("kind: \"normal\"", "kind: \"unknown\""),
        "- kind: \"unknown\"", 0);
    assertDependencyFailure(program,
        MANIFEST.replace("demo.base", "demo.-base"), firstRow, 0);
    assertDependencyFailure(program,
        MANIFEST.replace("^1.0.0", "^01.0.0"), firstRow, 0);
    assertDependencyFailure(program,
        MANIFEST.replace("demo.extra", "demo.-extra"), secondRow, 1);
    assertDependencyFailure(program,
        MANIFEST.replace("~2.1.0", "~02.1.0"), secondRow, 1);
    assertDependencyFailure(program,
        MANIFEST.replace(secondRow, "- type: \"development\""),
        "- type: \"development\"", 1);

    String duplicate = MANIFEST.replace("demo.extra", "demo.base");
    String unordered = MANIFEST.replace("demo.extra", "demo.aaa");
    assertDependencyFailure(program, duplicate, "\"demo.base\"", 1);
    assertDependencyFailure(program, unordered, "\"demo.aaa\"", 1);
    assertDependencyFailure(program,
        duplicate.replace("~2.1.0", "~02.1.0"), secondRow, 1);
    assertDependencyFailure(program,
        unordered.replace("~2.1.0", "~02.1.0"), secondRow, 1);
  }

  @Test
  void capabilityAdmissionUsesNameThenPathOrderAfterFieldValidation() throws Exception {
    Program program = program();
    String sameName = MANIFEST.replace("name: \"logs\"", "name: \"fixture\"");
    String orderedPaths = sameName.replace("test-data", "a-data");
    VirtualMachine accepted = vm(program, orderedPaths);
    accepted.run();
    assertEquals(2, accepted.global("capabilityCount"));
    assertEquals(8, accepted.global("capabilityCellsWritten"));
    assertEquals(orderedPaths, new String(accepted.hostOutput(), StandardCharsets.UTF_8));
    assertEquals(orderedPaths, new com.typeobject.wheeler.packageformat.PackageManifestParser()
        .parse(orderedPaths).canonicalText());

    String firstRow = "- name: \"fixture\"";
    String secondRow = "- name: \"logs\"";
    assertCapabilityFailure(program,
        MANIFEST.replace(firstRow, "- namx: \"fixture\""), "- namx: \"fixture\"", 0);
    assertCapabilityFailure(program,
        MANIFEST.replace(firstRow, "- name: fixture"), "- name: fixture", 0);
    assertCapabilityFailure(program,
        MANIFEST.replace(firstRow, "- name: \"\""), "- name: \"\"", 0);
    assertCapabilityFailure(program,
        MANIFEST.replace("path: \"test-data\"", "path: \"../test-data\""), firstRow, 0);
    assertCapabilityFailure(program,
        MANIFEST.replace(secondRow, "- name: \"\""), "- name: \"\"", 1);
    assertCapabilityFailure(program,
        MANIFEST.replace("path: \"logs\"", "path: \"../logs\""), secondRow, 1);
    assertCapabilityFailure(program,
        MANIFEST.replace("path: \"logs\"", "patx: \"logs\""), secondRow, 1);

    assertCapabilityFailure(program, sameName, "\"fixture\"", 1);
    assertCapabilityFailure(program,
        sameName.replace("path: \"logs\"", "path: \"test-data\""), "\"fixture\"", 1);
    String descending = MANIFEST.replace("name: \"logs\"", "name: \"aardvark\"");
    assertCapabilityFailure(program, descending, "\"aardvark\"", 1);
    assertCapabilityFailure(program,
        descending.replace("path: \"logs\"", "path: \"../logs\""),
        "- name: \"aardvark\"", 1);
    assertCapabilityFailure(program,
        sameName.replace("path: \"logs\"", "path: \"../logs\""), firstRow, 1);
  }

  @Test
  void capabilityCapacityRejectsBeforePairOrdering() throws Exception {
    Program program = program();
    StringBuilder source = new StringBuilder(MANIFEST.substring(0, MANIFEST.indexOf("targets:")));
    source.append("""
        targets:
          - kind: "library"
            name: "main"
            root: "src/Main.w"
            test: false
        dependencies: []
        capabilities:
        """);
    for (int row = 0; row < 8; row++) {
      source.append("  - name: \"cap").append(row).append("\"\n    path: \"data\"\n");
    }
    String full = source.toString();
    VirtualMachine accepted = vm(program, full);
    accepted.run();
    assertEquals(8, accepted.global("capabilityCount"));
    assertEquals(32, accepted.global("capabilityCellsWritten"));
    assertEquals(full, new String(accepted.hostOutput(), StandardCharsets.UTF_8));

    String excess = full + "  - name: \"cap7\"\n    path: \"data\"\n";
    assertCapabilityFailure(program, excess, "- name: \"cap7\"", 8);
  }

  private static void assertDependencyFailure(
      Program program, String source, String diagnosticToken, int admittedRows) {
    assertRowFailure(program, source, diagnosticToken, "dependency", admittedRows * 5);
  }

  private static void assertCapabilityFailure(
      Program program, String source, String diagnosticToken, int admittedRows) {
    assertRowFailure(program, source, diagnosticToken, "capability", admittedRows * 4);
  }

  private static void assertRowFailure(
      Program program, String source, String diagnosticToken, String collection, int writtenCells) {
    int offset = source.lastIndexOf(diagnosticToken);
    assertTrue(0 <= offset, "diagnostic token must occur in the fixture");
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertEquals(offset, machine.global("parseErrorOffset"));
    assertEquals(writtenCells, machine.global(collection + "CellsWritten"));
    assertEquals(0, machine.global(collection + "Count"));
    assertArrayEquals(new byte[source.getBytes(StandardCharsets.UTF_8).length], machine.hostOutput());
  }

  private static void assertTargetTables(VirtualMachine machine, String source) {
    // Rewind only cleanup so the fixture's published tables remain inspectable.
    int region = machine.snapshot().regions().stream()
        .filter(row -> row.maxBytes() == 15360 && row.maxObjects() == 7)
        .findFirst().orElseThrow().id();
    while (machine.snapshot().buffers().stream()
        .anyMatch(row -> row.regionId() == region
            && (row.length() == 80 || row.length() == 64) && row.dropped())) {
      machine.rewindOne();
    }
    var model = new com.typeobject.wheeler.packageformat.PackageManifestParser().parse(source);
    long[] targets = new long[80];
    long[] sources = new long[64];
    int cursor = 0;
    int row = 0;
    int sourceCount = 0;
    for (var target : model.targets()) {
      cursor = source.indexOf("  - kind:", cursor);
      assertTrue(0 <= cursor);
      int base = row++ * 10;
      targets[base] = switch (target.kind().keyword()) {
        case "deployable" -> 1;
        case "library" -> 2;
        case "tool" -> 3;
        default -> throw new AssertionError("unknown target kind");
      };
      targets[base + 1] = fieldStart(source, cursor, "name");
      targets[base + 2] = target.name().length();
      targets[base + 3] = fieldStart(source, cursor, "root");
      targets[base + 4] = target.root().length();
      targets[base + 7] = sourceCount;
      targets[base + 9] = target.test() ? 1 : 0;
      if (target.module() != null) {
        targets[base + 5] = fieldStart(source, cursor, "module");
        targets[base + 6] = target.module().length();
        targets[base + 8] = target.sources().size();
        for (String selector : target.sources()) {
          int start = source.indexOf("- \"" + selector + "\"", cursor);
          assertTrue(0 <= start);
          sources[sourceCount * 2] = SourceRanges.utf8Offset(source, start + 3);
          sources[sourceCount * 2 + 1] = selector.length();
          sourceCount++;
        }
      }
      cursor++;
    }
    for (long[] expected : new long[][] {targets, sources}) {
      var actual = machine.snapshot().buffers().stream()
          .filter(buffer -> buffer.regionId() == region && buffer.length() == expected.length)
          .findFirst().orElseThrow().elements().stream().mapToLong(Long::longValue).toArray();
      assertArrayEquals(expected, actual);
    }
  }

  private static int fieldStart(String source, int cursor, String key) {
    int start = source.indexOf(key + ": \"", cursor);
    assertTrue(0 <= start);
    return SourceRanges.utf8Offset(source, start + key.length() + 3);
  }

  private static String manifestWithTwoSourceCollections() {
    return MANIFEST.replace("    root: \"src/Tool.w\"",
        "    root: \"a/Tool.w\"\n    module: \"demo.tool\"\n"
            + "    sources:\n      - \"a/Tool.w\"");
  }

  private static Program program() throws Exception {
    Path root = Path.of("../wheeler-conformance/src/main/wheeler/packages");
    Map<String, String> modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.packages.manifest"));
    modules.put(
        "ManifestEmitter.w", PackageSources.read("packages/manifest/ManifestEmitter.w"));
    modules.put("NativeManifest.w", Files.readString(root.resolve("NativeManifest.w")));
    modules.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    return new WheelerCompiler().compileModuleFiles(modules, "wheeler.conformance.packages.main");
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
