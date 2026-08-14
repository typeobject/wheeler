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
  @Test
  void rebuildsAndHashesACompleteSourceLocalArtifact() throws Exception {
    byte[] artifact = fixtureArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 32_768);

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
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 32_768);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
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

  private static Program program() throws Exception {
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
          state long artifactLength = 0;
          state long codeStart = 0;
          state long functionCount = 0;
          state long maxLocalCount = 0;
          state long identityFirst = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 33824, /* allocations= */ 4);
            bytes sectionArchive = allocateBytes(products, /* length= */ 32768);
            words sectionStarts = allocate(products, /* length= */ 64);
            words sectionLengths = allocate(products, /* length= */ 64);
            bytes identity = allocateBytes(products, /* length= */ 32);
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
              while (sectionByte < length) limit 32768 {
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
            setOutputLength(output, plan.length);
            drop(identity);
            drop(sectionLengths);
            drop(sectionStarts);
            drop(sectionArchive);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_product_artifact");
  }
}
