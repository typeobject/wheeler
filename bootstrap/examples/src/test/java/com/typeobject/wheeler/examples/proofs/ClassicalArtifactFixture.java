package com.typeobject.wheeler.examples.proofs;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Builds independent forward artifacts and counted source claims for native publication. */
final class ClassicalArtifactFixture {
  static final int ARTIFACT_BYTES = 32_768;
  static final int CALLABLES = 64;
  static final int MAX_PROOFS = 64;
  static final int MAX_NAME_BYTES = 256;
  static final int MAX_STRINGS = 256;
  static final int PROOF_COLUMNS = 5;
  static final int PROOF_ROWS = MAX_PROOFS * PROOF_COLUMNS;
  static final int IDENTITY_BYTES = 32;
  static final long SENTINEL = 211;
  private static final int FUNCTION_WORDS = 10;
  private static final int FUNCTION_BYTES = FUNCTION_WORDS * Integer.BYTES;
  private static final int FORWARD_START_WORD = 3;
  private static final int FORWARD_LENGTH_WORD = FORWARD_START_WORD + 1;

  record Fixture(Program expected, byte[] input, Program driver) {
    VirtualMachine machine() {
      return VirtualMachine.withBinaryInput(driver, input, ARTIFACT_BYTES);
    }
  }

  static Fixture fixture(String declarations, boolean reversible, String mutation) throws Exception {
    var compiler = new WheelerCompiler();
    Program expected = compiler.compileLibraryModuleFiles(Map.of("Artifact.w", source(declarations, reversible)),
        "fixture.classical_artifact");
    return fixture(expected, reversible, mutation);
  }

