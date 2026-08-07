package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.WorkspaceManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native workspace-manifest identities. */
final class NativeWorkspaceIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/packages/identity/NativeWorkspaceIdentity.w");

  @Test
  void validatesBeforePublishingTheCanonicalWorkspaceIdentity() throws Exception {
    Program program = program();
    String canonical = workspace(2);
    byte[] input = canonical.getBytes(StandardCharsets.UTF_8);
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(input);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(
        new WorkspaceManifestParser().parse(canonical).identity(),
        HexFormat.of().formatHex(expected));
    assertEquals(2, machine.global("memberCount"));
    assertEquals(input.length, machine.global("sourceLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertNoIdentity(program, canonical.replace("schema: 1", "schema: 2").getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, workspace(3).getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, new byte[1025]);
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeWorkspaceIdentity.w", Files.readString(FIXTURE),
            "Workspace.w", PackageSources.read("packages/workspace/Workspace.w"),
            "Names.w", PackageSources.read("packages/workspace/Names.w"),
            "Paths.w", PackageSources.read("packages/workspace/Paths.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.packages.workspace_identity");
  }

  private static String workspace(int members) {
    StringBuilder source = new StringBuilder("""
        schema: 1
        workspace:
          name: "demo-workspace"
          profile: "bootstrap-1"
        members:
        """);
    for (int index = 0; index < members; index++) {
      source.append("  - name: \"member0").append(index).append("\"\n")
          .append("    path: \"packages/member0").append(index).append("\"\n");
    }
    return source.toString();
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
