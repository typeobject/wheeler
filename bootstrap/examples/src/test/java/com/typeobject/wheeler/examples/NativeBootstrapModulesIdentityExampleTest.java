package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest.Module;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for the bounded Wheeler-native bootstrap module closure. */
final class NativeBootstrapModulesIdentityExampleTest {
  private static final Path ROOT = Path.of("../wheeler-conformance/src/main/wheeler/bootstrap");
  private static final String IDENTITY = "ab".repeat(32);
  private static final int DENSE_GRAPH_ROOT_EDGE_ADJUSTMENT = 63;
  private static final int DENSE_GRAPH_IMPORTS_PER_MODULE = 64;
  private static final long MAX_CLOSURE_TRANSITIONS = 76_000_000;
  private static final long MAX_LARGE_GRAPH_TRANSITIONS = 80_000_000;

  @Test
  void validatesThePhysicalBoundedCompilerClosure() throws Exception {
    BootstrapModuleManifest manifest = CompilerSources.bootstrapModuleManifest();

    assertEquals(180_888, manifest.canonicalBytes().length);
    VirtualMachine machine = vm(program(), manifest.canonicalBytes());
    long transitions = 0;
    while (machine.status() != MachineStatus.HALTED
        && transitions < MAX_CLOSURE_TRANSITIONS) {
      machine.stepWithoutRewindHistory();
      transitions += 1;
    }

    assertEquals(75_439_422, transitions);
    assertEquals(MachineStatus.HALTED, machine.status());
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(manifest.canonicalBytes()),
        machine.hostOutput());
    assertEquals(385, machine.global("moduleCount"));
    assertEquals(2, machine.global("externalCount"));
    assertEquals(1_921, machine.global("importCount"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void pinsTheNativeImportCapacityGuard() throws Exception {
    String source = CompilerSources.read("compiler/closure/ModuleManifest.w");

    assertTrue(source.contains("private const long MAX_LOCAL_MODULES = 512;"));
    assertTrue(source.contains("requireMetadata(parsedModules < MAX_LOCAL_MODULES);"));
    assertTrue(source.contains("private const long MAX_IMPORTS = 3072;"));
    assertTrue(source.contains("requireMetadata(parsedImports < MAX_IMPORTS);"));
    assertTrue(source.contains("private const long MAX_MANIFEST_BYTES = 262144;"));
    assertTrue(source.contains(
        "requireMetadata(bufferLength(source) < MAX_MANIFEST_BYTES + 1);"));
  }

  @Test
  void validatesOneRootedModuleAndItsExternalImports() throws Exception {
    Program program = program();
    BootstrapModuleManifest empty = new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of(),
        List.of(new Module(
            "wheeler.compiler", "src/main/wheeler/Compiler.w", IDENTITY, List.of())));
    assertIdentity(program, empty, 1, 0, 0, true);

    BootstrapModuleManifest imported = new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of("wheeler.core", "wheeler.runtime"),
        List.of(new Module(
            "wheeler.compiler",
            "src/main/wheeler/Compiler.w",
            IDENTITY,
            List.of("wheeler.core", "wheeler.runtime"))));
    assertIdentity(program, imported, 1, 2, 2, false);

    BootstrapModuleManifest graph = new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of("wheeler.core"),
        List.of(
            new Module(
                "wheeler.compiler",
                "src/main/wheeler/Compiler.w",
                "01".repeat(32),
                List.of("wheeler.compiler.backend", "wheeler.core")),
            new Module(
                "wheeler.compiler.backend",
                "src/main/wheeler/Backend.w",
                "02".repeat(32),
                List.of("wheeler.compiler.tokens")),
            new Module(
                "wheeler.compiler.tokens",
                "src/main/wheeler/Tokens.w",
                "03".repeat(32),
                List.of())));
    assertIdentity(program, graph, 3, 1, 3, false);
    String graphText = graph.canonicalText();
    assertNoIdentity(program, graphText.replace(
        "    imports: []\n",
        "    imports:\n      - \"wheeler.compiler\"\n")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, graphText.replace(
        "      - \"wheeler.compiler.backend\"\n", "")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, graphText.replace("Tokens.w", "Backend.w")
        .getBytes(StandardCharsets.UTF_8));
    BootstrapModuleManifest fiveModules = new BootstrapModuleManifest(
        "bootstrap-1",
        "bootstrap.m0",
        List.of(),
        List.of(
            new Module(
                "bootstrap.m0", "src/M0.w", "10".repeat(32),
                List.of("bootstrap.m1", "bootstrap.m2", "bootstrap.m3", "bootstrap.m4")),
            new Module("bootstrap.m1", "src/M1.w", "11".repeat(32), List.of()),
            new Module("bootstrap.m2", "src/M2.w", "12".repeat(32), List.of()),
            new Module("bootstrap.m3", "src/M3.w", "13".repeat(32), List.of()),
            new Module("bootstrap.m4", "src/M4.w", "14".repeat(32), List.of())));
    assertIdentity(program, fiveModules, 5, 0, 4, false);
    BootstrapModuleManifest nineModules = generatedGraph(9);
    assertIdentity(program, nineModules, 9, 0, 8, false);
    BootstrapModuleManifest seventeenModules = generatedGraph(17);
    assertIdentity(program, seventeenModules, 17, 0, 16, false);
    BootstrapModuleManifest thirtyThreeModules = generatedGraph(33);
    assertLargeIdentity(program, thirtyThreeModules, 33, 0, 32);
    BootstrapModuleManifest sixtyFourModules = generatedGraph(64);
    assertLargeIdentity(program, sixtyFourModules, 64, 0, 63);
    BootstrapModuleManifest sixtyFiveModules = generatedGraph(65);
    assertLargeIdentity(program, sixtyFiveModules, 65, 0, 64);
    BootstrapModuleManifest excessModuleImports = generatedGraph(66);
    assertLargeNoIdentity(program, excessModuleImports.canonicalBytes());
    BootstrapModuleManifest oneHundredTwentyEightModules = generatedChainGraph(128);
    assertLargeIdentity(program, oneHundredTwentyEightModules, 128, 0, 127);
    BootstrapModuleManifest twoHundredFiftySixModules = generatedChainGraph(256);
    assertLargeIdentity(program, twoHundredFiftySixModules, 256, 0, 255);
    BootstrapModuleManifest twoHundredFiftySevenModules = generatedChainGraph(257);
    assertLargeIdentity(program, twoHundredFiftySevenModules, 257, 0, 256);
    BootstrapModuleManifest fiveHundredTwelveImports = generatedDenseGraph(512);
    assertLargeIdentity(program, fiveHundredTwelveImports, 9, 64, 512);
    BootstrapModuleManifest fiveHundredSeventySixImports = generatedDenseGraph(576);
    assertLargeIdentity(program, fiveHundredSeventySixImports, 10, 64, 576);
    BootstrapModuleManifest sevenHundredSixtyEightImports = generatedDenseGraph(768);
    assertLargeIdentity(program, sevenHundredSixtyEightImports, 13, 64, 768);
    BootstrapModuleManifest sixtyFourExternals = generatedExternalGraph(64);
    assertLargeIdentity(program, sixtyFourExternals, 1, 64, 0);
    BootstrapModuleManifest sixtyFiveExternals = generatedExternalGraph(65);
    assertLargeNoIdentity(program, sixtyFiveExternals.canonicalBytes());

