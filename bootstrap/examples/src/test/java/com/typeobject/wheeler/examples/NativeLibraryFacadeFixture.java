package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;

/** Lends only the physical facade source and its closed empty callable window to Wheeler. */
final class NativeLibraryFacadeFixture {
  static final String MODULE = "wheeler.compiler.library";
  static final String CLASS = "CompilerLibrary";
  static final int ARTIFACT_BYTES = 32_768;
  static final int IDENTITY_BYTES = 32;
  static final int SENTINEL = 211;
  private static final int HEADER_WORDS = 8;
  private static final int HEADER_BYTES = HEADER_WORDS * Long.BYTES;
  private static Program compiler;

  private NativeLibraryFacadeFixture() {}

  static VirtualMachine prepare(int artifactBytes, int identityBytes, boolean outsideName)
      throws Exception {
    String source = CompilerSources.read("CompilerLibrary.w");
    String prefix = "outside café 𝄞 CompilerLibrary\n";
    String suffix = "\nclassical class Outside {}";
    int sourceStart = HEADER_BYTES + prefix.getBytes(StandardCharsets.UTF_8).length;
    int sourceLength = source.getBytes(StandardCharsets.UTF_8).length;
    int moduleStart = sourceStart + SourceRanges.utf8Offset(source, source.indexOf(MODULE + ";"));
    int classStart = sourceStart + SourceRanges.utf8Offset(source, source.indexOf(CLASS + " {}"));
    byte[] sourceBytes = (prefix + source + suffix).getBytes(StandardCharsets.UTF_8);
    byte[] input = ByteBuffer.allocate(HEADER_BYTES + sourceBytes.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putLong(sourceStart).putLong(sourceLength)
        .putLong(moduleStart).putLong(MODULE.length())
        .putLong(outsideName ? HEADER_BYTES : classStart).putLong(CLASS.length())
        .putLong(artifactBytes).putLong(identityBytes).put(sourceBytes).array();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        compiler(), input, ARTIFACT_BYTES + IDENTITY_BYTES);
    while (machine.global("prepared") == 0) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(0, machine.historySize());
    return machine;
  }

  private static synchronized Program compiler() throws Exception {
    if (compiler != null) {
      return compiler;
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("FacadeProduct.w", """
        module example.facade_product;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.core.encoding.binary;
        classical class FacadeProduct {
          private const long WORD_BYTES = 8;
          private const long CALLABLE_ROWS = 4096;
          private const long SCALAR_ROWS = 16384;
          private const long PARAMETER_ROWS = 16384;
          private const long IMPORT_HEADER_ROWS = 1;
          private const long IMPORT_COLUMNS = 7;
          private const long IMPORT_ROWS = IMPORT_HEADER_ROWS + IMPORT_COLUMNS * SCALAR_ROWS;
          private const long CALLABLE_COLUMNS = 8;
          private const long PARAMETER_COLUMNS = 2;
          private const long METADATA_ROWS = CALLABLE_COLUMNS * CALLABLE_ROWS + IMPORT_ROWS
            + SCALAR_ROWS + PARAMETER_COLUMNS * PARAMETER_ROWS;
          private const long METADATA_BYTES = METADATA_ROWS * WORD_BYTES;
          private const long METADATA_BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS + 2;
          private const long ARTIFACT_BYTES = 32768;
          private const long IDENTITY_BYTES = 32;
          private const long PUBLICATION_BUFFERS = 2;
          private const long FIRST_EXCESS_BYTES = 1;
          private const long PUBLICATION_BYTES = ARTIFACT_BYTES + IDENTITY_BYTES
            + PUBLICATION_BUFFERS * FIRST_EXCESS_BYTES;
          private const long SENTINEL = 211;
          state long prepared = 0;
          state long published = 0;
          state long artifactLength = 0;
          state long functionCount = 0;
          state long maxLocalCount = 0;
          state long relocationCount = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            long sourceStart = readSigned(archive, 0 * WORD_BYTES);
            long sourceLength = readSigned(archive, 1 * WORD_BYTES);
            long moduleStart = readSigned(archive, 2 * WORD_BYTES);
            long moduleLength = readSigned(archive, 3 * WORD_BYTES);
            long classStart = readSigned(archive, 4 * WORD_BYTES);
            long classLength = readSigned(archive, 5 * WORD_BYTES);
            long artifactBytes = readSigned(archive, 6 * WORD_BYTES);
            long identityBytes = readSigned(archive, 7 * WORD_BYTES);
            region metadata = new region(METADATA_BYTES, METADATA_BUFFERS);
            words bodyStarts = allocate(metadata, CALLABLE_ROWS);
            words bodyLengths = allocate(metadata, CALLABLE_ROWS);
            words importedRows = allocate(metadata, IMPORT_ROWS);
            words importedStarts = allocate(metadata, SCALAR_ROWS);
            words firstParameters = allocate(metadata, CALLABLE_ROWS);
            words parameterCounts = allocate(metadata, CALLABLE_ROWS);
            words resultTypes = allocate(metadata, CALLABLE_ROWS);
            words effects = allocate(metadata, CALLABLE_ROWS);
            words parameterTypes = allocate(metadata, PARAMETER_ROWS);
            words parameterModes = allocate(metadata, PARAMETER_ROWS);
            words nameStarts = allocate(metadata, CALLABLE_ROWS);
            words nameLengths = allocate(metadata, CALLABLE_ROWS);
            region publication = new region(PUBLICATION_BYTES, PUBLICATION_BUFFERS);
            bytes artifact = allocateBytes(publication, artifactBytes);
            bytes identity = allocateBytes(publication, identityBytes);
            long cell = 0;
            while (cell < artifactBytes) limit ARTIFACT_BYTES + 1 {
              setByte(artifact, cell, SENTINEL);
              cell += 1;
            }
            cell = 0;
            while (cell < identityBytes) limit IDENTITY_BYTES + 1 {
              setByte(identity, cell, SENTINEL);
              cell += 1;
            }
            prepared = 1;
            SourceProductArtifactPlan plan = compileStructuredArchiveModule(
              archive, sourceStart, sourceLength, /* moduleOwner= */ 0,
              archive, moduleStart, moduleLength, classStart, classLength,
              /* firstCallable= */ 0, /* callableCount= */ 0, bodyStarts, bodyLengths,
              /* importedCount= */ 0, importedRows, archive, importedStarts,
              firstParameters, parameterCounts, resultTypes, effects,
              parameterTypes, parameterModes, archive, nameStarts, nameLengths,
              artifact, identity
            );
            artifactLength = plan.length;
            functionCount = plan.functionCount;
            maxLocalCount = plan.maxLocalCount;
            relocationCount = plan.relocationCount;
            published = 1;
            long cursor = 0;
            while (cursor < plan.length) limit ARTIFACT_BYTES {
              setByte(output, cursor, artifact[cursor]);
              cursor += 1;
            }
            cell = 0;
            while (cell < IDENTITY_BYTES) limit IDENTITY_BYTES {
              setByte(output, cursor + cell, identity[cell]);
              cell += 1;
            }
            setOutputLength(output, plan.length + IDENTITY_BYTES);
            drop(identity);
            drop(artifact);
            drop(publication);
            drop(nameLengths);
            drop(nameStarts);
            drop(parameterModes);
            drop(parameterTypes);
            drop(effects);
            drop(resultTypes);
            drop(parameterCounts);
            drop(firstParameters);
            drop(importedStarts);
            drop(importedRows);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(metadata);
          }
        }
        """);
    compiler = new WheelerCompiler().compileModuleFiles(sources, "example.facade_product");
    return compiler;
  }
}
