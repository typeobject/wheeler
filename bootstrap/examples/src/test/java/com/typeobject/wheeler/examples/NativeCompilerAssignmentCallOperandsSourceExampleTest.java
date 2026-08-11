package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Focused native evidence for recursive packed assignment-call source decoding. */
final class NativeCompilerAssignmentCallOperandsSourceExampleTest {
  private static final String IDENTITIES =
      "compiler/syntax/calls/assignment/AssignmentCallIdentities.w";
  private static final String ARITIES =
      "compiler/syntax/calls/assignment/AssignmentCallArities.w";
  private static final String OPERANDS =
      "compiler/syntax/calls/assignment/AssignmentCallOperands.w";
  private static final String MODULE = "wheeler.compiler.assignment_call_operands";

  @Test
  void compilesRecursivePackedSourcesByteForByte() throws Exception {
    String identities = CompilerSources.read(IDENTITIES);
    String arities = CompilerSources.read(ARITIES);
    String operands = CompilerSources.read(OPERANDS);
    byte[] artifact = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(),
        List.of(identities, arities),
        operands);
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(IDENTITIES, identities);
    sources.put(ARITIES, arities);
    sources.put(OPERANDS, operands);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(sources, MODULE));

    assertArrayEquals(expected, artifact);
    var decoded = new BytecodeReader().read(artifact);
    assertEquals(
        MODULE + "::packedSource",
        decoded.functions().stream()
            .filter(function -> function.name().endsWith("::packedSource"))
            .findFirst()
            .orElseThrow()
            .name());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
