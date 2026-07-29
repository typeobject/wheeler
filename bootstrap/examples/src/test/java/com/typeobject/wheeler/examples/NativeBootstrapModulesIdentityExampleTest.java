package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

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
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for the bounded Wheeler-native bootstrap module closure. */
final class NativeBootstrapModulesIdentityExampleTest {
  private static final Path ROOT = Path.of("src/main/wheeler/native/bootstrap");
  private static final String IDENTITY = "ab".repeat(32);
  private static final long MAX_CLOSURE_TRANSITIONS = 6_000_000;
  private static final long MAX_LARGE_GRAPH_TRANSITIONS = 50_000_000;

  @Test
  void validatesThePhysicalBoundedCompilerClosure() throws Exception {
    BootstrapModuleManifest manifest = CompilerSources.bootstrapModuleManifest();

    assertEquals(10_154, manifest.canonicalBytes().length);
    VirtualMachine machine = vm(program(), manifest.canonicalBytes());
    long transitions = 0;
    while (machine.status() != MachineStatus.HALTED
        && transitions < MAX_CLOSURE_TRANSITIONS) {
      machine.step();
      transitions += 1;
      if (10_000 <= machine.historySize()) {
        machine.commitHistory();
      }
    }

    assertEquals(5_676_823, transitions);
    assertEquals(MachineStatus.HALTED, machine.status());
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(manifest.canonicalBytes()),
        machine.hostOutput());
    assertEquals(31, machine.global("moduleCount"));
    assertEquals(1, machine.global("externalCount"));
    assertEquals(105, machine.global("importCount"));
    assertEquals(1, machine.global("published"));
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
    assertLargeNoIdentity(program, sixtyFiveModules.canonicalBytes());
    BootstrapModuleManifest sixtyFourExternals = generatedExternalGraph(64);
    assertLargeIdentity(program, sixtyFourExternals, 1, 64, 0);
    BootstrapModuleManifest sixtyFiveExternals = generatedExternalGraph(65);
    assertLargeNoIdentity(program, sixtyFiveExternals.canonicalBytes());

    String text = imported.canonicalText();
    assertNoIdentity(program, new byte[32_769]);
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
      machine.step();
      transitions += 1;
      if (10_000 <= machine.historySize()) {
        machine.commitHistory();
      }
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
        machine.step();
      } catch (VmTrap expected) {
        // The first rejected transition sets the fail-closed machine state.
      }
      transitions += 1;
      if (10_000 <= machine.historySize()) {
        machine.commitHistory();
      }
    }

    assertEquals(MachineStatus.TRAPPED, machine.status());
    assertArrayEquals(new byte[32], machine.hostOutput());
    assertEquals(0, machine.global("published"));
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
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeBootstrapModulesIdentity.w",
            Files.readString(ROOT.resolve("NativeBootstrapModulesIdentity.w")),
            "BootstrapSyntax.w", Files.readString(ROOT.resolve("BootstrapSyntax.w")),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "examples.bootstrap.modules_identity");
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
