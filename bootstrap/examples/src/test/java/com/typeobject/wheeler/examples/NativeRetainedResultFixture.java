package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;

/** Closed archive signatures and complete caller storage at the compilation boundary. */
final class NativeRetainedResultFixture {
  record Run(VirtualMachine machine, List<BufferValue> callerBuffers, String source) {}

  private static Program program;

  private NativeRetainedResultFixture() {}

  static Run prepare(String result, String body, long retainedResult, int firstCallable)
      throws Exception {
    String source = "module example.results; classical class Results { public " + result
        + " compute(long mod) { " + body + " } }";
    String prefix = "outside café 𝄞\n";
    String archive = prefix + source + "\noutside tail";
    int sourceStart = 64 + prefix.getBytes(StandardCharsets.UTF_8).length;
    int bodyStart = archive.indexOf('{', archive.indexOf("compute("));
    int bodyEnd = SourceRanges.matchingClose(archive, bodyStart) + 1;
    byte[] bytes = archive.getBytes(StandardCharsets.UTF_8);
    byte[] input = ByteBuffer.allocate(64 + bytes.length).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(sourceStart).putLong(source.getBytes(StandardCharsets.UTF_8).length)
        .putLong(firstCallable).putLong(64 + SourceRanges.utf8Offset(archive, bodyStart))
        .putLong(SourceRanges.utf8Length(archive, bodyStart, bodyEnd - bodyStart))
        .putLong(64 + SourceRanges.utf8Offset(archive, archive.indexOf("compute(")))
        .putLong(retainedResult)
        .putLong(64 + SourceRanges.utf8Offset(archive, archive.indexOf("Results {")))
        .put(bytes).array();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32_800);
    while (machine.global("prepared") == 0) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(0, machine.historySize());
    return new Run(machine, machine.snapshot().buffers(), source);
  }

  static synchronized Program program() throws Exception {
    if (program != null) {
      return program;
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("RetainedResults.w", """
        module example.retained_results;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.core.encoding.binary;
        classical class RetainedResults {
          state long prepared = 0;
          state long published = 0;
          state long artifactLength = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            long sourceStart = readSigned(archive, 0);
            long sourceLength = readSigned(archive, 8);
            long firstCallable = readSigned(archive, 16);
            region metadata = new region(1600000, 12);
            words bodyStarts = allocate(metadata, 4096);
            words bodyLengths = allocate(metadata, 4096);
            words importedRows = allocate(metadata, 114689);
            words importedStarts = allocate(metadata, 16384);
            words firstParameters = allocate(metadata, 4096);
            words parameterCounts = allocate(metadata, 4096);
            words resultTypes = allocate(metadata, 4096);
            words effects = allocate(metadata, 4096);
            words parameterTypes = allocate(metadata, 16384);
            words parameterModes = allocate(metadata, 16384);
            words nameStarts = allocate(metadata, 4096);
            words nameLengths = allocate(metadata, 4096);
            set(resultTypes, 0, -17);
            set(bodyStarts, firstCallable, readSigned(archive, 24));
            set(bodyLengths, firstCallable, readSigned(archive, 32));
            set(nameStarts, firstCallable, readSigned(archive, 40));
            set(nameLengths, firstCallable, 7);
            set(firstParameters, firstCallable, 16383);
            set(parameterCounts, firstCallable, 1);
            set(resultTypes, firstCallable, readSigned(archive, 48));
            set(parameterTypes, 16383, 1);
            region publication = new region(32800, 2);
            bytes artifact = allocateBytes(publication, 32768);
            bytes identity = allocateBytes(publication, 32);
            long cell = 0;
            while (cell < 32768) limit 32768 {
              setByte(artifact, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 32) limit 32 {
              setByte(identity, cell, 211);
              cell += 1;
            }
            prepared = 1;
            SourceProductArtifactPlan plan = compileStructuredArchiveModule(
              archive, sourceStart, sourceLength, 511, archive, sourceStart + 7, 15,
              readSigned(archive, 56), 7, firstCallable, 1, bodyStarts, bodyLengths,
              0, importedRows, archive, importedStarts, firstParameters, parameterCounts,
              resultTypes, effects, parameterTypes, parameterModes, archive, nameStarts,
              nameLengths, artifact, identity
            );
            long cursor = 0;
            while (cursor < plan.length) limit 32768 {
              setByte(output, cursor, artifact[cursor]);
              cursor += 1;
            }
            long hashByte = 0;
            while (hashByte < 32) limit 32 {
              setByte(output, cursor + hashByte, identity[hashByte]);
              hashByte += 1;
            }
            setOutputLength(output, cursor + 32);
            artifactLength = plan.length;
            published = 1;
            drop(identity); drop(artifact); drop(publication);
            drop(nameLengths); drop(nameStarts); drop(parameterModes); drop(parameterTypes);
            drop(effects); drop(resultTypes); drop(parameterCounts); drop(firstParameters);
            drop(importedStarts); drop(importedRows); drop(bodyLengths); drop(bodyStarts);
            drop(metadata);
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(sources, "example.retained_results");
    return program;
  }
}
