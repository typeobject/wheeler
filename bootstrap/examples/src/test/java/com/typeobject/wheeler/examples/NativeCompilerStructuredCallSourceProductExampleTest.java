package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.StructuredCallSourceProductDriver.driver;
import static com.typeobject.wheeler.examples.StructuredCallSourceProductDriver.driverWithEffect;
import static com.typeobject.wheeler.examples.StructuredCallSourceProductDriver.driverWithSymbol;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.StructuredCallSourceProductDriver.SymbolProduct;
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
  void emitsAValueCallBeforeARootLoop() throws Exception {
    String source = SOURCE.replace(
        "    long index = 0;\n",
        "    long result = recurse(value);\n"
            + "    long index = 0;\n").replace(
                "\n    long result = recurse(value);\n    return result;",
                "\n    return result;");

    assertArtifact(source, 1, 1, 0);
  }

  @Test
  void forwardsAValueCallResultDirectly() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long result = recurse(value);\n"
            + "    return result;\n",
        "    return recurse(value);\n"), 1, 1, 0);
  }

  @Test
  void emitsAFalseReturnBehindALocalBooleanCall() throws Exception {
    assertArtifact(callConditionalSource("return false;"), 1, 2, 0);
  }

  @Test
  void rejectsMultipleCallConditionalChildrenBeforePublication() throws Exception {
    assertRejected(callConditionalSource("return false;\n      return true;"), 1, 2, 0);
  }

  @Test
  void emitsPositiveAndNegativeSignedLiteralReturnsBehindAnImportedBooleanCall()
      throws Exception {
    assertImportedSignedLiteralChild(3);
    assertImportedSignedLiteralChild(-3);
  }

  @Test
  void rejectsAnOverflowingCallConditionalLiteralBeforePublication() throws Exception {
    String source = importedCallConditionalSource("return 9223372036854775808;");
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, 1, 2, 0, true, 2, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(RuntimeException.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  @Test
  void emitsASignedConstantReturnBehindAnImportedBooleanCall() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          private const long RESULT = 4;

          public long recurse(boolean value) {
            if (remote(value)) {
              return RESULT;
            }

            return -1;
          }
        }
        """;
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    int symbolStart = source.indexOf("RESULT", source.indexOf("return"));
    SymbolProduct result = new SymbolProduct(symbolStart, "RESULT".length(), 1, 4, 1);
    Program driver = driverWithSymbol(
        bodyStart, bodyLength, 1, 2, 0, true, 2, 2, 0, result);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("relocationCount"));
  }

  @Test
  void rejectsABooleanProductForASignedCallConditionalChild() throws Exception {
    String source = callConditionalSource("return RESULT;")
        .replace("classical class StructuredCall {",
            "classical class StructuredCall {\n  private const boolean RESULT = true;");
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    int symbolStart = source.indexOf("RESULT", source.indexOf("return"));
    SymbolProduct result = new SymbolProduct(symbolStart, "RESULT".length(), 2, 1, 1);
    Program driver = driverWithSymbol(
        bodyStart, bodyLength, 1, 2, 0, false, 1, 1, 0, result);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(RuntimeException.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  private static String callConditionalSource(String child) {
    return """
        module example.structured_call;

        classical class StructuredCall {
          public boolean recurse(boolean value) {
            if (recurse(value)) {
              CHILD
            }

            return true;
          }
        }
        """.replace("CHILD", child);
  }

  private static String importedCallConditionalSource(String child) {
    return """
        module example.structured_call;

        classical class StructuredCall {
          public long recurse(boolean value) {
            if (remote(value)) {
              CHILD
            }

            return -1;
          }
        }
        """.replace("CHILD", child);
  }

  private static void assertImportedSignedLiteralChild(long expected) throws Exception {
    String source = importedCallConditionalSource("return " + expected + ";");
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driver(bodyStart, bodyLength, 1, 2, 0, true, 2, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expected, machine.global("instructionFourSecondOperand"));
    assertEquals(1, machine.global("relocationCount"));
  }

  @Test
  void emitsAReversibleResultSlotArtifact() throws Exception {
    assertReversibleArtifact("long", "long value", "value", 1, 1);
  }

  @Test
  void emitsAReversibleImmediateResultRelation() throws Exception {
    assertReversibleArtifact("long", "long value", "value + 8", 1, 1);
  }

  @Test
  void emitsAReversibleTwoSourceResultRelation() throws Exception {
    assertReversibleArtifact("long", "long left, long right", "left + right", 2, 1);
  }

  @Test
  void emitsAReversibleBooleanResultSlotArtifact() throws Exception {
    assertReversibleArtifact("boolean", "boolean value", "value", 1, 2);
  }

  @Test
  void rejectsBooleanArithmeticBeforeArtifactPublication() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public rev boolean recurse(boolean value) {
            return value & true;
          }

          theorem recurseInverse proves inverse(recurse);
        }
        """;
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driverWithEffect(bodyStart, bodyLength, 1, 2, 1, false, 1, 1, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("valid"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  @Test
  void emitsAReversibleLocalCallArtifact() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public rev void recurse() {
            recurse();
          }

          theorem recurseInverse proves inverse(recurse);
        }
        """;
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driverWithEffect(bodyStart, bodyLength, 0, 0, 0, false, 1, 1, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", source), MODULE);
    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("relocationCount"));
    assertArrayEquals(new BytecodeWriter().write(expected), machine.hostOutput());
  }

  @Test
  void emitsReversibleImportedCallProducts() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public rev void recurse() {
            remote();
          }

          theorem recurseInverse proves inverse(recurse);
        }
        """;
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driverWithEffect(bodyStart, bodyLength, 0, 0, 0, true, 0, 0, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    byte[] artifact = machine.hostOutput();
    int functions = sectionStart(artifact, 5);
    int code = sectionStart(artifact, 6);
    int descriptor = functions + 4;
    int forward = code + readU32(artifact, descriptor + 12);
    int inverse = code + readU32(artifact, descriptor + 20);
    assertEquals(Opcode.CALL.code(), readU16(artifact, forward));
    assertEquals(Opcode.UNCALL.code(), readU16(artifact, inverse));
    assertEquals(1, machine.global("relocationCount"));
    assertEquals(1, machine.global("relocationTarget"));
    assertEquals(42, machine.global("relocationIdentityByte"));
  }

  @Test
  void rejectsAnUnimplementedReversibleEffectBeforePublication() throws Exception {
    String source = SOURCE.replace(
        "\n}",
        "\n\n  theorem recurseInverse proves inverse(recurse);\n}");
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driverWithEffect(bodyStart, bodyLength, 1, 1, 0, false, 1, 1, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(RuntimeException.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
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
    assertEquals(1, machine.global("relocationCount"));
    assertEquals(1, machine.global("relocationTarget"));
    assertEquals(0, machine.global("relocationOwner"));
    assertEquals(42, machine.global("relocationIdentityByte"));
    assertEquals(1, machine.global("retainedFunctionCount"));
    assertEquals(2, machine.global("excludedFunctionCount"));
    assertEquals(0, machine.global("resolvedFunctionTarget"));
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

  @Test
  void emitsARootBorrowedWordProjection() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public long recurse(borrow mut words values, long index) {
            long selected = values[index];
            return selected;
          }
        }
        """;

    assertArtifact(source, 2, 10, 1);
  }

  @Test
  void emitsANestedBooleanLiteralCondition() throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public long recurse(boolean value) {
            long cursor = 0;
            while (cursor < 1) limit 1 {
              if (value == false) {
                cursor += 1;
              }

              cursor += 1;
            }

            return cursor;
          }
        }
        """;

    assertArtifact(source, 1, 2, 0);
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

  private static int sectionStart(byte[] artifact, int wantedType) {
    int sectionCount = readU32(artifact, 24);
    for (int section = 0; section < sectionCount; section++) {
      int directory = 40 + section * 32;
      if (readU32(artifact, directory) == wantedType) {
        return Math.toIntExact(readU64(artifact, directory + 8));
      }
    }
    throw new IllegalArgumentException("Missing section " + wantedType);
  }

  private static int readU16(byte[] input, int offset) {
    return input[offset] & 0xff | (input[offset + 1] & 0xff) << 8;
  }

  private static int readU32(byte[] input, int offset) {
    return input[offset] & 0xff
        | (input[offset + 1] & 0xff) << 8
        | (input[offset + 2] & 0xff) << 16
        | (input[offset + 3] & 0xff) << 24;
  }

  private static long readU64(byte[] input, int offset) {
    long value = 0;
    for (int index = 7; index >= 0; index--) {
      value = value << 8 | input[offset + index] & 0xffL;
    }
    return value;
  }

  private static void assertReversibleArtifact(
      String returnType,
      String parameters,
      String result,
      int parameterCount,
      int parameterType) throws Exception {
    String source = """
        module example.structured_call;

        classical class StructuredCall {
          public rev RETURN_TYPE recurse(PARAMETERS) {
            return RESULT;
          }

          theorem recurseInverse proves inverse(recurse);
        }
        """
        .replace("RETURN_TYPE", returnType)
        .replace("PARAMETERS", parameters)
        .replace("RESULT", result);
    int bodyStart = source.indexOf("{", source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = driverWithEffect(
        bodyStart, bodyLength, parameterCount, parameterType, 1, false, 1, 1, 2);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", source), MODULE);
    assertEquals(1, machine.global("valid"));
    assertArrayEquals(new BytecodeWriter().write(expected), machine.hostOutput());
  }

}
