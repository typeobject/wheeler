package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for reversible source-product artifact publication. */
final class NativeCompilerReversibleSourceProductArtifactExampleTest {
  @Test
  void publishesTheStageZeroReversibleArtifactByteForByte() throws Exception {
    WheelerCompiler compiler = new WheelerCompiler();
    Program expectedProgram = compiler.compileLibraryModuleFiles(
        Map.of("InverseArtifact.w", source()), "fixture.inverse_artifact");
    FunctionBody expectedFunction = function(expectedProgram, "bump");
    FunctionBody forwardFunction = new FunctionBody(
        expectedFunction.id(),
        expectedFunction.name(),
        expectedFunction.coherent(),
        expectedFunction.parameterCount(),
        expectedFunction.localTypes(),
        expectedFunction.resultType(),
        expectedFunction.implicitResultSlot(),
        expectedFunction.forward(),
        List.of());
    Program forwardProgram = new Program(
        expectedProgram.name(),
        expectedProgram.entryFunctionId(),
        expectedProgram.globals(),
        expectedProgram.functions().stream()
            .map(function -> function.id() == forwardFunction.id() ? forwardFunction : function)
            .toList());
    byte[] forwardArtifact = new BytecodeWriter().write(forwardProgram);
    byte[] expectedArtifact = new BytecodeWriter().write(expectedProgram);
    CodeRange forwardCode = functionForwardCode(forwardArtifact, forwardFunction.id());
    byte[] proofName = "bumpInverse".getBytes(StandardCharsets.UTF_8);
    byte[] input = Arrays.copyOf(forwardArtifact, forwardArtifact.length + proofName.length);
    System.arraycopy(proofName, 0, input, forwardArtifact.length, proofName.length);
    Program nativeCompiler = program(
        input.length,
        forwardArtifact.length,
        forwardCode.start(),
        forwardCode.length(),
        forwardFunction.forward().size(),
        forwardFunction.id(),
        proofName.length);
    VirtualMachine machine = VirtualMachine.withBinaryInput(nativeCompiler, input, 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expectedArtifact, machine.hostOutput());
    Program published = new BytecodeReader().read(machine.hostOutput());
    FunctionBody publishedFunction = function(published, "bump");
    VirtualMachine executed = new VirtualMachine(published);
    executed.invoke(publishedFunction.id(), false);
    assertEquals(3, executed.global(0));
    executed.establishEffectBoundary();
    executed.invoke(publishedFunction.id(), true);
    assertEquals(0, executed.global(0));
  }

  private static String source() {
    return """
        module fixture.inverse_artifact;

        classical class InverseArtifact {
          state long value = 0;

          rev void bump() {
            value += 3;
            assert(value == 3);
          }

          theorem bumpInverse proves inverse(bump);
        }
        """;
  }

  private static FunctionBody function(Program program, String name) {
    return program.functions().stream()
        .filter(candidate -> candidate.name().endsWith("::" + name))
        .findFirst()
        .orElseThrow();
  }

  private static CodeRange functionForwardCode(byte[] artifact, int function) {
    int functionSection = sectionStart(artifact, 5);
    int codeSection = sectionStart(artifact, 6);
    int descriptor = functionSection + 4 + function * 40;
    return new CodeRange(
        codeSection + readU32(artifact, descriptor + 12),
        readU32(artifact, descriptor + 16));
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

  private static Program program(
      int inputLength,
      int artifactLength,
      int codeStart,
      int codeLength,
      int instructionCount,
      int subject,
      int proofNameLength) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.generated_inverse_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.reversible_source_product_artifact"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("ReversibleSourceProductArtifactExample.w", """
        module example.reversible_source_product_artifact;

        import wheeler.compiler.closure.generated_inverse_products;
        import wheeler.compiler.closure.reversible_source_product_artifact;
        import wheeler.compiler.closure.source_product_artifact;

        classical class ReversibleSourceProductArtifactExample {
          state long published = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(bufferLength(input) == INPUT_LENGTH);
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ 8);
            bytes forwardCode = allocateBytes(arena, /* length= */ CODE_LENGTH);
            words callableRows = allocate(arena, /* length= */ 320);
            words inverseRows = allocate(arena, /* length= */ 192);
            bytes inverseCode = allocateBytes(arena, /* length= */ 262144);
            words proofNameStarts = allocate(arena, /* length= */ 64);
            words proofNameLengths = allocate(arena, /* length= */ 64);
            words proofSubjects = allocate(arena, /* length= */ 64);
            bytes identity = allocateBytes(arena, /* length= */ 32);
            long codeByte = 0;
            while (codeByte < CODE_LENGTH) limit 262144 {
              setByte(forwardCode, codeByte, input[CODE_START + codeByte]);
              codeByte += 1;
            }
            set(callableRows, 0, 0);
            set(callableRows, 64, CODE_LENGTH);
            set(callableRows, 128, INSTRUCTION_COUNT);
            set(proofNameStarts, 0, ARTIFACT_LENGTH);
            set(proofNameLengths, 0, PROOF_NAME_LENGTH);
            set(proofSubjects, 0, SUBJECT);
            GeneratedInversePlan inverse = materializeGeneratedInverseCompositionProducts(
              /* callableCount= */ 1,
              callableRows,
              forwardCode,
              /* forwardCodeLength= */ CODE_LENGTH,
              inverseRows,
              inverseCode
            );
            assert(inverse.valid);
            SourceProductArtifactPlan artifact = publishReversibleVoidSourceProductArtifact(
              input,
              ARTIFACT_LENGTH,
              /* callableCount= */ 1,
              /* ownershipEventCount= */ 0,
              callableRows,
              inverseRows,
              inverseCode,
              input,
              /* proofCount= */ 1,
              proofNameStarts,
              proofNameLengths,
              proofSubjects,
              output,
              identity
            );
            published = 1;
            setOutputLength(output, artifact.length);
            drop(identity);
            drop(proofSubjects);
            drop(proofNameLengths);
            drop(proofNameStarts);
            drop(inverseCode);
            drop(inverseRows);
            drop(callableRows);
            drop(forwardCode);
            drop(arena);
          }
        }
        """
            .replace("INPUT_LENGTH", Integer.toString(inputLength))
            .replace("ARTIFACT_LENGTH", Integer.toString(artifactLength))
            .replace("CODE_START", Integer.toString(codeStart))
            .replace("CODE_LENGTH", Integer.toString(codeLength))
            .replace("INSTRUCTION_COUNT", Integer.toString(instructionCount))
            .replace("SUBJECT", Integer.toString(subject))
            .replace("PROOF_NAME_LENGTH", Integer.toString(proofNameLength))
            .replace("ARENA_BYTES", Integer.toString(267_808 + codeLength)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.reversible_source_product_artifact");
  }

  private record CodeRange(int start, int length) {}
}