  static Fixture fixture(Program expected, boolean generateInverses, String mutation) throws Exception {
    List<FunctionBody> functions = expected.functions().stream().map(function ->
        generateInverses && function.id() != expected.entryFunctionId()
            ? new FunctionBody(function.id(), function.name(), function.coherent(), function.parameterCount(),
                function.localTypes(), function.resultType(), function.implicitResultSlot(),
                function.forward(), List.of())
            : function).toList();
    Program forward = copy(expected, functions, List.of(), expected.maxSteps());
    byte[] artifact = new BytecodeWriter().write(forward);
    int functionStart = sectionStart(artifact, BytecodeFormat.FUNCTIONS);
    int codeStart = sectionStart(artifact, BytecodeFormat.CODE);
    int callableCount = expected.functions().size() - 1;
    StringBuilder writes = new StringBuilder();
    int codeLength = 0;
    for (int function = 0; function < callableCount; function++) {
      int descriptor = functionStart + Integer.BYTES + function * FUNCTION_BYTES;
      int offset = u32(artifact, descriptor + FORWARD_START_WORD * Integer.BYTES);
      int length = u32(artifact, descriptor + FORWARD_LENGTH_WORD * Integer.BYTES);
      writes.append("set(callables, ").append(function).append(", ").append(offset).append(");\n")
          .append("set(callables, ").append(CALLABLES + function).append(", ").append(length).append(");\n")
          .append("set(callables, ").append(CALLABLES * 2 + function).append(", ")
          .append(functions.get(function).forward().size()).append(");\n");
      codeLength += length;
    }
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(artifact);
    for (ProofCertificate proof : expected.proofCertificates()) {
      byte[] name = proof.name().getBytes(StandardCharsets.UTF_8);
      long[] values = {input.size(), name.length, proof.rule().code(), proof.subjectId(), proof.argument()};
      for (int column = 0; column < PROOF_COLUMNS; column++) {
        writes.append("set(proofs, ").append(column * MAX_PROOFS + proof.id()).append(", ")
            .append(values[column]).append(");\n");
      }
      input.writeBytes(name);
    }
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.classical_source_product_artifact"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.generated_inverse_products"));
    CoreSources.addBinaryClosure(modules);
    modules.put("Sha256.w", Files.readString(Path.of("../wheeler-core/src/main/wheeler/crypto/Sha256.w")));
    modules.put("ArtifactDriver.w", """
        module example.classical_artifact_driver;
        import wheeler.compiler.closure.classical_source_product_artifact;
        import wheeler.compiler.closure.generated_inverse_products;
        import wheeler.compiler.closure.source_classical_proofs;
        import wheeler.compiler.closure.source_product_artifact;
        classical class ArtifactDriver {
          const long ARTIFACT_BYTES = %d;
          const long SENTINEL = %d;
          const long CALLABLES = 64;
          const long CALLABLE_COLUMNS = 5;
          const long INVERSE_COLUMNS = 3;
          const long WORD_BYTES = 8;
          const long CODE_BYTES = 262144;
          const long IDENTITY_BYTES = 32;
          const long FORWARD_BYTES = %d;
          const long ARENA_BYTES = (CALLABLES * (CALLABLE_COLUMNS + INVERSE_COLUMNS)
            + SOURCE_PROOF_ROWS) * WORD_BYTES + FORWARD_BYTES + CODE_BYTES + IDENTITY_BYTES;
          const long WORD_TABLES = 3;
          const long BYTE_TABLES = 3;
          const long ALLOCATIONS = WORD_TABLES + BYTE_TABLES;
          state long prepared = 0;
          state long published = 0;
          state long completed = 0;
          state long artifactLength = -1;
          state long codeStart = -1;
          state long functionCount = -1;
          state long maxLocalCount = -1;
          state long relocationCount = -1;
          entry void main(borrow byteview input, borrow mut bytes output) {
            region arena = new region(ARENA_BYTES, ALLOCATIONS);
            bytes forwardCode = allocateBytes(arena, FORWARD_BYTES);
            words callables = allocate(arena, CALLABLES * CALLABLE_COLUMNS);
            words inverses = allocate(arena, CALLABLES * INVERSE_COLUMNS);
            bytes inverseCode = allocateBytes(arena, CODE_BYTES);
            words proofs = allocate(arena, SOURCE_PROOF_ROWS);
            bytes identity = allocateBytes(arena, IDENTITY_BYTES);
            long copied = 0;
            while (copied < FORWARD_BYTES) limit CODE_BYTES {
              setByte(forwardCode, copied, input[%d + copied]);
              copied += 1;
            }
            long cell = 0;
            while (cell < SOURCE_PROOF_ROWS) limit SOURCE_PROOF_ROWS {
              set(proofs, cell, SENTINEL);
              cell += 1;
            }
            long byteIndex = 0;
            while (byteIndex < ARTIFACT_BYTES) limit ARTIFACT_BYTES {
              setByte(output, byteIndex, SENTINEL);
              byteIndex += 1;
            }
            byteIndex = 0;
            while (byteIndex < IDENTITY_BYTES) limit IDENTITY_BYTES {
              setByte(identity, byteIndex, SENTINEL);
              byteIndex += 1;
            }
            %s
            long claimedCount = %d;
            long generatedCount = %d;
            long artifactBytes = %d;
            if (0 < generatedCount) {
              GeneratedInversePlan inverse = materializeGeneratedInverseCompositionProducts(
                generatedCount, callables, forwardCode, FORWARD_BYTES, inverses, inverseCode
              );
              assert(inverse.valid);
            }
            %s
            prepared = 1;
            SourceProductArtifactPlan artifact = publishClassicalSourceProductArtifact(
              input, artifactBytes, %d, generatedCount, callables, inverses, inverseCode,
              input, claimedCount, proofs, output, identity
            );
            artifactLength = artifact.length;
            codeStart = artifact.codeStart;
            functionCount = artifact.functionCount;
            maxLocalCount = artifact.maxLocalCount;
            relocationCount = artifact.relocationCount;
            published = 1;
            completed = 1;
            setOutputLength(output, artifact.length);
            drop(identity);
            drop(proofs);
            drop(inverseCode);
            drop(inverses);
            drop(callables);
            drop(forwardCode);
            drop(arena);
          }
        }
        """.formatted(ARTIFACT_BYTES, SENTINEL, codeLength, codeStart, writes, expected.proofCertificates().size(),
            generateInverses ? callableCount : 0, artifact.length, mutation, callableCount));
    Program driver = new WheelerCompiler().compileModuleFiles(modules, "example.classical_artifact_driver");
    return new Fixture(expected, input.toByteArray(), driver);
  }

  static Program copy(Program original, List<FunctionBody> functions, List<ProofCertificate> proofs, long steps) {
    return new Program(original.name(), original.kind(), original.entryFunctionId(), original.globals(),
        original.recordTypes(), original.variantTypes(), original.arrayTypes(), original.sliceTypes(), functions,
        proofs, original.quantumRegisters(), original.quantumCircuits(), original.workflow(),
        original.requiredInstructionExtensions(), original.maxHistoryRecords(), steps);
  }

  static String source(String declarations, boolean reversible) {
    String effect = reversible ? "rev " : "";
    return """
        module fixture.classical_artifact;
        classical class MidArtifact {
          state long count = 0;
          record Alpha(long zero) {}
          variant Zed { case High(long payload); }
          %svoid bump() { count += 3; assert(count == 3); }
          %svoid invoke() { bump(); }
          %s
        }
        """.formatted(effect, effect, declarations);
  }

  static int stringCount(Program program) {
    byte[] artifact = new BytecodeWriter().write(program);
    return u32(artifact, sectionStart(artifact, BytecodeFormat.STRINGS));
  }

  static int sectionStart(byte[] artifact, int type) {
    int count = u32(artifact, BytecodeFormat.HEADER_SECTION_COUNT_OFFSET);
    for (int section = 0; section < count; section++) {
      int directory = BytecodeFormat.HEADER_SIZE + section * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
      if (u32(artifact, directory) == type) {
        return Math.toIntExact(ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN).getLong(directory + BytecodeFormat.DIRECTORY_SECTION_OFFSET));
      }
    }
    throw new IllegalArgumentException("Missing section " + type);
  }

  private static int u32(byte[] artifact, int start) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN).getInt(start);
  }
}
