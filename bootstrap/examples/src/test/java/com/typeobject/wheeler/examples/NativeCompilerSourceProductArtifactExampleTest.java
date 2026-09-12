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
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for direct source-product artifact publication. */
final class NativeCompilerSourceProductArtifactExampleTest {
  private static final int SOURCE_CALL_LIMIT = 256;

  @Test
  void rebuildsAndHashesACompleteSourceLocalArtifact() throws Exception {
    byte[] artifact = fixtureArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(0), artifact, 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertArrayEquals(artifact, machine.hostOutput());
    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(sectionStart(artifact, 6), machine.global("codeStart"));
    assertEquals(1, machine.global("functionCount"));
    assertEquals(0, machine.global("maxLocalCount"));
    assertEquals(
        MessageDigest.getInstance("SHA-256").digest(artifact)[0] & 0xff,
        machine.global("identityFirst"));
  }

  @Test
  void rejectsMalformedProductsBeforePublishingOneByte() throws Exception {
    byte[] artifact = fixtureArtifact();
    artifact[Math.toIntExact(sectionStart(artifact, 6))] = (byte) 0xff;
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(0), artifact, 32_768);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  @Test
  void publishesCompleteRelocationReportsAndRejectsTheFirstExcessCount() throws Exception {
    for (int count : new int[] {1, SOURCE_CALL_LIMIT}) {
      byte[] artifact = new WheelerCompiler().compileToBytecode(
          "classical class Report { void tick() {} entry void main() { " + "tick();".repeat(count) + " } }");
      VirtualMachine machine = VirtualMachine.withBinaryInput(program(count), artifact, 32_768);
      var initial = machine.snapshot();
      while (machine.global("published") == 0) machine.stepWithoutRewindHistory();
      assertEquals(count, machine.global("relocationCount"));
      assertArrayEquals(artifact, machine.hostOutput());
      var output = machine.snapshot().buffers().get(initial.buffers().getLast().id());
      for (int index = artifact.length; index < output.length(); index++) assertEquals(0, output.elements().get(index));
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(artifact);
      var identity = machine.snapshot().buffers().stream()
          .filter(buffer -> !buffer.dropped() && buffer.length() == digest.length).findFirst().orElseThrow();
      for (int index = 0; index < digest.length; index++) {
        assertEquals(Byte.toUnsignedInt(digest[index]), identity.elements().get(index));
      }
      assertEquals(initial.buffers().getFirst(), machine.snapshot().buffers().getFirst());
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
    for (long count : new long[] {-1, SOURCE_CALL_LIMIT + 1, Long.MAX_VALUE}) {
      VirtualMachine machine = VirtualMachine.withBinaryInput(program(count), fixtureArtifact(), 32_768);
      var input = machine.snapshot().buffers();
      assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
      assertEquals(0, machine.global("published"));
      assertEquals(0, machine.global("relocationCount"));
      for (var buffer : input) assertEquals(buffer, machine.snapshot().buffers().get(buffer.id()));
      var identity = machine.snapshot().buffers().stream()
          .filter(buffer -> !buffer.dropped() && buffer.length() == 256 / Byte.SIZE).findFirst().orElseThrow();
      for (long cell : identity.elements()) assertEquals(0, cell);
    }
  }

  private static byte[] fixtureArtifact() throws Exception {
    return new WheelerCompiler().compileToBytecode("""
        classical class SourceProductFixture {
          entry void main() {}
        }
        """);
  }

  private static long sectionStart(byte[] artifact, int type) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sectionCount = bytes.getInt(24);
    for (int section = 0; section < sectionCount; section++) {
      int directory = 40 + section * 32;
      if (bytes.getInt(directory) == type) {
        return bytes.getLong(directory + 8);
      }
    }
    throw new AssertionError("missing section " + type);
  }

  private static Program program(long relocationCount) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_product_artifact"));
    sources.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("SourceProductArtifactExample.w", """
        module example.source_product_artifact;

        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.core.encoding.binary;

        classical class SourceProductArtifactExample {
          private const long ARTIFACT_BYTES = 32768;
          private const long DIRECTORY_ROWS = 64;
          private const long DIRECTORY_COLUMNS = 2;
          private const long IDENTITY_BYTES = 32;
          private const long WORD_BYTES = 8;
          private const long PRODUCT_BYTES = ARTIFACT_BYTES + IDENTITY_BYTES
            + DIRECTORY_ROWS * DIRECTORY_COLUMNS * WORD_BYTES;
          private const long PRODUCT_BUFFERS = DIRECTORY_COLUMNS + 2;
          state long published = 0;
          state long relocationCount = 0;
          state long artifactLength = 0;
          state long codeStart = 0;
          state long functionCount = 0;
          state long maxLocalCount = 0;
          state long identityFirst = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region products = new region(/* bytes= */ PRODUCT_BYTES, /* allocations= */ PRODUCT_BUFFERS);
            bytes sectionArchive = allocateBytes(products, ARTIFACT_BYTES);
            words sectionStarts = allocate(products, DIRECTORY_ROWS);
            words sectionLengths = allocate(products, DIRECTORY_ROWS);
            bytes identity = allocateBytes(products, IDENTITY_BYTES);
            long sectionBytes = 0;
            long section = 0;
            while (section < 6) limit 6 {
              long directory = 40 + section * 32;
              assert(readUnsigned(input, directory, 4) == section + 1);
              long start = readUnsigned(input, directory + 8, 8);
              long length = readUnsigned(input, directory + 16, 8);
              set(sectionStarts, section, sectionBytes);
              set(sectionLengths, section, length);
              long sectionByte = 0;
              while (sectionByte < length) limit ARTIFACT_BYTES {
                setByte(
                  sectionArchive,
                  sectionBytes + sectionByte,
                  input[start + sectionByte]
                );
                sectionByte += 1;
              }
              sectionBytes += length;
              section += 1;
            }
            SourceProductArtifactPlan plan = publishSourceProductArtifact(
              /* relocationCount= */ RELOCATION_COUNT,
              sectionArchive,
              sectionBytes,
              /* sectionCount= */ 6,
              sectionStarts,
              sectionLengths,
              output,
              identity
            );
            artifactLength = plan.length;
            codeStart = plan.codeStart;
            functionCount = plan.functionCount;
            maxLocalCount = plan.maxLocalCount;
            identityFirst = identity[0];
            relocationCount = plan.relocationCount;
            setOutputLength(output, plan.length);
            published = 1;
            drop(identity);
            drop(sectionLengths);
            drop(sectionStarts);
            drop(sectionArchive);
            drop(products);
          }
        }
        """.replace("RELOCATION_COUNT", Long.toString(relocationCount)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_product_artifact");
  }
}
