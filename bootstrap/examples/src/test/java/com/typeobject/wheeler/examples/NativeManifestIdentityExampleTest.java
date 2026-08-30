package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native package-manifest identities. */
final class NativeManifestIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/packages/identity/NativeManifestIdentity.w");
  private static final String MANIFEST = """
      schema: 1
      package:
        name: "demo.identity"
        version: "1.0.0"
        profile: "bootstrap-1"
      targets:
        - kind: "tool"
          name: "main"
          root: "src/Main.w"
          test: false
      dependencies: []
      capabilities: []
      """;

  @Test
  void validatesBeforePublishingTheCanonicalManifestIdentity() throws Exception {
    Program program = program();
    byte[] input = MANIFEST.getBytes(StandardCharsets.UTF_8);
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(input);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(
        new PackageManifestParser().parse(MANIFEST).identity(),
        HexFormat.of().formatHex(expected));
    assertEquals(1, machine.global("targetCount"));
    assertEquals(0, machine.global("sourceCount"));
    assertEquals(0, machine.global("dependencyCount"));
    assertEquals(0, machine.global("capabilityCount"));
    assertEquals(input.length, machine.global("sourceLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertNoIdentity(program, MANIFEST.replace("schema: 1", "schema: 2").getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("dependencies: []", "dependencies:")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("dependencies: []", "dependencies: [")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("dependencies: []", "dependencies: ]")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("capabilities: []", "capabilities:")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("capabilities: []", "capabilities: [")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(
        program,
        MANIFEST.replace("capabilities: []", "capabilities: ]")
            .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, twoTargets().getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, new byte[1025]);
  }

  private static Program program() throws Exception {
    Map<String, String> modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.packages.manifest"));
    modules.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
    modules.put("NativeManifestIdentity.w", Files.readString(FIXTURE));
    modules.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.packages.manifest_identity");
  }

  private static String twoTargets() {
    return MANIFEST.replace(
        "dependencies: []",
        """
          - kind: "tool"
            name: "tool"
            root: "src/Tool.w"
            test: false
        dependencies: []""");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
  }
}
