package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Shared constants cannot erase intervening declarations, exports, or privacy checks. */
final class NativeCompilerSharedHelperConstantsExampleTest {
  private static final String BASE = "private const long BASE = 7;\n";
  private static final String TAIL = "private const long TAIL = BASE + 1;\n";
  private static final String GAP = "private const long GAP = 3;\n";
  private static final String ROOT_MODULE = "example.shared_entry";

  private record Sources(String left, String right, String root) {
    Map<String, String> modules() {
      return Map.of("Left.w", left, "Right.w", right, "Entry.w", root);
    }
  }

  @Test
  void preservesPrivateGapsAndPublicTailsAcrossBothFrameOrders() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    Sources ordinary = sources(BASE + GAP + TAIL);
    Sources keywordName = new Sources(
        ordinary.left(), ordinary.right().replace("GAP", "public"), ordinary.root());
    for (Sources source : List.of(
        ordinary, sources(GAP + BASE + TAIL), sources(BASE + TAIL + GAP), keywordName)) {
      byte[] expected = expected(source);
      for (List<String> frames : List.of(
          List.of(source.left(), source.right()), List.of(source.right(), source.left()))) {
        byte[] artifact = NativeModuleCompilerHarness.compile(compiler, frames, source.root());
        assertArrayEquals(expected, artifact, source.right());
        var machine = new VirtualMachine(new BytecodeReader().read(artifact));
        var initial = machine.snapshot();
        machine.run();
        assertEquals(MachineStatus.HALTED, machine.status());
        while (machine.historySize() > 0) {
          machine.rewindOne();
        }
        assertEquals(initial, machine.snapshot());
      }
    }
  }

  @Test
  void rejectsDifferentDeclarationsAndExposedPrivateTailsWithoutPublication() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    Sources valid = sources(BASE + GAP + TAIL);
    for (Sources mismatch : List.of(
        new Sources(valid.left(), valid.right().replace("BASE + 1", "1 + BASE"), valid.root()),
        new Sources(valid.left(), valid.right().replace("BASE = 7", "BASE = 8"), valid.root()),
        new Sources(valid.left().replace(BASE, BASE + "private const boolean FLAG = true;\n"),
            valid.right().replace(BASE, BASE + "private const long FLAG = 1;\n"), valid.root()))) {
      // The bounded native graph requires exact declarations, not equal evaluated values.
      expected(mismatch);
      NativeModuleCompilerHarness.assertTrap(
          compiler, List.of(mismatch.left(), mismatch.right()), mismatch.root());
    }
    Sources exposed = new Sources(valid.left(), valid.right(),
        valid.root().replace("long exported = ANSWER;", "long exported = GAP;"));
    Sources publicConflict = new Sources(valid.left().replace("private const long BASE", "public const long BASE"),
        valid.right().replace("private const long BASE", "public const long BASE"),
        valid.root().replace("long exported = ANSWER;", "long exported = BASE;"));
    for (Sources rejected : List.of(exposed, publicConflict)) {
      assertThrows(CompilerException.class, () -> expected(rejected));
      NativeModuleCompilerHarness.assertTrap(
          compiler, List.of(rejected.left(), rejected.right()), rejected.root());
    }
  }

  @Test
  void rewindsSharedPlanningEmissionAndARejectedTail() throws Exception {
    String imported = "module example.imported; classical class Imported { "
        + "private const long BASE = 7; private const long GAP = 3; "
        + "private const long TAIL = 8; public long helper() { return GAP; } }";
    String root = "module example.root; import example.imported; classical class Root { "
        + "private const long BASE = 7; private const long TAIL = 8; "
        + "entry void main() { long value = helper(); assert(value == 3); } }";
    int insertion = root.indexOf("entry void");
    String expected = root.substring(0, insertion)
        + " private const long GAP = 3;  private long helper() { return GAP; } "
        + root.substring(insertion);
    Program probe = NativeSourceLinkFixture.sharedHelperProgram();
    for (boolean accepted : List.of(true, false)) {
      String source = accepted ? imported : imported.replace("TAIL = 8", "TAIL = 9");
      var writer = NativeModuleCompilerHarness.writer(probe, List.of(source), root);
      var initial = writer.snapshot();
      if (accepted) {
        writer.run();
        assertArrayEquals(expected.getBytes(StandardCharsets.UTF_8), writer.hostOutput());
        assertEquals(1, writer.global("published"));
      } else {
        assertThrows(VmTrap.class, writer::run);
        assertArrayEquals(new byte[32768], writer.hostOutput());
        assertEquals(0, writer.global("published"));
      }
      while (writer.historySize() > 0) {
        writer.rewindOne();
      }
      assertEquals(initial, writer.snapshot());
    }
  }

  @Test
  void preservesQuotedAndCommentedQualificationsAcrossStateInsertionWindows() throws Exception {
    String imported = "module example.imported; classical class Imported { "
        + "private const long BASE = 7; private const long GAP = 3; "
        + "private const long TAIL = 8; public long helper() { return GAP; } }";
    String constants = "private const long BASE = 7; private const long TAIL = 8; ";
    String state = "state long observed = 0; ";
    String body = "entry void main() { region arena = new region(32, 1); "
        + "bytes text = allocateBytes(arena, 32); writeAscii(text, 0, \"example.imported::BASE\");\n"
        + "// example.imported::BASE myexample.imported::BASE\n".repeat(70)
        + "long value = example.imported::helper(); drop(text); drop(arena); assert(value == 3); } }";
    Program probe = NativeSourceLinkFixture.sharedHelperProgram();
    for (boolean stateFirst : List.of(false, true)) {
      String prefix = "module example.root; import example.imported; classical class Root { "
          + (stateFirst ? state + constants : constants + state);
      String root = prefix + body;
      new WheelerCompiler().compileModuleFiles(
          Map.of("Imported.w", imported, "Root.w", root), "example.root");
      int insertion = stateFirst ? prefix.length() : prefix.indexOf("state long");
      String expected = prefix.substring(0, insertion) + " private const long GAP = 3;  "
          + prefix.substring(insertion) + "private long helper() { return GAP; } "
          + body.replace("long value = example.imported::helper();", "long value = helper();");
      var writer = NativeModuleCompilerHarness.writer(probe, List.of(imported), root);
      var initial = writer.snapshot();
      writer.run();
      assertEquals(MachineStatus.HALTED, writer.status());
      assertEquals(1, writer.global("published"));
      assertArrayEquals(expected.getBytes(StandardCharsets.UTF_8), writer.hostOutput());
      while (writer.historySize() > 0) {
        writer.rewindOne();
      }
      assertEquals(initial, writer.snapshot());
    }
  }

  @Test
  void boundsImportedConstantsBeforePublication() throws Exception {
    checkConstantBoundary(true);
  }

  @Test
  void boundsRootConstantsBeforePublication() throws Exception {
    checkConstantBoundary(false);
  }

  private static void checkConstantBoundary(boolean importedBoundary) throws Exception {
    StringBuilder unique = new StringBuilder();
    for (int index = 0; index < 255; index++) {
      unique.append("private const long C").append(index).append(" = ").append(index).append(';');
    }
    String tail = "private const long TAIL = 8;";
    String helper = "public long helper(){return TAIL;} ";
    String entry = "entry void main(){long value=helper();assert(value==8);} }";
    Program probe = NativeSourceLinkFixture.sharedHelperProgram();
    String importedConstants = importedBoundary ? unique + tail : tail;
    String rootConstants = importedBoundary ? tail : unique + tail;
    String imported = "module example.imported;classical class Imported {"
        + importedConstants + helper + "}";
    String rootPrefix = "module example.root;import example.imported;classical class Root {"
        + rootConstants;
    String root = rootPrefix + entry;
    String expected = rootPrefix + (importedBoundary ? unique.toString() : "")
        + "private long helper(){return TAIL;} " + entry;
    var writer = NativeModuleCompilerHarness.writer(probe, List.of(imported), root);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertArrayEquals(expected.getBytes(StandardCharsets.UTF_8), writer.hostOutput());
    String excess = "private const long EXCESS = 0;" + tail;
    String rejectedImport = importedBoundary ? imported.replace(tail, excess) : imported;
    String rejectedRoot = importedBoundary ? root : root.replace(tail, excess);
    var rejected = NativeModuleCompilerHarness.writer(probe, List.of(rejectedImport), rejectedRoot);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(rejected));
    assertArrayEquals(new byte[32768], rejected.hostOutput());
    assertEquals(0, rejected.global("published"));
  }

  private static byte[] expected(Sources source) {
    return new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        source.modules(), ROOT_MODULE));
  }

  private static Sources sources(String declarations) {
    String left = """
        module example.left;
        classical class Left {
          %s
          public long leftValue() { return TAIL; }
        }
        """.formatted(BASE + TAIL);
    String right = """
        module example.right;
        classical class Right {
          %s
          public const long ANSWER = TAIL + GAP;
          public long rightValue() { return ANSWER; }
        }
        """.formatted(declarations);
    String root = """
        module example.shared_entry;
        import example.left;
        import example.right;
        classical class SharedEntry {
          const long ROOT = 5;
          entry void main() {
            long left = leftValue();
            long right = rightValue();
            assert(left == 8);
            assert(right == 11);
            long exported = ANSWER;
            long own = ROOT;
            assert(exported == 11);
            assert(own == 5);
          }
        }
        """;
    return new Sources(left, right, root);
  }
}
