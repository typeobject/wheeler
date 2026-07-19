package com.typeobject.wheeler.examples;

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
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical-YAML workspace manifests. */
class NativeWorkspaceExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesABoundedWorkspace() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "LineEmitter.w", PackageSources.read("packages/manifest/LineEmitter.w"),
            "ManifestTokens.w", PackageSources.read("packages/manifest/ManifestTokens.w"),
            "Names.w", PackageSources.read("packages/workspace/Names.w"),
            "NativeWorkspace.w", Files.readString(root.resolve("NativeWorkspace.w")),
            "Paths.w", PackageSources.read("packages/workspace/Paths.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "Workspace.w", PackageSources.read("packages/workspace/Workspace.w")),
        "examples.packages.workspace_main");
    String canonical = """
        schema: 1
        workspace:
          name: "demo-workspace"
          profile: "bootstrap-1"
        members:
          - name: "app"
            path: "packages/app"
          - name: "base"
            path: "packages/base"
          - name: "compiler"
            path: "packages/compiler"
          - name: "runtime"
            path: "packages/runtime"
          - name: "tools"
            path: "packages/tools"
        """;
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(30, machine.global("nameStart"));
    assertEquals(14, machine.global("nameLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(5, machine.global("memberCount"));
    assertEquals(3, machine.global("firstMemberNameLength"));
    assertEquals(12, machine.global("firstMemberPathLength"));
    assertEquals(4, machine.global("secondMemberNameLength"));
    assertEquals(13, machine.global("secondMemberPathLength"));
    assertEquals(5, machine.global("lastMemberNameLength"));
    assertEquals(14, machine.global("lastMemberPathLength"));
    assertEquals(canonical.length(), machine.global("emittedLength"));
    assertEquals(canonical.length(), machine.global("finalCursor"));
    assertEquals(canonical, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    new WorkspaceManifestParser().parse(machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String sixteenMembers = workspaceWithMembers(16);
    VirtualMachine larger = vm(program, sixteenMembers);
    larger.run();
    assertEquals(16, larger.global("memberCount"));
    assertEquals(8, larger.global("lastMemberNameLength"));
    assertEquals(17, larger.global("lastMemberPathLength"));
    assertEquals(sixteenMembers, new String(larger.hostOutput(), StandardCharsets.UTF_8));
    new WorkspaceManifestParser().parse(larger.hostOutput());
    assertTraps(program, workspaceWithMembers(17));

    assertTraps(program, canonical.replace("schema: 1", "schema: 2"));
    assertTraps(program, canonical.replace("members:", "plugins:"));
    assertTraps(program, canonical.replace("demo-workspace", "Demo"));
    assertTraps(program, canonical.replace("name: \"base\"", "name: \"app\""));
    assertTraps(
        program,
        canonical.replace(
            "  - name: \"app\"\n    path: \"packages/app\"\n"
                + "  - name: \"base\"\n    path: \"packages/base\"",
            "  - name: \"base\"\n    path: \"packages/base\"\n"
                + "  - name: \"app\"\n    path: \"packages/app\""));
    assertTraps(program, canonical.replace("packages/base", "packages/app"));
    assertTraps(program, canonical.replace("packages/base", "packages/app/nested"));
    assertTraps(program, canonical.replace("packages/base", "packages/../base"));
  }

  private static String workspaceWithMembers(int count) {
    StringBuilder source = new StringBuilder("""
        schema: 1
        workspace:
          name: "demo-workspace"
          profile: "bootstrap-1"
        members:
        """);
    for (int index = 0; index < count; index++) {
      String suffix = index < 10 ? "0" + index : Integer.toString(index);
      source.append("  - name: \"member").append(suffix).append("\"\n")
          .append("    path: \"packages/member").append(suffix).append("\"\n");
    }
    return source.toString();
  }

  private static void assertTraps(Program program, String source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
  }

  private static VirtualMachine vm(Program program, String source) {
    byte[] input = source.getBytes(StandardCharsets.UTF_8);
    return new VirtualMachine(program, input, input.length);
  }
}
