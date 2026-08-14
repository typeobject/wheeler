package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for byte-view reads, byte writes, and indexed byte copies. */
final class NativeCompilerStructuredByteProductsExampleTest {
  private static final String SOURCE = """
      //! Exercises direct byte products in one structured loop.

      module example.byte_loop;

      classical class ByteLoop {
        /// Copies a bounded byte prefix and returns its final value.
        public long copyAndRead(
          borrow byteview input,
          borrow mut bytes output,
          borrow mut bytes scratch,
          long count
        ) {
          long index = 0;
          long observed = 0;
          while (index < count) limit 64 {
            long value = input[index];
            setByte(scratch, index, value);
            setByte(output, index, scratch[index]);
            setByte(output, index, input[index]);
            long copied = output[index];
            observed = copied;
            index += 1;
          }

          return observed;
        }
      }
      """;

  @Test
  void compilesByteViewsWritesAndIndexedCopiesWithoutProjection() throws Exception {
    int bodyStart = SOURCE.indexOf('{', SOURCE.indexOf("copyAndRead("));
    int bodyLength = matchingClose(SOURCE, bodyStart) - bodyStart + 1;
    var expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("ByteLoop.w", SOURCE), "example.byte_loop");
    byte[] expected = new BytecodeWriter().write(expectedProgram);
    var program = productProgram(bodyStart, bodyLength);
    var machine = new VirtualMachine(program, SOURCE.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(expected.length, machine.global("artifactLength"));
    assertArrayEquals(expected, machine.hostOutput());
  }

  private static com.typeobject.wheeler.core.bytecode.Program productProgram(
      int bodyStart, int bodyLength) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("StructuredByteProductsExample.w", """
        module example.structured_byte_products;

        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.structured_source_module_compiler;
        import wheeler.core.encoding.binary;

        classical class StructuredByteProductsExample {
          state long valid = 0;
          state long artifactLength = 0;

          entry void main(borrow utf8 source, borrow mut bytes output) {
            region products = new region(/* bytes= */ 1024992, /* allocations= */ 16);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words symbolOwners = allocate(products, /* length= */ 16384);
            words symbolStarts = allocate(products, /* length= */ 16384);
            words symbolLengths = allocate(products, /* length= */ 16384);
            words symbolTypes = allocate(products, /* length= */ 16384);
            words symbolValues = allocate(products, /* length= */ 16384);
            words symbolResolved = allocate(products, /* length= */ 16384);
            words signatureTypes = allocate(products, /* length= */ 12288);
            words parameterCounts = allocate(products, /* length= */ 64);
            bytes strings = allocateBytes(products, /* length= */ 32768);
            words stringStarts = allocate(products, /* length= */ 256);
            words stringLengths = allocate(products, /* length= */ 256);
            words functionNameIds = allocate(products, /* length= */ 64);
            bytes artifact = allocateBytes(products, /* length= */ 32768);
            bytes identity = allocateBytes(products, /* length= */ 32);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(signatureTypes, 0, 0);
            set(signatureTypes, 4096, 0);
            set(signatureTypes, 8192, 13);
            set(signatureTypes, 1, 0);
            set(signatureTypes, 4097, 1);
            set(signatureTypes, 8193, 11);
            set(signatureTypes, 2, 0);
            set(signatureTypes, 4098, 2);
            set(signatureTypes, 8194, 11);
            set(signatureTypes, 3, 0);
            set(signatureTypes, 4099, 3);
            set(signatureTypes, 8195, 1);
            set(parameterCounts, 0, 4);
            writeAscii(strings, 0, "$library");
            writeAscii(strings, 8, "ByteLoop");
            writeAscii(strings, 16, "example.byte_loop::copyAndRead");
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 8);
            set(stringStarts, 1, 8);
            set(stringLengths, 1, 8);
            set(stringStarts, 2, 16);
            set(stringLengths, 2, 30);
            set(functionNameIds, 0, 2);
            SourceProductArtifactPlan plan = compileStructuredSourceModule(
              source,
              /* archiveSourceStart= */ 0,
              /* moduleOwner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              /* symbolCount= */ 0,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              /* signatureTypeCount= */ 4,
              signatureTypes,
              parameterCounts,
              strings,
              /* stringBytes= */ 46,
              /* stringCount= */ 3,
              stringStarts,
              stringLengths,
              functionNameIds,
              artifact,
              identity
            );
            long artifactByte = 0;
            while (artifactByte < plan.length) limit 32768 {
              setByte(output, artifactByte, artifact[artifactByte]);
              artifactByte += 1;
            }

            setOutputLength(output, plan.length);
            artifactLength = plan.length;
            if (0 < plan.length) {
              valid = 1;
            }
            drop(identity);
            drop(artifact);
            drop(functionNameIds);
            drop(stringLengths);
            drop(stringStarts);
            drop(strings);
            drop(parameterCounts);
            drop(signatureTypes);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(bodyStart, bodyLength));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.structured_byte_products");
  }

  private static int matchingClose(String source, int open) {
    int depth = 0;
    for (int cursor = open; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth += 1;
      }
      if (source.charAt(cursor) == '}') {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }
    }
    throw new IllegalArgumentException("unbalanced source");
  }
}
