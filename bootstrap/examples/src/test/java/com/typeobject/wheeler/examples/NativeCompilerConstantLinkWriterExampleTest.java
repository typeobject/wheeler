package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Constant emission changes declaration visibility, never identifier spelling. */
final class NativeCompilerConstantLinkWriterExampleTest {
  @Test
  void preservesVisibilityNamesAndReleasesBothWriterScratchProfilesBeforePublication() throws Exception {
    String declarations = "public const long public = 42; public const long ANSWER = public; ";
    String imported = "module example.imported; classical class Imported { " + declarations + "}";
    String root = "module example.root; import example.imported; classical class Root { "
        + "state long value = example.imported::ANSWER; entry void main() { assert(value == 42); } }";
    new WheelerCompiler().compileModuleFiles(Map.of("Imported.w", imported, "Root.w", root), "example.root");
    int insertion = root.indexOf("entry void");
    for (boolean privateExports : List.of(false, true)) {
      var writer = NativeModuleCompilerHarness.writer(NativeSourceLinkFixture.constantProgram(privateExports),
          List.of(imported), root);
      var initial = writer.snapshot();
      runToPhase(writer, 1);
      var planned = writer.snapshot();
      assertEquals(0, writer.global("published"));
      assertArrayEquals(new byte[32_768], writer.hostOutput());
      runToPhase(writer, 2);
      var copied = writer.snapshot();
      assertEquals(0, writer.global("published"));
      assertArrayEquals(new byte[32_768], writer.hostOutput());
      assertEquals(planned.buffers().size() + (privateExports ? 6 : 3), copied.buffers().size());
      assertEquals(planned.regions().size() + (privateExports ? 2 : 1), copied.regions().size());
      assertEquals(liveBuffers(planned), liveBuffers(copied));
      assertEquals(liveRegions(planned), liveRegions(copied));
      writer.run();
      assertEquals(MachineStatus.HALTED, writer.status());
      assertEquals(1, writer.global("published"));
      String inserted = privateExports
          ? "private const long public = 42; private const long ANSWER = public; " : declarations;
      String expected = root.substring(0, insertion).replace("example.imported::ANSWER", "ANSWER")
          + inserted + root.substring(insertion);
      assertArrayEquals(expected.getBytes(StandardCharsets.UTF_8), writer.hostOutput());
      while (writer.historySize() > 0) {
        writer.rewindOne();
      }
      assertEquals(initial, writer.snapshot());
    }
  }

  private static void runToPhase(VirtualMachine machine, long phase) {
    for (int step = 0; step < 1_000_000 && machine.global("phase") != phase; step++) {
      machine.step();
    }
    assertEquals(phase, machine.global("phase"));
  }

  private static List<Integer> liveBuffers(MachineSnapshot snapshot) {
    return snapshot.buffers().stream().filter(buffer -> !buffer.dropped()).map(BufferValue::id).toList();
  }

  private static List<RegionValue> liveRegions(MachineSnapshot snapshot) {
    return snapshot.regions().stream().filter(region -> !region.dropped()).toList();
  }
}
