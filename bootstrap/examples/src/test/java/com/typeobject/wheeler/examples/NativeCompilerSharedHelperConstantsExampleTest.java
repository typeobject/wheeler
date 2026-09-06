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
import java.util.LinkedHashMap;
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
    Program probe = sharedLinkProbe();
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
    Program probe = sharedLinkProbe();
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

  private static Program sharedLinkProbe() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.imported_helpers"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.canonical_helper_linking"));
    CoreSources.addBinaryClosure(modules);
    modules.put("SharedLinkProbe.w", """
        module example.shared_link_probe;
        import wheeler.compiler.canonical_helper_linking;
        import wheeler.compiler.imported_helpers;
        import wheeler.compiler.module_linker;
        import wheeler.core.encoding.binary;
        classical class SharedLinkProbe {
          state long published = 0;
          private void copyWindow(borrow byteview input, long start, borrow mut bytes output) {
            long index = 0;
            while (index < bufferLength(output)) limit 32768 {
              setByte(output, index, input[start + index]);
              index += 1;
            }
          }
          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(readUnsigned(input, 0, 4) == 1);
            long importedLength = readUnsigned(input, 4, 4);
            long rootStart = 8 + importedLength;
            long rootLength = bufferLength(input) - rootStart;
            assert(0 < importedLength);
            assert(importedLength < 32769);
            assert(0 < rootLength);
            assert(rootLength < 32769);
            region sources = new region(/* bytes= */ 65536, /* allocations= */ 2);
            bytes importedBytes = allocateBytes(sources, importedLength);
            bytes rootBytes = allocateBytes(sources, rootLength);
            copyWindow(input, 8, importedBytes);
            copyWindow(input, rootStart, rootBytes);
            utf8 imported = freezeUtf8(importedBytes);
            utf8 root = freezeUtf8(rootBytes);
            LinkPlan plan = planSharedResolvedHelperImport(imported, root, 1);
            assert(plan.valid);
            region emission = new region(/* bytes= */ 36864, /* allocations= */ 1);
            bytes linked = allocateBytes(emission, plan.linkedLength);
            long written = writeCanonicalHelperImport(imported, root, plan, linked);
            assert(written == plan.linkedLength);
            long index = 0;
            while (index < written) limit 36864 {
              setByte(output, index, linked[index]);
              index += 1;
            }
            setOutputLength(output, written);
            published = 1;
            drop(linked);
            drop(emission);
            drop(root);
            drop(imported);
            drop(sources);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(modules, "example.shared_link_probe");
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
