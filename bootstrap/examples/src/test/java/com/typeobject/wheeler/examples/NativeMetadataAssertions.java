package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.nio.charset.StandardCharsets;
import java.util.function.Consumer;

/** Keeps metadata hash-alias regressions independent of native admission. */
final class NativeMetadataAssertions {
  private NativeMetadataAssertions() {}

  static void assertHashAliasesRejected(
      Program program, String source, Consumer<byte[]> stageZero, String... keys) {
    for (String key : keys) {
      assertTrue(source.contains(key + ":"), key);
      char[] spelling = key.toCharArray();
      spelling[spelling.length - 2]++;
      spelling[spelling.length - 1] -= 31;
      String alias = new String(spelling);
      assertEquals(polynomial(key), polynomial(alias), key);
      byte[] input = source.replace(key + ":", alias + ":").getBytes(StandardCharsets.UTF_8);
      assertThrows(PackageFormatException.class, () -> stageZero.accept(input), alias);
      var machine = new VirtualMachine(program, input, input.length);
      var initial = machine.snapshot();
      assertThrows(VmTrap.class, machine::run, alias);
      assertEquals(0, machine.global("emittedLength"), alias);
      assertEquals(0, machine.global("finalCursor"), alias);
      assertArrayEquals(new byte[input.length], machine.hostOutput(), alias);
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot(), alias);
    }
  }

  private static long polynomial(String value) {
    long hash = 0;
    for (int index = 0; index < value.length(); index++) {
      hash = Math.addExact(Math.multiplyExact(hash, 31), value.charAt(index));
    }
    return hash;
  }
}
