package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
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
  void wheelerHashesTextBinaryAndPaddingBoundaries() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeSha256.w", Files.readString(root.resolve("NativeSha256.w")),
            "Sha256.w", Files.readString(root.resolve("crypto/Sha256.w"))),
        "examples.crypto.sha256_main");
    assertDigest(program, new byte[0], true);
    assertDigest(program, "abc".getBytes(StandardCharsets.US_ASCII), false);
    assertDigest(program, sequence(55), false);
    assertDigest(program, sequence(56), false);
    assertDigest(program, sequence(64), false);
    assertDigest(program, sequence(100), false);
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
