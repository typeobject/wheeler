package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Direct source-product evidence for structured comparison and indexed-copy loops. */
final class NativeCompilerStructuredComparisonSourceProductExampleTest {
  private static final String MODULE = "example.structured_comparison";
  private static final String SOURCE = """
      module example.structured_comparison;

      classical class StructuredComparison {
        private const long MAX_SOURCE_BYTES = 32768;

        public long copyOffset(
          borrow byteview source,
          long sourceStart,
          long length,
          borrow mut words rows,
          borrow mut bytes output
        ) {
          long index = 0;
          while (index < length) limit MAX_SOURCE_BYTES {
            long kind = rows[512 + index];
            boolean one = kind == 1;
            assert(-1 < kind);
            assert(index < length);
            assert(one);
            setByte(output, index, source[index]);
            index += 1;
          }

          return length;
        }
      }
      """;

  @Test
  void emitsStructuredComparisonAndIndexedCopyProducts() throws Exception {
    String source = SOURCE;
    int body = source.indexOf("{", source.indexOf("copyOffset("));
    int maxSourceBytes = source.indexOf("MAX_SOURCE_BYTES");
    Program driver = driver(body, matchingClose(source, body) - body + 1, maxSourceBytes);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (RuntimeException exception) {
      var frame = machine.snapshot().selectedFrames().getLast();
      var function = driver.functions().get(frame.functionId());
      int start = Math.max(0, frame.programCounter() - 8);
      int end = Math.min(function.forward().size(), frame.programCounter() + 2);
      throw new AssertionError(
          function.name() + " instruction=" + frame.programCounter()
              + " nearby=" + function.forward().subList(start, end),
          exception);
    }

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredComparison.w", source), MODULE);
    byte[] expectedBytes = new BytecodeWriter().write(expected);
    assertEquals(1, machine.global("valid"));
    assertEquals(expectedBytes.length, machine.global("artifactLength"));
    assertArrayEquals(expectedBytes, machine.hostOutput());
  }

  @Test
  void malformedComparisonProductsPublishNoArtifact() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "assert(index < length);", "assert(index < length + 1);"));
  }

  @Test
  void oversizedLiteralIndexPublishesNoArtifact() throws Exception {
    assertNoArtifact(SOURCE.replace("512 + index", "65536 + index"));
  }

  private static void assertNoArtifact(String source) throws Exception {
    int body = source.indexOf("{", source.indexOf("copyOffset("));
    int maxSourceBytes = source.indexOf("MAX_SOURCE_BYTES");
    Program driver = driver(body, matchingClose(source, body) - body + 1, maxSourceBytes);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("artifactLength"));
  }

  private static Program driver(
      int bodyStart,
      int bodyLength,
      int maxSourceBytes) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("StructuredComparisonSourceProductExample.w", """
        module example.structured_comparison_source_product;

        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.structured_source_module_compiler;
        import wheeler.core.encoding.binary;

        classical class StructuredComparisonSourceProductExample {
          state long valid = 0;
          state long artifactLength = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 1200000, /* allocations= */ 16);
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
            set(symbolOwners, 0, 0);
            set(symbolStarts, 0, %d);
            set(symbolLengths, 0, 16);
            set(symbolTypes, 0, 1);
            set(symbolValues, 0, 32768);
            set(symbolResolved, 0, 1);
            set(signatureTypes, 0, 0);
            set(signatureTypes, 4096, 0);
            set(signatureTypes, 8192, 13);
            set(signatureTypes, 1, 0);
            set(signatureTypes, 4097, 1);
            set(signatureTypes, 8193, 1);
            set(signatureTypes, 2, 0);
            set(signatureTypes, 4098, 2);
            set(signatureTypes, 8194, 1);
            set(signatureTypes, 3, 0);
            set(signatureTypes, 4099, 3);
            set(signatureTypes, 8195, 10);
            set(signatureTypes, 4, 0);
            set(signatureTypes, 4100, 4);
            set(signatureTypes, 8196, 11);
            set(parameterCounts, 0, 5);
            writeAscii(strings, 0, "$library");
            writeAscii(strings, 8, "StructuredComparison");
            writeAscii(strings, 28, "example.structured_comparison::copyOffset");
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 8);
            set(stringStarts, 1, 8);
            set(stringLengths, 1, 20);
            set(stringStarts, 2, 28);
            set(stringLengths, 2, 41);
            set(functionNameIds, 0, 2);
            SourceProductArtifactPlan plan = compileStructuredSourceModule(
              input,
              /* archiveSourceStart= */ 0,
              /* moduleOwner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              /* symbolCount= */ 1,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              /* signatureTypeCount= */ 5,
              signatureTypes,
              parameterCounts,
              strings,
              /* stringBytes= */ 69,
              /* stringCount= */ 3,
              stringStarts,
              stringLengths,
              functionNameIds,
              artifact,
              identity
            );
            assert(0 < plan.length);
            long artifactByte = 0;
            while (artifactByte < plan.length) limit 32768 {
              setByte(output, artifactByte, artifact[artifactByte]);
              artifactByte += 1;
            }
            setOutputLength(output, plan.length);
            artifactLength = plan.length;
            valid = 1;
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
        """.formatted(bodyStart, bodyLength, maxSourceBytes));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.structured_comparison_source_product");
  }

  private static int matchingClose(String source, int open) {
    int depth = 1;
    for (int index = open + 1; index < source.length(); index++) {
      if (source.charAt(index) == '{') {
        depth += 1;
      } else if (source.charAt(index) == '}') {
        depth -= 1;
        if (depth == 0) {
          return index;
        }
      }
    }
    throw new IllegalArgumentException("Unclosed callable body");
  }
}
