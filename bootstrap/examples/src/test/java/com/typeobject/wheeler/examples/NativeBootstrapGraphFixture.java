package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifestParser;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;

/** Checks graph admission, complete caller buffers, and explicitly retained or discarded history. */
final class NativeBootstrapGraphFixture {
  private static final long MAX_LARGE_GRAPH_TRANSITIONS = 80_000_000;
  private static final int OUTPUT_BYTES = 40;
  private static Program cached;

  record Run(long transitions, long graphTransitions) {}

  private NativeBootstrapGraphFixture() {}

  static synchronized Program program() throws Exception {
    if (cached == null) {
      Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
          "wheeler.compiler.closure.module_manifest"));
      sources.put("NativeBootstrapModulesIdentity.w", Files.readString(Path.of(
          "../wheeler-conformance/src/main/wheeler/bootstrap/NativeBootstrapModulesIdentity.w")));
      sources.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
      sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
      cached = new WheelerCompiler().compileModuleFiles(
          sources, "wheeler.conformance.bootstrap.modules_identity");
    }
    return cached;
  }

  static Run accepts(BootstrapModuleManifest expected, boolean rewind) throws Exception {
    return run(expected.canonicalBytes(), expected, rewind);
  }

  static void rejectsGraph(byte[] source) throws Exception {
    assertThrows(PackageFormatException.class,
        () -> new BootstrapModuleManifestParser().parse(source));
    run(source, null, true);
  }

  static void rejectsProfile(BootstrapModuleManifest wider) throws Exception {
    run(wider.canonicalBytes(), null, false);
  }

  private static Run run(byte[] source, BootstrapModuleManifest expected, boolean rewind)
      throws Exception {
    Program program = program();
    boolean[] graphFunctions = new boolean[program.functions().size()];
    for (int function = 0; function < graphFunctions.length; function++) {
      String name = program.function(function).name();
      graphFunctions[function] = name.endsWith("module_manifest::validateGraph")
          || name.endsWith("module_manifest::firstOwnerEdge");
    }
    long[] transitions = {0, 0};
    var machine = VirtualMachine.withBinaryInput(program, source, OUTPUT_BYTES, transition -> {
      transitions[0]++;
      if (graphFunctions[transition.functionId()]) { transitions[1]++; }
    });
    var initial = machine.snapshot();
    assertEquals(2, initial.buffers().size());
    boolean rejected = false;
    if (rewind) {
      if (expected == null) {
        assertThrows(VmTrap.class, machine::run);
        rejected = true;
      } else { machine.run(); }
    } else {
      // Large graph fixtures retain no preparation or execution history.
      while (machine.status() != MachineStatus.HALTED
          && machine.status() != MachineStatus.TRAPPED
          && transitions[0] < MAX_LARGE_GRAPH_TRANSITIONS) {
        try { machine.stepWithoutRewindHistory(); }
        catch (VmTrap trap) {
          if (expected != null) { throw trap; }
          rejected = true;
          break;
        }
      }
    }
    var after = machine.snapshot();
    assertEquals(expected == null, rejected);
    if (expected != null) { assertEquals(MachineStatus.HALTED, machine.status()); }
    assertEquals(expected == null ? 0 : 1, machine.global("published"));
    assertEquals(initial.buffers().getFirst(), after.buffers().getFirst());
    byte[] output = new byte[OUTPUT_BYTES];
    if (expected != null) {
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(source);
      System.arraycopy(digest, 0, output, 0, digest.length);
      assertArrayEquals(digest, machine.hostOutput());
      assertEquals(expected.modules().size(), machine.global("moduleCount"));
      assertEquals(expected.externals().size(), machine.global("externalCount"));
      assertEquals(expected.modules().stream().mapToInt(m -> m.imports().size()).sum(),
          machine.global("importCount"));
      var arenas = after.regions().stream().filter(r -> r.maxBytes() == 12_288).toList();
      assertEquals(1, arenas.size());
      assertEquals(3, arenas.getFirst().maxObjects());
      assertTrue(arenas.getFirst().dropped());
    } else {
      assertEquals(0, machine.global("moduleCount"));
      assertEquals(0, machine.global("externalCount"));
      assertEquals(0, machine.global("importCount"));
    }
    var actual = after.buffers().get(1);
    assertEquals(OUTPUT_BYTES, actual.length());
    byte[] bytes = new byte[OUTPUT_BYTES];
    for (int index = 0; index < bytes.length; index++) {
      bytes[index] = actual.elements().get(index).byteValue();
    }
    assertArrayEquals(output, bytes);
    if (rewind) {
      while (machine.historySize() > 0) { machine.rewindOne(); }
      assertEquals(initial, machine.snapshot());
    } else { assertEquals(0, machine.historySize()); }
    return new Run(transitions[0], transitions[1]);
  }
}
