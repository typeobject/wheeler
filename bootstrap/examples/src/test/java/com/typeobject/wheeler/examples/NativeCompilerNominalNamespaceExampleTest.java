package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Exact borrowed-window and rewind evidence for the existing generated namespace policy. */
final class NativeCompilerNominalNamespaceExampleTest {
  private static Program program;

  @Test
  void checksOnlyTheRetainedUtf8ByteWindowAndRewinds() throws Exception {
    String prefix = "WheelerNominal // λ 🐍\n";
    String body = "classical class Root { long WheelerNomina() { return 7; } }";
    String suffix = "__wheeler_nominal_";
    check(prefix + body + suffix, 16 + prefix.getBytes(StandardCharsets.UTF_8).length,
        body.length(), true);
    check("__wheeler_nominal", 16, 17, true);
  }

  @Test
  void rejectsEitherCompleteMarkerAtAnyPositionWithoutChangingCallerStorage() throws Exception {
    for (String marker : new String[] {"WheelerNominal", "__wheeler_nominal_"}) {
      for (String prefix : new String[] {"", "other", "// λ "}) {
        String source = prefix + marker;
        check(source, 16, source.getBytes(StandardCharsets.UTF_8).length, false);
      }
    }
  }

  @Test
  void boundsTheWholeSourceWindowBeforeScanningAndPreservesRewind() throws Exception {
    String source = " ".repeat(32769);
    check(source, 16, 32768, true);
    check(source, 16, 32769, false);
    for (long[] range : new long[][] {
        {-1, 1}, {Long.MAX_VALUE, 1}, {16, -1}, {16, 0}, {16, Long.MAX_VALUE},
        {32785, 1}, {32784, 2}}) {
      check(source, range[0], range[1], false);
    }
    check(source, 32784, 1, true);
  }

  private static void check(String source, long start, long length, boolean accepted)
      throws Exception {
    byte[] text = source.getBytes(StandardCharsets.UTF_8);
    byte[] input = ByteBuffer.allocate(16 + text.length).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(start).putLong(length).put(text).array();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 64);
    var initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    var prepared = machine.snapshot();
    byte[] output = machine.hostOutput();
    if (accepted) { machine.run(); }
    else { assertThrows(VmTrap.class, machine::run); }
    assertEquals(accepted ? 1 : 0, machine.global("published"));
    assertArrayEquals(output, machine.hostOutput());
    assertEquals(prepared.buffers(), machine.snapshot().buffers());
    assertEquals(prepared.regions(), machine.snapshot().regions());
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static synchronized Program program() throws Exception {
    if (program != null) { return program; }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_stubs"));
    CoreSources.addBinaryClosure(sources);
    sources.put("NominalNamespace.w", """
        module example.nominal_namespace;
        import wheeler.compiler.closure.imported_nominal_stubs;
        import wheeler.core.encoding.binary;

        classical class NominalNamespace {
          state long prepared = 0;
          state long published = 0;
          entry void main(borrow byteview input, borrow mut bytes output) {
            long byte = 0;
            while (byte < 64) limit 64 {
              setByte(output, byte, byte + 1);
              byte += 1;
            }
            prepared = 1;
            requireImportedNominalNamespace(input, readSigned(input, 0), readSigned(input, 8));
            published = 1;
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(sources, "example.nominal_namespace");
    return program;
  }
}
