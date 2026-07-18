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

class NativeWorkspaceExampleTest {
  @Test
  void wheelerParsesAndCanonicalizesABoundedWorkspace() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "LineEmitter.w", Files.readString(root.resolve("packages/LineEmitter.w")),
            "ManifestTokens.w", Files.readString(root.resolve("packages/ManifestTokens.w")),
            "Names.w", Files.readString(root.resolve("packages/Names.w")),
            "NativeWorkspace.w", Files.readString(root.resolve("NativeWorkspace.w")),
            "Paths.w", Files.readString(root.resolve("packages/Paths.w")),
            "Scanner.w", Files.readString(root.resolve("lexer/Scanner.w")),
            "Workspace.w", Files.readString(root.resolve("packages/Workspace.w"))),
        "examples.packages.workspace_main");
    String canonical =
        "workspace \"demo-workspace\" profile \"bootstrap-1\";\n"
            + "member \"app\" path \"packages/app\";\n"
            + "member \"base\" path \"packages/base\";\n";
    String input = canonical.replace("\n", "\n   ");
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(11, machine.global("nameStart"));
    assertEquals(14, machine.global("nameLength"));
    assertEquals(11, machine.global("profileLength"));
    assertEquals(2, machine.global("memberCount"));
    assertEquals(3, machine.global("firstMemberNameLength"));
    assertEquals(12, machine.global("firstMemberPathLength"));
    assertEquals(4, machine.global("secondMemberNameLength"));
    assertEquals(13, machine.global("secondMemberPathLength"));
    assertEquals(canonical.length(), machine.global("emittedLength"));
    assertEquals(input.length(), machine.global("finalCursor"));
    assertEquals(canonical, new String(machine.hostOutput(), StandardCharsets.UTF_8));
    new WorkspaceManifestParser().parse(machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertTraps(program, canonical.replace("demo-workspace", "Demo"));
    assertTraps(program, canonical.replace("\"base\" path", "\"app\" path"));
    assertTraps(
        program,
        canonical.replace(
            "member \"app\" path \"packages/app\";\n"
                + "member \"base\" path \"packages/base\";",
            "member \"base\" path \"packages/base\";\n"
                + "member \"app\" path \"packages/app\";"));
    assertTraps(program, canonical.replace("packages/base", "packages/app"));
    assertTraps(program, canonical.replace("packages/base", "packages/app/nested"));
    assertTraps(program, canonical.replace("packages/base", "packages/../base"));
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
