package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Direct source-product evidence for structured local calls. */
final class NativeCompilerStructuredCallSourceProductExampleTest {
  private static final String MODULE = "example.structured_call";
  private static final String SOURCE = """
      module example.structured_call;

      classical class StructuredCall {
        public long recurse(long value) {
          long index = 0;
          while (index < 1) limit 1 {
            index += 1;
          }

          long result = recurse(value);
          return result;
        }
      }
      """;

  @Test
  void emitsAValueCallAfterACompletedRootLoop() throws Exception {
    assertArtifact(SOURCE, 1, 1, 0);
  }

  @Test
  void emitsAnImportedCallThroughAVerifiedSignatureStub() throws Exception {
    String source = SOURCE.replace("recurse(value)", "remote(value)")
        .replace("public long recurse", "public long caller")
        .replace(
            "long result = remote(value);",
            "long first = remote(value);\n    long result = remote(first);");
    int bodyStart = source.indexOf("{", source.indexOf("caller("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, 1, 1, 0, true);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("functionCount"));
  }

  @Test
  void emitsAQualifiedImportedCallThroughTheSharedPipeline() throws Exception {
    String source = SOURCE.replace("recurse(value)", "dep.alpha::remote(value)")
        .replace("public long recurse", "public long caller");
    int bodyStart = source.indexOf("{", source.indexOf("caller("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, 1, 1, 0, true);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("functionCount"));
  }

  @Test
  void emitsImportedBooleanAndVoidSignatureStubs() throws Exception {
    String booleanSource = SOURCE.replace(
        "public long recurse(long value)",
        "public boolean caller(boolean value)")
        .replace("recurse(value)", "remote(value)")
        .replace("long result = remote(value)", "boolean result = remote(value)");
    assertImportedArtifact(booleanSource, "caller(", 1, 2, 2);

    String voidSource = SOURCE.replace(
        "public long recurse(long value)",
        "public void caller()")
        .replace("long result = recurse(value);\n    return result;", "remote();");
    assertImportedArtifact(voidSource, "caller(", 0, 0, 0);
  }

  @Test
  void emitsAValueCallInsideTheRootLoop() throws Exception {
    String source = SOURCE.replace(
        "index += 1;",
        "long nested = recurse(value);\n      index += 1;")
        .replace("long result = recurse(value);\n    return result;", "return value;");

    assertArtifact(source, 1, 1, 0);
  }

  @Test
  void emitsAValueCallInsideANestedGuard() throws Exception {
    String source = SOURCE.replace(
        "index += 1;",
        "if (index < 1) {\n        long nested = recurse(value);\n      }\n      index += 1;")
        .replace("long result = recurse(value);\n    return result;", "return value;");

    assertArtifact(source, 1, 1, 0);
  }

  @Test
  void emitsAValueCallAtDepthFour() throws Exception {
    String source = SOURCE.replace(
        "index += 1;",
        "while (index < 1) limit 1 {\n"
            + "        while (index < 1) limit 1 {\n"
            + "          while (index < 1) limit 1 {\n"
            + "            long nested = recurse(value);\n"
            + "            index += 1;\n"
            + "          }\n"
            + "        }\n"
            + "      }")
        .replace("long result = recurse(value);\n    return result;", "return value;");

    assertArtifact(source, 1, 1, 0);
  }

  @Test
  void emitsNestedBooleanAndVoidCalls() throws Exception {
    String booleanSource = SOURCE.replace(
        "public long recurse(long value)",
        "public boolean recurse(boolean value)")
        .replace(
            "index += 1;",
            "boolean nested = recurse(value);\n      index += 1;")
        .replace("long result = recurse(value);\n    return result;", "return value;");
    assertArtifact(booleanSource, 1, 2, 0);

    String voidSource = SOURCE.replace("public long recurse(long value)", "public void recurse()")
        .replace("index += 1;", "recurse();\n      index += 1;")
        .replace("long result = recurse(value);\n    return result;", "");
    assertArtifact(voidSource, 0, 0, 0);
  }

