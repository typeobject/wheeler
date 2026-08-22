package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for profile-2 test-case identity derivation. */
final class NativeTestCaseIdentityExampleTest {
  private static final String MANIFEST =
      "98a3eba9ba2cbe9875f34fcd98d4914b7d2238a7ebc1065ea2205cca2460805b";
  private static final String SOURCE =
      "3378eeff4264eb113988db8dd45a788fcef0227ed42df22d28668ee1930f65f6";
  private static Program compiledProgram;

  @Test
  void reproducesTheStageZeroCaseIdentity() throws Exception {
    for (String name : new String[] {
        "compiler",
        "compiler::suite.case[17]",
        "a".repeat(255)
    }) {
      assertArrayEquals(expected(name), execute(frame(MANIFEST, SOURCE, name)));
    }
  }

  @Test
  void rejectsMalformedFramesBeforePublication() throws Exception {
    byte[] uppercase = frame(MANIFEST.toUpperCase(), SOURCE, "compiler");
    byte[] empty = frame(MANIFEST, SOURCE, "");
    byte[] trailing = ByteBuffer.allocate(uppercase.length + 1)
        .put(frame(MANIFEST, SOURCE, "compiler"))
        .put((byte) 0)
        .array();

    assertRejected(uppercase);
    assertRejected(empty);
    assertRejected(trailing);
  }

  private static byte[] expected(String name) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-case/1");
    field(digest, MANIFEST);
    field(digest, name);
    field(digest, SOURCE);
    return digest.digest();
  }

  private static void field(MessageDigest digest, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    digest.update(ByteBuffer.allocate(Long.BYTES).putLong(bytes.length).array());
    digest.update(bytes);
  }

  private static byte[] frame(String manifest, String source, String name) {
    byte[] nameBytes = name.getBytes(StandardCharsets.US_ASCII);
    return ByteBuffer.allocate(130 + nameBytes.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .put(manifest.getBytes(StandardCharsets.US_ASCII))
        .put(source.getBytes(StandardCharsets.US_ASCII))
        .putShort((short) nameBytes.length)
        .put(nameBytes)
        .array();
  }

  private static void assertRejected(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[32], machine.hostOutput());
  }

  private static byte[] execute(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static synchronized Program program() throws Exception {
    if (compiledProgram != null) {
      return compiledProgram;
    }

    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put(
        "TestCaseIdentity.w",
        Files.readString(Path.of(
            "../wheeler-runtime/src/main/wheeler/runtime/testing/TestCaseIdentity.w")));
    sources.put(
        "NativeTestCaseIdentity.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestCaseIdentity.w")));
    compiledProgram = new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_case_identity");
    return compiledProgram;
  }
}