    String text = imported.canonicalText();
    assertNoIdentity(program, new byte[262_145]);
    assertNoIdentity(program, text.replace(
        "  - \"wheeler.core\"\n  - \"wheeler.runtime\"",
        "  - \"wheeler.runtime\"\n  - \"wheeler.core\"")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("      - \"wheeler.core\"", "      - \"other.core\"")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("root: \"wheeler.compiler\"", "root: \"other.compiler\"")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace(IDENTITY, IDENTITY.toUpperCase())
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("Compiler.w", "../Compiler.w")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static void assertLargeIdentity(
      Program program,
      BootstrapModuleManifest manifest,
      int modules,
      int externals,
      int imports
  ) throws Exception {
    byte[] canonical = manifest.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    long transitions = 0;
    while (machine.status() != MachineStatus.HALTED
        && transitions < MAX_LARGE_GRAPH_TRANSITIONS) {
      machine.stepWithoutRewindHistory();
      transitions += 1;
    }

    assertEquals(MachineStatus.HALTED, machine.status());
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical),
        machine.hostOutput());
    assertEquals(modules, machine.global("moduleCount"));
    assertEquals(externals, machine.global("externalCount"));
    assertEquals(imports, machine.global("importCount"));
    assertEquals(1, machine.global("published"));
  }

  private static void assertLargeNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    long transitions = 0;
    while (machine.status() != MachineStatus.HALTED
        && machine.status() != MachineStatus.TRAPPED
        && transitions < MAX_LARGE_GRAPH_TRANSITIONS) {
      try {
        machine.stepWithoutRewindHistory();
      } catch (VmTrap expected) {
        // The first rejected transition sets the fail-closed machine state.
      }
      transitions += 1;
    }

    assertEquals(MachineStatus.TRAPPED, machine.status());
    assertArrayEquals(new byte[32], machine.hostOutput());
    assertEquals(0, machine.global("published"));
  }

  private static BootstrapModuleManifest generatedDenseGraph(int edgeLimit) {
    List<String> externals = new ArrayList<>();
    for (int external = 0; external < 64; external++) {
      externals.add("e.x%02d".formatted(external));
    }

    List<Module> rows = new ArrayList<>();
    List<String> rootImports = new ArrayList<>();
    int moduleCount = Math.ceilDiv(
        edgeLimit + DENSE_GRAPH_ROOT_EDGE_ADJUSTMENT,
        DENSE_GRAPH_IMPORTS_PER_MODULE);
    for (int module = 1; module < moduleCount; module++) {
      rootImports.add("b.m%02d".formatted(module));
    }
    rows.add(new Module("b.m00", "s/M00.w", "20".repeat(32), rootImports));

    int edges = rootImports.size();
    for (int owner = 1; owner < moduleCount; owner++) {
      List<String> imports = new ArrayList<>();
      int ownerLimit = owner + 1 == moduleCount ? 64 : 63;
      for (int external = 0; external < ownerLimit && edges < edgeLimit; external++) {
        imports.add("e.x%02d".formatted(external));
        edges += 1;
      }
      rows.add(new Module(
          "b.m%02d".formatted(owner),
          "s/M%02d.w".formatted(owner),
          "%02x".formatted(32 + owner).repeat(32),
          imports));
    }
    return new BootstrapModuleManifest("bootstrap-1", "b.m00", externals, rows);
  }

  private static BootstrapModuleManifest generatedExternalGraph(int count) {
    List<String> externals = new ArrayList<>();
    for (int index = 0; index < count; index++) {
      externals.add("external.m%02d".formatted(index));
    }
    return new BootstrapModuleManifest(
        "bootstrap-1",
        "bootstrap.root",
        externals,
        List.of(new Module(
            "bootstrap.root", "src/Root.w", IDENTITY, List.of())));
  }

  private static BootstrapModuleManifest generatedChainGraph(int count) {
    List<Module> rows = new ArrayList<>();
    for (int index = 0; index < count; index++) {
      List<String> imports = index + 1 < count
          ? List.of("bootstrap.m" + (index + 1))
          : List.of();
      rows.add(new Module(
          "bootstrap.m" + index,
          "src/M" + index + ".w",
          "%02x".formatted(32 + index % 224).repeat(32),
          imports));
    }
    return new BootstrapModuleManifest(
        "bootstrap-1", "bootstrap.m0", List.of(), rows);
  }

  private static BootstrapModuleManifest generatedGraph(int count) {
    List<String> rootImports = new ArrayList<>();
    List<Module> rows = new ArrayList<>();
    for (int index = 1; index < count; index++) {
      rootImports.add("bootstrap.m" + index);
    }
    for (int index = 0; index < count; index++) {
      rows.add(new Module(
          "bootstrap.m" + index,
          "src/M" + index + ".w",
          "%02x".formatted(32 + index).repeat(32),
          index == 0 ? rootImports : List.of()));
    }
    return new BootstrapModuleManifest(
        "bootstrap-1", "bootstrap.m0", List.of(), rows);
  }

  private static void assertIdentity(
      Program program,
      BootstrapModuleManifest manifest,
      int modules,
      int externals,
      int imports,
      boolean rewind
  ) throws Exception {
    byte[] canonical = manifest.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical),
        machine.hostOutput());
    assertEquals(modules, machine.global("moduleCount"));
    assertEquals(externals, machine.global("externalCount"));
    assertEquals(imports, machine.global("importCount"));
    assertEquals(1, machine.global("published"));
    if (rewind) {
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.module_manifest"));
    sources.put(
        "NativeBootstrapModulesIdentity.w",
        Files.readString(ROOT.resolve("NativeBootstrapModulesIdentity.w")));
    sources.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    return new WheelerCompiler().compileModuleFiles(
        sources,
        "wheeler.conformance.bootstrap.modules_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
    assertEquals(0, machine.global("published"));
  }
}
