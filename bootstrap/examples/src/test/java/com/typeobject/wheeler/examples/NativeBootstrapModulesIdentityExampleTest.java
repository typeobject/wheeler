package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest.Module;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for the bounded Wheeler-native bootstrap module closure. */
final class NativeBootstrapModulesIdentityExampleTest {
  private static final Path ROOT = Path.of("src/main/wheeler/native/bootstrap");
  private static final String IDENTITY = "ab".repeat(32);

  @Test
  void validatesOneRootedModuleAndItsExternalImports() throws Exception {
    Program program = program();
    BootstrapModuleManifest empty = new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of(),
        List.of(new Module(
            "wheeler.compiler", "src/main/wheeler/Compiler.w", IDENTITY, List.of())));
    assertIdentity(program, empty, 0, 0, true);

    BootstrapModuleManifest imported = new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of("wheeler.core", "wheeler.runtime"),
        List.of(new Module(
            "wheeler.compiler",
            "src/main/wheeler/Compiler.w",
            IDENTITY,
            List.of("wheeler.core", "wheeler.runtime"))));
    assertIdentity(program, imported, 2, 2, false);

    String text = imported.canonicalText();
    assertNoIdentity(program, new byte[2_049]);
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

  private static void assertIdentity(
      Program program,
      BootstrapModuleManifest manifest,
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
    assertEquals(1, machine.global("moduleCount"));
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
