package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

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
          assert(-1 < length);
          long index = 0;
          while (index < length) limit MAX_SOURCE_BYTES {
            long kind = rows[512 + index];
            boolean one = kind == 1;
            assert(-1 < kind);
            assert(index < length);
            assert(one);
            setByte(output, index, source[sourceStart + index]);
            index += 1;
          }

          return length;
        }
      }
      """;

  @Test
  void emitsStructuredComparisonAndIndexedCopyProducts() throws Exception {
    assertArtifact(SOURCE);
  }

  @Test
  void emitsBinaryReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    return length;\n",
        "    return length + sourceStart;\n"));
  }

  @Test
  void emitsConstantReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    return length;\n",
        "    return MAX_SOURCE_BYTES;\n"));
  }

  @Test
  void emitsSignedLiteralReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    return length;\n",
        "    return -1;\n"));
  }

  @Test
  void emitsBooleanLiteralReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    return length;\n",
            "    return true;\n"));
    assertArtifact(SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    return length;\n",
            "    return false;\n"));
  }

  @Test
  void rejectsMalformedBooleanLiteralReturnProducts() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    return length;\n",
            "    return true false;\n"));
  }

  @Test
  void emitsEqualityReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    return length;\n",
            "    return length == sourceStart;\n"));
  }

  @Test
  void emitsLessThanReturnProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    return length;\n",
            "    return length < sourceStart;\n"));
  }

  @Test
  void rejectsMalformedBinaryReturnProducts() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    return length;\n",
        "    return length +;\n"));
  }

  @Test
  void emitsBinaryDeclarationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long combined = length + sourceStart;\n"
            + "    long index = 0;\n"));
  }

  @Test
  void emitsBooleanComparisonDeclarationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    boolean before = length < sourceStart;\n"
            + "    assert(before);\n"
            + "    long index = 0;\n"));
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    boolean same = length == sourceStart;\n"
            + "    assert(same);\n"
            + "    long index = 0;\n"));
  }

  @Test
  void emitsBooleanEqualityDeclarationProducts() throws Exception {
    String declaration = SOURCE.replace(
        "    borrow mut bytes output\n",
        "    borrow mut bytes output,\n"
            + "    boolean result\n").replace(
                "    long index = 0;\n",
                "    boolean same = result == result;\n"
                    + "    assert(same);\n"
                    + "    long index = 0;\n");

    assertArtifact(declaration);
  }

  @Test
  void emitsBooleanLiteralDeclarationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    boolean before = true;\n"
            + "    assert(before);\n"
            + "    long index = 0;\n"));
  }

  @Test
  void emitsBooleanSourceDeclarationProducts() throws Exception {
    String declaration = SOURCE.replace(
        "    borrow mut bytes output\n",
        "    borrow mut bytes output,\n"
            + "    boolean result\n").replace(
                "    long index = 0;\n",
                "    boolean before = result;\n"
                    + "    assert(before);\n"
                    + "    long index = 0;\n");

    assertArtifact(declaration);
  }

  @Test
  void rejectsSignedBooleanDeclarationProducts() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    boolean before = length + sourceStart;\n"
            + "    long index = 0;\n"));
  }

  @Test
  void emitsImportedConstantDeclarationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long combined = length & MAX_SOURCE_BYTES;\n"
            + "    long index = 0;\n"));
  }

  @Test
  void constantProductShadowsLocalDeclaration() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long MAX_SOURCE_BYTES = length;\n"
            + "    long combined = sourceStart + MAX_SOURCE_BYTES;\n"
            + "    long index = 0;\n").replace(
                "limit MAX_SOURCE_BYTES",
                "limit 32768"));
  }

  @Test
  void emitsRootByteMutationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    while (index < length) limit MAX_SOURCE_BYTES {\n",
        "    setByte(output, index, length);\n"
            + "    while (index < length) limit MAX_SOURCE_BYTES {\n"));
  }

  @Test
  void emitsRootWordMutationProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    while (index < length) limit MAX_SOURCE_BYTES {\n",
        "    set(rows, index, length);\n"
            + "    while (index < length) limit MAX_SOURCE_BYTES {\n"));
  }

  @Test
  void rejectsRootWordMutationWithByteOwner() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    while (index < length) limit MAX_SOURCE_BYTES {\n",
        "    set(output, index, length);\n"
            + "    while (index < length) limit MAX_SOURCE_BYTES {\n"));
  }

  @Test
  void emitsRootByteProjectionProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long projected = source[sourceStart];\n"
            + "    long index = 0;\n"));
  }

  @Test
  void rejectsMalformedRootByteProjectionProducts() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long projected = source[sourceStart] + length;\n"
            + "    long index = 0;\n"));
  }

  @Test
  void emitsRootWordProjectionProducts() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long projected = rows[sourceStart];\n"
            + "    long index = 0;\n"));
  }

  @Test
  void rejectsNonSignedRootProjectionIndexes() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    long index = 0;\n",
        "    long projected = source[output];\n"
            + "    long index = 0;\n"));
  }

  @Test
  void rejectsMalformedRootByteMutationProducts() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "    while (index < length) limit MAX_SOURCE_BYTES {\n",
        "    setByte(output, index, length, index);\n"
            + "    while (index < length) limit MAX_SOURCE_BYTES {\n"));
  }

  @Test
  void emitsABooleanReturnSlot() throws Exception {
    String booleanReturn = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    borrow mut bytes output\n",
            "    borrow mut bytes output,\n"
                + "    boolean result\n").replace(
                    "    return length;\n",
                    "    return result;\n");

    assertTrue(booleanReturn.contains("public boolean copyOffset("));
    assertArtifact(booleanReturn);
  }

  @Test
  void emitsBooleanEqualityReturnProducts() throws Exception {
    String booleanReturn = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    borrow mut bytes output\n",
            "    borrow mut bytes output,\n"
                + "    boolean result\n").replace(
                    "    return length;\n",
                    "    return result == result;\n");

    assertArtifact(booleanReturn);
  }

  @Test
  void emitsBooleanXorReturnProducts() throws Exception {
    String booleanReturn = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    borrow mut bytes output\n",
            "    borrow mut bytes output,\n"
                + "    boolean result\n").replace(
                    "    return length;\n",
                    "    return result ^ result;\n");

    assertArtifact(booleanReturn);
  }

  @Test
  void rejectsMixedBooleanEqualityReturnProducts() throws Exception {
    String booleanReturn = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    borrow mut bytes output\n",
            "    borrow mut bytes output,\n"
                + "    boolean result\n").replace(
                    "    return length;\n",
                    "    return result == length;\n");

    assertNoArtifact(booleanReturn);
  }

  @Test
  void rejectsBooleanLessThanReturnProducts() throws Exception {
    String booleanReturn = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    borrow mut bytes output\n",
            "    borrow mut bytes output,\n"
                + "    boolean result\n").replace(
                    "    return length;\n",
                    "    return result < result;\n");

    assertNoArtifact(booleanReturn);
  }

  @Test
  void emitsAnImplicitVoidReturn() throws Exception {
    String voidReturn = SOURCE.replace(
        "public long copyOffset(",
        "public void copyOffset(").replace(
            "    return length;\n",
            "");

    assertTrue(voidReturn.contains("public void copyOffset("));
    assertArtifact(voidReturn);
  }

  @Test
  void rejectsUnsupportedDirectReturnTypesBeforePublication() throws Exception {
    String byteViewReturn = SOURCE.replace(
        "public long copyOffset(",
        "public byteview copyOffset(").replace(
            "    return length;\n",
            "    return source;\n");

    assertTrue(byteViewReturn.contains("public byteview copyOffset("));
    assertNoArtifact(byteViewReturn);
  }

  @Test
  void emitsOneArmRootConditionalReturnProducts() throws Exception {
    String conditional = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    long index = 0;\n",
            "    if (length < sourceStart) {\n"
                + "      return false;\n"
                + "    }\n\n"
                + "    long index = 0;\n").replace(
                    "    return length;\n",
                    "    return length < sourceStart;\n");

    assertArtifact(conditional);
  }

  @Test
  void emitsSignedThenBooleanConditionalAdmissionProducts() throws Exception {
    String conditional = SOURCE.replace(
        "    assert(-1 < length);\n",
        "    if (length < 0) {\n"
            + "      return 1;\n"
            + "    }\n"
            + "    boolean same = length == 0;\n"
            + "    if (same == false) {\n"
            + "      return 0;\n"
            + "    }\n");

    assertArtifact(conditional);
  }

  @Test
  void rejectsMultipleConditionalReturnChildren() throws Exception {
    String malformed = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    long index = 0;\n",
            "    if (length < sourceStart) {\n"
                + "      assert(length < sourceStart);\n"
                + "      return false;\n"
                + "    }\n\n"
                + "    long index = 0;\n").replace(
                    "    return length;\n",
                    "    return length < sourceStart;\n");

    assertNoArtifact(malformed);
  }

  @Test
  void rejectsComparisonConditionalReturns() throws Exception {
    String malformed = SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    long index = 0;\n",
            "    if (length < sourceStart) {\n"
                + "      return length < sourceStart;\n"
                + "    }\n\n"
                + "    long index = 0;\n").replace(
                    "    return length;\n",
                    "    return length < sourceStart;\n");

    assertNoArtifact(malformed);
  }

  @Test
  void emitsComputedConditionalReturnProducts() throws Exception {
    String conditional = SOURCE.replace(
        "    long index = 0;\n",
        "    if (length < sourceStart) {\n"
            + "      return length - sourceStart;\n"
            + "    }\n\n"
            + "    long index = 0;\n");

    assertArtifact(conditional);
  }

  @Test
  void emitsPreservedConditionalReturnProducts() throws Exception {
    String conditional = SOURCE.replace(
        "    long index = 0;\n",
        "    if (length < sourceStart) {\n"
            + "      return length;\n"
            + "    }\n\n"
            + "    long index = 0;\n");

    assertArtifact(conditional);
  }

  @Test
  void emitsConstantConditionalReturnProducts() throws Exception {
    String conditional = SOURCE.replace(
        "    long index = 0;\n",
        "    if (length < sourceStart) {\n"
            + "      return MAX_SOURCE_BYTES;\n"
            + "    }\n\n"
            + "    long index = 0;\n");

    assertArtifact(conditional);
  }

  @Test
  void emitsSignedLiteralConditionalReturnProducts() throws Exception {
    String conditional = SOURCE.replace(
        "    long index = 0;\n",
        "    if (length < sourceStart) {\n"
            + "      return -1;\n"
            + "    }\n\n"
            + "    long index = 0;\n");

    assertArtifact(conditional);
  }

  @Test
  void emitsUtf8ProjectionDeclarationsInsideALoop() throws Exception {
    String projections = utf8LoopProjectionSource();
    assertArtifact(projections);
    assertArtifact(projections.replace(
        "long width = utf8Width(source, index);",
        "long secondIndex = index + sourceStart;\n"
            + "      long width = utf8Scalar(source, secondIndex);"));
  }

  @Test
  void emitsArithmeticDeclarationsInsideALoop() throws Exception {
    assertArtifact(arithmeticLoopDeclarationSource());
  }

  @Test
  void rejectsUnsupportedArithmeticLoopDeclarationSources() throws Exception {
    assertNoArtifact(arithmeticLoopDeclarationSource().replace(
        "index * 31",
        "index * kind"));
    assertNoArtifact(arithmeticLoopDeclarationSource().replace(
        "product + kind",
        "product + 1"));
    assertNoArtifact(arithmeticLoopDeclarationSource().replace(
        "index * 31",
        "index - 1"));
    assertNoArtifact(arithmeticLoopDeclarationSource().replace(
        "product + kind",
        "product - kind"));
  }

  @Test
  void rejectsMalformedUtf8LoopProjectionSources() throws Exception {
    assertNoArtifact(utf8LoopProjectionSource().replace(
        "borrow utf8 source,",
        "borrow byteview source,"));
    assertNoArtifact(utf8LoopProjectionSource().replace(
        "utf8Width(source, index)",
        "utf8Width(source, 0)"));
  }

  @Test
  void emitsLocalRightGuardsWithBooleanLiteralAssignment() throws Exception {
    String lessThan = localRightGuardSource();
    assertArtifact(lessThan);
    assertArtifact(lessThan.replace(
        "if (index < sourceStart)",
        "if (index == sourceStart)"));
    assertArtifact(lessThan.replace(
        "if (index < sourceStart)",
        "if (index == 0)"));
  }

  @Test
  void rejectsNonSignedLocalRightGuard() throws Exception {
    assertNoArtifact(localRightGuardSource().replace(
        "if (index < sourceStart)",
        "if (index < same)"));
  }

  @Test
  void emitsReverseUtf8ComparisonLoop() throws Exception {
    assertArtifact(SOURCE.replace(
        "    long index = 0;\n"
            + "    while (index < length) limit MAX_SOURCE_BYTES {\n"
            + "      long kind = rows[512 + index];\n"
            + "      boolean one = kind == 1;\n"
            + "      assert(-1 < kind);\n"
            + "      assert(index < length);\n"
            + "      assert(one);\n"
            + "      setByte(output, index, source[sourceStart + index]);\n"
            + "      index += 1;\n"
            + "    }\n",
        "    long comparison = 0;\n"
            + "    long offset = 0;\n"
            + "    long reverse = length;\n"
            + "    while (offset < length) limit MAX_SOURCE_BYTES {\n"
            + "      reverse -= 1;\n"
            + "      long leftIndex = sourceStart + reverse;\n"
            + "      long rightIndex = sourceStart + offset;\n"
            + "      long leftScalar = utf8Scalar(source, leftIndex);\n"
            + "      long rightScalar = utf8Scalar(source, rightIndex);\n"
            + "      if (leftScalar < rightScalar) {\n"
            + "        comparison = -1;\n"
            + "      }\n\n"
            + "      if (rightScalar < leftScalar) {\n"
            + "        comparison = 1;\n"
            + "      }\n\n"
            + "      offset += 1;\n"
            + "    }\n").replace(
                "borrow byteview source,",
                "borrow utf8 source,").replace(
                    "    return length;\n",
                    "    return comparison;\n"));
  }

  @Test
  void emitsNegativeSignedAssignmentInsideALoopGuard() throws Exception {
    String assignment = SOURCE.replace(
        "    long index = 0;\n",
        "    long selected = 0;\n"
            + "    long index = 0;\n").replace(
                "      long kind = rows[512 + index];\n",
                "      if (index < sourceStart) {\n"
                    + "        selected = -1;\n"
                    + "      }\n\n"
                    + "      long kind = rows[512 + index];\n").replace(
                        "    return length;\n",
                        "    return selected;\n");

    assertArtifact(assignment);
  }

  @Test
  void emitsOneNestedLoopInsideTheStructuredWindow() throws Exception {
    String nested = SOURCE.replace(
        "      setByte(output, index, source[sourceStart + index]);\n",
        "      long copyIndex = 0;\n"
            + "      while (copyIndex < 1) limit 5 {\n"
            + "        setByte(output, index, source[sourceStart + index]);\n"
            + "        copyIndex += 1;\n"
            + "      }\n");

    assertTrue(nested.contains("while (copyIndex < 1)"));
    assertArtifact(nested);
  }

  @Test
  void emitsANestedFirstRootFollowedByASequentialRoot() throws Exception {
    String sequential = SOURCE.replace(
        "      setByte(output, index, source[sourceStart + index]);\n",
        "      long copyIndex = 0;\n"
            + "      while (copyIndex < 1) limit 5 {\n"
            + "        copyIndex += 1;\n"
            + "      }\n").replace(
                "    return length;\n",
                "    long second = 0;\n"
                    + "    while (second < 1) limit 5 {\n"
                    + "      second += 1;\n"
                    + "    }\n"
                    + "    assert(second == 1);\n"
                    + "    return length;\n");

    assertTrue(sequential.contains("while (copyIndex < 1)"));
    assertTrue(sequential.contains("while (second < 1)"));
    assertArtifact(sequential);
  }

  @Test
  void fifthNestedLoopPublishesNoArtifact() throws Exception {
    String tooDeep = SOURCE.replace(
        "      setByte(output, index, source[sourceStart + index]);\n",
        "      long a = 0;\n"
            + "      while (a < 1) limit 5 {\n"
            + "        long b = 0;\n"
            + "        while (b < 1) limit 5 {\n"
            + "          long c = 0;\n"
            + "          while (c < 1) limit 5 {\n"
            + "            long d = 0;\n"
            + "            while (d < 1) limit 5 {\n"
            + "              setByte(output, index, source[sourceStart + index]);\n"
            + "              d += 1;\n"
            + "            }\n"
            + "            c += 1;\n"
            + "          }\n"
            + "          b += 1;\n"
            + "        }\n"
            + "        a += 1;\n"
            + "      }\n");

    assertTrue(tooDeep.contains("while (d < 1)"));
    assertNoArtifact(tooDeep);
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

  @Test
  void mutableByteSumReadPublishesNoArtifact() throws Exception {
    assertNoArtifact(SOURCE.replace(
        "source[sourceStart + index]", "output[sourceStart + index]"));
  }

  private static void assertArtifact(String source) throws Exception {
    int body = source.indexOf("{", source.indexOf("copyOffset("));
    int parameterCount = source.contains("boolean result") ? 6 : 5;
    int sourceType = source.contains("borrow utf8 source") ? 8 : 13;
    Program driver = driver(
        body,
        matchingClose(source, body) - body + 1,
        parameterCount,
        sourceType);
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
              + " nearby=" + function.forward().subList(start, end)
              + " plan=" + machine.snapshot().records().getLast(),
          exception);
    }

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredComparison.w", source), MODULE);
    byte[] expectedBytes = new BytecodeWriter().write(expected);
    assertEquals(1, machine.global("valid"));
    assertEquals(expectedBytes.length, machine.global("artifactLength"));
    assertArrayEquals(expectedBytes, machine.hostOutput());
  }

  private static void assertNoArtifact(String source) throws Exception {
    int body = source.indexOf("{", source.indexOf("copyOffset("));
    int parameterCount = source.contains("boolean result") ? 6 : 5;
    int sourceType = source.contains("borrow utf8 source") ? 8 : 13;
    Program driver = driver(
        body,
        matchingClose(source, body) - body + 1,
        parameterCount,
        sourceType);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("artifactLength"));
  }

  private static String utf8LoopProjectionSource() {
    return SOURCE.replace(
        "borrow byteview source,",
        "borrow utf8 source,").replace(
            "      long kind = rows[512 + index];\n",
            "      long scalar = utf8Scalar(source, index);\n"
                + "      long width = utf8Width(source, index);\n"
                + "      long kind = rows[512 + index];\n").replace(
                    "      assert(-1 < kind);\n",
                    "      assert(-1 < kind);\n"
                        + "      assert(0 < width);\n").replace(
                            "      setByte(output, index, source[sourceStart + index]);\n",
                            "      setByte(output, index, scalar);\n");
  }

  private static String arithmeticLoopDeclarationSource() {
    return SOURCE.replace(
        "      long kind = rows[512 + index];\n",
        "      long kind = rows[512 + index];\n"
            + "      long product = index * 31;\n"
            + "      long nextHash = product + kind;\n").replace(
                "      assert(-1 < kind);\n",
                "      assert(-1 < kind);\n"
                    + "      assert(-1 < nextHash);\n");
  }

  private static String localRightGuardSource() {
    return SOURCE.replace(
        "public long copyOffset(",
        "public boolean copyOffset(").replace(
            "    long index = 0;\n",
            "    boolean same = true;\n"
                + "    long index = 0;\n").replace(
                    "      long kind = rows[512 + index];\n",
                    "      if (index < sourceStart) {\n"
                        + "        same = false;\n"
                        + "      }\n\n"
                        + "      long kind = rows[512 + index];\n").replace(
                            "    return length;\n",
                            "    return same;\n");
  }

  private static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int sourceType) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.local_structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("StructuredComparisonSourceProductExample.w", """
        module example.structured_comparison_source_product;

        import wheeler.compiler.closure.local_structured_source_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
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
            writeAscii(strings, 128, "MAX_SOURCE_BYTES");
            set(symbolStarts, 0, 128);
            set(symbolLengths, 0, 16);
            set(symbolTypes, 0, 1);
            set(symbolValues, 0, 32768);
            set(symbolResolved, 0, 1);
            set(signatureTypes, 0, 0);
            set(signatureTypes, 4096, 0);
            set(signatureTypes, 8192, %d);
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
            set(signatureTypes, 5, 0);
            set(signatureTypes, 4101, 5);
            set(signatureTypes, 8197, 2);
            set(parameterCounts, 0, %d);
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
              /* symbolNames= */ strings,
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
              /* signatureTypeCount= */ %d,
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
        """.formatted(
            bodyStart,
            bodyLength,
            sourceType,
            parameterCount,
            parameterCount));
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
