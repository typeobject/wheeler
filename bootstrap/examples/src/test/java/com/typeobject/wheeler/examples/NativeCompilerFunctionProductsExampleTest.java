package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for canonical function and instruction products. */
final class NativeCompilerFunctionProductsExampleTest {
  @Test
  void decodesCanonicalFunctionDescriptorsAndInstructions() throws Exception {
    Program product = product();
    byte[] artifact = new BytecodeWriter().write(product);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact, 32);

    machine.run();

    long instructions = product.functions().stream()
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    long maxLocals = product.functions().stream()
        .mapToLong(function -> function.localTypes().size())
        .max()
        .orElseThrow();
    assertEquals(product.functions().size(), machine.global("functionCount"));
    assertEquals(instructions, machine.global("instructionCount"));
    assertEquals(maxLocals, machine.global("maxLocalCount"));
    assertEquals(1, machine.global("localRelocationCount"));
    assertEquals(0, machine.global("firstLocalTarget"));
    assertEquals(product.functions().getFirst().forward().getFirst().opcode().code(),
        machine.global("firstOpcode"));
    assertEquals(1, machine.global("published"));
    assertEquals(expectedIdentity(artifact), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsUnknownExecutableOpcodesBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    int codeStart = sectionStart(artifact, 6);
    artifact[codeStart] = (byte) 0xff;
    artifact[codeStart + 1] = (byte) 0xff;
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsUnknownLocalCallTargetsBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    int call = firstCallInstruction(artifact);
    putLong(artifact, call + 8, 99);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals("00".repeat(32), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsNoncontiguousFunctionCodeBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    int functionsStart = sectionStart(artifact, 5);
    putInt(artifact, functionsStart + 16, 1);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program decoder() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.function_product_identities"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.local_call_relocations"));
    sources.put("FunctionProductsExample.w", """
        module example.function_products;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.function_product_identities;
        import wheeler.compiler.closure.local_call_relocations;

        classical class FunctionProductsExample {
          state long functionCount = 0;
          state long instructionCount = 0;
          state long maxLocalCount = 0;
          state long firstOpcode = 0;
          state long localRelocationCount = 0;
          state long firstLocalTarget = -1;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 203872, /* allocations= */ 6);
            words functions = allocate(rows, /* length= */ 640);
            words instructions = allocate(rows, /* length= */ 24576);
            bytes signatureIdentity = allocateBytes(rows, /* length= */ 32);
            bytes aggregateIdentity = allocateBytes(rows, /* length= */ 32);
            bytes ownershipIdentity = allocateBytes(rows, /* length= */ 32);
            bytes dependencyIdentities = allocateBytes(rows, /* length= */ 2048);
            long identityByte = 0;
            while (identityByte < 32) limit 32 {
              setByte(signatureIdentity, identityByte, 1);
              setByte(aggregateIdentity, identityByte, 2);
              setByte(ownershipIdentity, identityByte, 3);
              setByte(dependencyIdentities, identityByte, 4);
              identityByte += 1;
            }
            CompiledFunctionPlan plan = indexCompiledFunctionProducts(
              source,
              bufferLength(source),
              functions,
              instructions
            );
            region relocations = new region(/* bytes= */ 198656, /* allocations= */ 3);
            bytes signatureIdentities = allocateBytes(relocations, /* length= */ 2048);
            words relocationRows = allocate(relocations, /* length= */ 8192);
            bytes relocationIdentities = allocateBytes(relocations, /* length= */ 131072);
            long localFunction = 0;
            while (localFunction < plan.functionCount) limit 64 {
              long signatureByte = 0;
              while (signatureByte < 32) limit 32 {
                setByte(
                  signatureIdentities,
                  localFunction * 32 + signatureByte,
                  localFunction + 1
                );
                signatureByte += 1;
              }
              localFunction += 1;
            }
            localRelocationCount = resolveLocalCallRelocations(
              source,
              plan.functionCount,
              plan.instructionCount,
              instructions,
              signatureIdentities,
              relocationRows,
              relocationIdentities
            );
            if (0 < localRelocationCount) {
              firstLocalTarget = relocationRows[4096];
            }
            publishFunctionProductIdentity(
              source,
              bufferLength(source),
              functions,
              0,
              signatureIdentity,
              /* dependencyCount= */ 1,
              dependencyIdentities,
              aggregateIdentity,
              ownershipIdentity,
              output
            );
            functionCount = plan.functionCount;
            instructionCount = plan.instructionCount;
            maxLocalCount = plan.maxLocalCount;
            firstOpcode = instructions[12288];
            published = 1;
            setOutputLength(output, 32);
            drop(relocationIdentities);
            drop(relocationRows);
            drop(signatureIdentities);
            drop(relocations);
            drop(dependencyIdentities);
            drop(ownershipIdentity);
            drop(aggregateIdentity);
            drop(signatureIdentity);
            drop(instructions);
            drop(functions);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.function_products");
  }

  private static String expectedIdentity(byte[] artifact) throws Exception {
    int functionsStart = sectionStart(artifact, 5);
    int codeStart = sectionStart(artifact, 6);
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int functionCount = bytes.getInt(functionsStart);
    int descriptor = functionsStart + 4;
    long flags = Integer.toUnsignedLong(bytes.getInt(descriptor + 8));
    int forwardOffset = bytes.getInt(descriptor + 12);
    int forwardLength = bytes.getInt(descriptor + 16);
    int inverseOffset = bytes.getInt(descriptor + 20);
    int inverseLength = bytes.getInt(descriptor + 24);
    long parameterCount = Integer.toUnsignedLong(bytes.getInt(descriptor + 28));
    long localCount = Integer.toUnsignedLong(bytes.getInt(descriptor + 32));
    int typeOffset = bytes.getInt(descriptor + 36);
    int typeCount = Math.toIntExact(localCount + flags / 4 % 2);
    int typeStart = functionsStart + 4 + functionCount * 40 + typeOffset * 4;

    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes("wheeler-callable-body-product-1".getBytes(StandardCharsets.US_ASCII));
    byte[] identity = new byte[32];
    Arrays.fill(identity, (byte) 1);
    input.writeBytes(identity);
    Arrays.fill(identity, (byte) 2);
    input.writeBytes(identity);
    Arrays.fill(identity, (byte) 3);
    input.writeBytes(identity);
    writeLong(input, 1);
    Arrays.fill(identity, (byte) 4);
    input.writeBytes(identity);
    input.writeBytes(digest(artifact, codeStart + forwardOffset, forwardLength));
    input.writeBytes(inverseLength == 0
        ? digest(artifact, 0, 0)
        : digest(artifact, codeStart + inverseOffset, inverseLength));
    input.writeBytes(digest(artifact, typeStart, typeCount * 4));
    writeLong(input, flags);
    writeLong(input, forwardLength);
    writeLong(input, inverseLength);
    writeLong(input, parameterCount);
    writeLong(input, localCount);
    writeLong(input, typeCount);
    return HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(input.toByteArray()));
  }

  private static byte[] digest(byte[] bytes, int start, int length) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    digest.update(bytes, start, length);
    return digest.digest();
  }

  private static void writeLong(ByteArrayOutputStream output, long value) {
    for (int octet = 0; octet < 8; octet++) {
      output.write((int) (value >>> (octet * 8)) & 0xff);
    }
  }

  private static Program product() {
    String source = """
        module fixture.function_products;

        classical class FunctionProducts {
          long identity(long value) {
            return value;
          }

          entry void main() {
            long value = identity(7);
            assert(value == 7);
          }
        }
        """;
    return new WheelerCompiler().compileModuleFiles(
        Map.of("FunctionProducts.w", source),
        "fixture.function_products");
  }

  private static int firstCallInstruction(byte[] artifact) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int codeStart = sectionStart(artifact, 6);
    int codeLength = sectionLength(artifact, 6);
    int cursor = codeStart;
    while (cursor < codeStart + codeLength) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == 0x0200 || opcode == 0x0201 || opcode == 0x0202
          || opcode == 0x0204 || opcode == 0x0205 || opcode == 0x0206) {
        return cursor;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("missing call instruction");
  }

  private static int sectionLength(byte[] artifact, int wantedType) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sections = bytes.getInt(24);
    for (int index = 0; index < sections; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == wantedType) {
        return Math.toIntExact(bytes.getLong(directory + 16));
      }
    }
    throw new AssertionError("missing section " + wantedType);
  }

  private static int sectionStart(byte[] artifact, int wantedType) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sections = bytes.getInt(24);
    for (int index = 0; index < sections; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == wantedType) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing section " + wantedType);
  }

  private static void putInt(byte[] bytes, int offset, int value) {
    ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).putInt(offset, value);
  }

  private static void putLong(byte[] bytes, int offset, long value) {
    ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).putLong(offset, value);
  }
}