  @Test
  void preservesNestedCallsAcrossTwoRootLoops() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public long recurse(long value) {
            long index = 0;
            while (index < 1) limit 1 {
              long first = recurse(value);
              index += 1;
            }

            long between = 1;
            assert(between == 1);
            while (index < 2) limit 1 {
              long second = recurse(value);
              index += 1;
            }

            return value;
          }
        }
        """;

    assertArtifact(source, 1, 1, 0);
  }

  @Test
  void rejectsMalformedNestedArgumentsWithoutPublishing() throws Exception {
    String malformed = SOURCE.replace(
        "index += 1;",
        "long nested = recurse(missing);\n      index += 1;")
        .replace("long result = recurse(value);\n    return result;", "return value;");

    assertRejected(malformed, 1, 1, 0);
  }

  @Test
  void rejectsCallsBeyondDepthFourWithoutPublishing() throws Exception {
    String tooDeep = SOURCE.replace(
        "index += 1;",
        "while (index < 1) limit 1 {\n"
            + "        while (index < 1) limit 1 {\n"
            + "          while (index < 1) limit 1 {\n"
            + "            while (index < 1) limit 1 {\n"
            + "              long nested = recurse(value);\n"
            + "              index += 1;\n"
            + "            }\n"
            + "          }\n"
            + "        }\n"
            + "      }")
        .replace("long result = recurse(value);\n    return result;", "return value;");

    assertRejected(tooDeep, 1, 1, 0);
  }

  @Test
  void emitsABooleanResultCall() throws Exception {
    String source = SOURCE.replace("public long recurse(long value)",
        "public boolean recurse(boolean value)")
        .replace("long result = recurse(value);", "boolean result = recurse(value);");

    assertArtifact(source, 1, 2, 0);
  }

  @Test
  void emitsAVoidCallWithoutFabricatedLocals() throws Exception {
    String source = SOURCE.replace("public long recurse(long value)", "public void recurse()")
        .replace("long result = recurse(value);\n    return result;", "recurse();");

    assertArtifact(source, 0, 0, 0);
  }

  @Test
  void emitsTwoOrderedArguments() throws Exception {
    String source = SOURCE.replace("long value)", "long value, boolean enabled)")
        .replace("recurse(value);", "recurse(value, enabled);");

    assertArtifact(source, 2, 1, 2);
  }

  private static void assertImportedArtifact(
      String source,
      String callable,
      int parameterCount,
      int parameterType,
      int resultType) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf(callable));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(
        bodyStart,
        bodyLength,
        parameterCount,
        parameterType,
        0,
        true,
        parameterType,
        resultType);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("functionCount"));
  }

  private static void assertRejected(
      String source,
      int parameterCount,
      int firstType,
      int secondType) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, parameterCount, firstType, secondType);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(RuntimeException.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  private static void assertArtifact(
      String source,
      int parameterCount,
      int firstType,
      int secondType) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, parameterCount, firstType, secondType);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (RuntimeException exception) {
      var frame = machine.snapshot().selectedFrames().getLast();
      var function = driver.functions().get(frame.functionId());
      int start = Math.max(0, frame.programCounter() - 8);
      int end = Math.min(function.forward().size(), frame.programCounter() + 2);
      var nearby = function.forward().subList(start, end);
      long target = function.forward().get(frame.programCounter() - 4).operands().getFirst();
      throw new AssertionError(
          function.name() + " instruction=" + frame.programCounter()
              + " target=" + driver.functions().get((int) target).name()
              + " nearby=" + nearby,
          exception);
    }

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", source), MODULE);
    byte[] expectedBytes = new BytecodeWriter().write(expected);
    assertEquals(1, machine.global("valid"));
    assertEquals(expectedBytes.length, machine.global("artifactLength"));
    assertArrayEquals(expectedBytes, machine.hostOutput());
  }

  private static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType) throws Exception {
    return driver(bodyStart, bodyLength, parameterCount, firstType, secondType, false);
  }

  private static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported) throws Exception {
    return driver(
        bodyStart,
        bodyLength,
        parameterCount,
        firstType,
        secondType,
        imported,
        1,
        1);
  }

  private static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int importedParameterType,
      int importedResultType) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("StructuredCallSourceProductExample.w", """
        module example.structured_call_source_product;

        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.structured_source_module_compiler;

        classical class StructuredCallSourceProductExample {
          state long valid = 0;
          state long artifactLength = 0;
          state long functionCount = 0;
          state long maxLocalCount = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 2903936, /* allocations= */ 20);
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
            words importedRows = allocate(products, /* length= */ 32768);
            words importedParameterRows = allocate(products, /* length= */ 32768);
            bytes importedNames = allocateBytes(products, /* length= */ 1048576);
            bytes importedIdentities = allocateBytes(products, /* length= */ 131072);
            region qualifiers = new region(/* bytes= */ 1146880, /* allocations= */ 4);
            bytes qualifierNames = allocateBytes(qualifiers, /* length= */ 1048576);
            words qualifierNameStarts = allocate(qualifiers, /* length= */ 4096);
            words qualifierNameLengths = allocate(qualifiers, /* length= */ 4096);
            words qualifierRanks = allocate(qualifiers, /* length= */ 4096);
            IMPORTED_SETUP
            set(bodyStarts, 0, BODY_START);
            set(bodyLengths, 0, BODY_LENGTH);
            set(signatureTypes, 0, 0);
            set(signatureTypes, 4096, 0);
            set(signatureTypes, 8192, FIRST_TYPE);
            set(signatureTypes, 1, 0);
            set(signatureTypes, 4097, 1);
            set(signatureTypes, 8193, SECOND_TYPE);
            set(parameterCounts, 0, PARAMETER_COUNT);
            writeAscii(strings, 0, "$library");
            writeAscii(strings, 8, "StructuredCall");
            writeAscii(strings, 22, "example.structured_call::recurse");
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 8);
            set(stringStarts, 1, 8);
            set(stringLengths, 1, 14);
            set(stringStarts, 2, 22);
            set(stringLengths, 2, 32);
            set(functionNameIds, 0, 2);
            SourceProductArtifactPlan plan = compileStructuredSourceModuleWithTargets(
              input,
              /* archiveSourceStart= */ 0,
              /* moduleOwner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              /* importedTargetCount= */ IMPORTED_COUNT,
              importedRows,
              importedParameterRows,
              importedNames,
              importedIdentities,
              qualifierNames,
              qualifierNameStarts,
              qualifierNameLengths,
              qualifierRanks,
              bodyStarts,
              bodyLengths,
              /* symbolCount= */ 0,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              /* signatureTypeCount= */ PARAMETER_COUNT,
              signatureTypes,
              parameterCounts,
              strings,
              /* stringBytes= */ 54,
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
            functionCount = plan.functionCount;
            maxLocalCount = plan.maxLocalCount;
            valid = 1;
            drop(qualifierRanks);
            drop(qualifierNameLengths);
            drop(qualifierNameStarts);
            drop(qualifierNames);
            drop(qualifiers);
            drop(importedIdentities);
            drop(importedNames);
            drop(importedParameterRows);
            drop(importedRows);
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
        """.replace("BODY_START", Integer.toString(bodyStart))
            .replace("BODY_LENGTH", Integer.toString(bodyLength))
            .replace("PARAMETER_COUNT", Integer.toString(parameterCount))
            .replace("FIRST_TYPE", Integer.toString(firstType))
            .replace("SECOND_TYPE", Integer.toString(secondType))
            .replace("IMPORTED_COUNT", imported ? "2" : "0")
            .replace("IMPORTED_SETUP", imported
                ? "writeAscii(importedNames, 0, \"remoteunused\");\n"
                    + "writeAscii(qualifierNames, 0, \"dep.alphadep.beta\");\n"
                    + "set(qualifierNameLengths, 0, 9);\n"
                    + "set(qualifierNameStarts, 1, 9);\n"
                    + "set(qualifierNameLengths, 1, 8);\n"
                    + "set(importedRows, 12288, 6);\n"
                    + "set(importedRows, 20480, IMPORTED_PARAMETER_COUNT);\n"
                    + "set(importedRows, 24576, IMPORTED_RESULT_TYPE);\n"
                    + "set(importedRows, 4097, 1);\n"
                    + "set(importedRows, 8193, 6);\n"
                    + "set(importedRows, 12289, 6);\n"
                    + "set(importedRows, 16385, 1);\n"
                    + "set(importedRows, 20481, IMPORTED_PARAMETER_COUNT);\n"
                    + "set(importedRows, 24577, IMPORTED_RESULT_TYPE);\n"
                    + "set(importedParameterRows, 0, IMPORTED_PARAMETER_TYPE);\n"
                    + "set(importedParameterRows, 1, IMPORTED_PARAMETER_TYPE);\n"
                    + "setByte(importedIdentities, 0, 42);\n"
                    + "setByte(importedIdentities, 32, 43);"
                : "")
            .replace("IMPORTED_PARAMETER_COUNT", Integer.toString(parameterCount))
            .replace("IMPORTED_PARAMETER_TYPE", Integer.toString(importedParameterType))
            .replace("IMPORTED_RESULT_TYPE", Integer.toString(importedResultType)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.structured_call_source_product");
  }

}
