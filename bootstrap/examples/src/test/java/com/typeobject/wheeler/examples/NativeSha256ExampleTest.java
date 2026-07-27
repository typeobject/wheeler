package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for the provider-free Wheeler SHA-256 implementation. */
class NativeSha256ExampleTest {
  @Test
  void hashesThePhysicalBoundedCompilerManifest() throws Exception {
    byte[] input = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32);
    long transitions = 0;
    while (machine.status() != MachineStatus.HALTED && transitions < 2_000_000) {
      machine.step();
      transitions += 1;
      if (10_000 <= machine.historySize()) {
        machine.commitHistory();
      }
    }

    assertEquals(1_616_379, transitions);
    assertEquals(MachineStatus.HALTED, machine.status());
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(input), machine.hostOutput());
  }

  @Test
  void wheelerHashesTextBinaryAndPaddingBoundaries() throws Exception {
    Program program = program();
    assertDigest(program, new byte[0], true);
    assertDigest(program, "abc".getBytes(StandardCharsets.US_ASCII), false);
    assertDigest(program, sequence(55), false);
    assertDigest(program, sequence(56), false);
    assertDigest(program, sequence(64), false);
    assertDigest(program, sequence(100), false);
  }

  private static Program program() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeSha256.w", Files.readString(root.resolve("NativeSha256.w")),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "examples.crypto.sha256_main");
  }

  private static void assertDigest(
      Program program, byte[] input, boolean verifyRewind) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, input, 32);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(input.length, machine.global("inputLength"));
    assertEquals(32, machine.global("digestLength"));
    assertArrayEquals(
        MessageDigest.getInstance("SHA-256").digest(input),
        machine.hostOutput());
    if (verifyRewind) {
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  private static byte[] sequence(int length) {
    byte[] result = new byte[length];
    for (int index = 0; index < length; index++) {
      result[index] = (byte) (index * 37 + 11);
    }
    return result;
  }
}
