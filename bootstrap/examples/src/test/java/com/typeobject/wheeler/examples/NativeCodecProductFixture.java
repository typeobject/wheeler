package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Compiles the physical codec against closed signatures, never dependency source. */
final class NativeCodecProductFixture {
  static final String MODULE = "wheeler.compiler.codec";
  static final String FUNCTION = MODULE + "::reencodeArtifact";
  static final String TARGET = "wheeler.compiler.verifier::verifyArtifact";

  record Run(VirtualMachine machine, List<BufferValue> caller) {}

  private NativeCodecProductFixture() {}

  static Map<String, String> referenceSources() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    CoreSources.addBinaryClosure(sources);
    return sources;
  }

  static Run prepare() throws Exception {
    String source = CompilerSources.read("compiler/verification/Codec.w");
    assertEquals(List.of("wheeler.compiler.verifier"),
        SourceModuleInspection.inspect(source.getBytes(StandardCharsets.UTF_8)).imports());
    String suffix = "\nwheeler.compiler.verifier\nverifyArtifact";
    byte[] input = (source + suffix).getBytes(StandardCharsets.UTF_8);
    int bytes = source.getBytes(StandardCharsets.UTF_8).length;
    int body = source.indexOf('{', source.indexOf("reencodeArtifact("));
    int bodyEnd = SourceRanges.matchingClose(source, body) + 1;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_structured_archive_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    var coordinates = Map.of(
        "BODY_START", SourceRanges.utf8Offset(source, body),
        "BODY_LENGTH", SourceRanges.utf8Length(source, body, bodyEnd - body),
        "NAME_START", SourceRanges.utf8Offset(source, source.indexOf("reencodeArtifact(")),
        "MODULE_START", SourceRanges.utf8Offset(source, source.indexOf(MODULE + ";")),
        "CLASS_START", SourceRanges.utf8Offset(source, source.indexOf("BytecodeCodec {")),
        "IMPORT_MODULE_START", bytes + 1,
        "IMPORT_NAME_START", bytes + 27,
        "SOURCE_LENGTH", bytes);
    String driver = driver();
    for (String key : coordinates.keySet().stream()
        .sorted(Comparator.comparingInt(String::length).reversed()).toList()) {
      driver = driver.replace(key, Integer.toString(coordinates.get(key)));
    }
    sources.put("CodecProduct.w", driver);
    Program program = new WheelerCompiler().compileModuleFiles(sources, "example.codec_product");
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, input, 32_817);
    while (machine.global("prepared") == 0) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(0, machine.historySize());
    return new Run(machine, machine.snapshot().buffers().stream()
        .filter(buffer -> !buffer.dropped()).toList());
  }

  private static String driver() {
    return """
        module example.codec_product;
        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.imported_structured_archive_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        classical class CodecProduct {
          state long prepared = 0;
          state long published = 0;
          state long artifactLength = 0;
          state long relocationCount = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            region columns = new region(/* bytes= */ 2056232, /* allocations= */ 26);
            words bodyStarts = allocate(columns, 4096);
            words bodyLengths = allocate(columns, 4096);
            words importedRows = allocate(columns, 114689);
            words importedStarts = allocate(columns, 16384);
            words dependencies = allocate(columns, 8192);
            words firstParameters = allocate(columns, 4096);
            words parameterCounts = allocate(columns, 4096);
            words resultTypes = allocate(columns, 4096);
            words effects = allocate(columns, 4096);
            words parameterTypes = allocate(columns, 16384);
            words parameterModes = allocate(columns, 16384);
            words nameStarts = allocate(columns, 4096);
            words nameLengths = allocate(columns, 4096);
            bytes identities = allocateBytes(columns, 131072);
            words owners = allocate(columns, 4096);
            words moduleStarts = allocate(columns, 512);
            words moduleLengths = allocate(columns, 512);
            words hashSlots = allocate(columns, 8192);
            words hashFunctions = allocate(columns, 8192);
            words functionRows = allocate(columns, 4096);
            words publishedRows = allocate(columns, 4096);
            words relocations = allocate(columns, 768);
            words relocationOwners = allocate(columns, 256);
            bytes relocationIdentities = allocateBytes(columns, 8192);
            bytes artifact = allocateBytes(columns, 32768);
            bytes identity = allocateBytes(columns, 32);
            set(bodyStarts, 0, BODY_START);
            set(bodyLengths, 0, BODY_LENGTH);
            set(dependencies, 0, 0);
            set(dependencies, 4096, 1);
            set(firstParameters, 0, 0);
            set(firstParameters, 1, 2);
            set(parameterCounts, 0, 2);
            set(parameterCounts, 1, 2);
            set(resultTypes, 0, 1);
            set(resultTypes, 1, 1);
            set(parameterTypes, 0, 13);
            set(parameterTypes, 1, 5);
            set(parameterTypes, 2, 13);
            set(parameterTypes, 3, 1);
            set(parameterModes, 0, 1);
            set(parameterModes, 1, 2);
            set(parameterModes, 2, 1);
            set(nameStarts, 0, NAME_START);
            set(nameStarts, 1, IMPORT_NAME_START);
            set(nameLengths, 0, 16);
            set(nameLengths, 1, 14);
            setByte(identities, 0, 31);
            setByte(identities, 32, 47);
            set(owners, 0, 1);
            set(owners, 1, 0);
            set(moduleStarts, 0, IMPORT_MODULE_START);
            set(moduleStarts, 1, MODULE_START);
            set(moduleLengths, 0, 25);
            set(moduleLengths, 1, 22);
            mapCallableFunctionRows(2, identities, 2, identities, hashSlots, hashFunctions,
              functionRows, publishedRows);
            long cell = 0;
            while (cell < 32768) limit 32768 {
              setByte(artifact, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 8192) limit 8192 {
              setByte(relocationIdentities, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 768) limit 768 {
              set(relocations, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 256) limit 256 {
              set(relocationOwners, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 32) limit 32 {
              setByte(identity, cell, 211);
              cell += 1;
            }
            prepared = 1;
            SourceProductArtifactPlan plan = compileStructuredArchiveModuleWithImportedTargets(
              archive, 0, SOURCE_LENGTH, 1, CLASS_START, 13, 0, 1, bodyStarts, bodyLengths,
              0, importedRows, archive, importedStarts, 1, dependencies, firstParameters,
              parameterCounts, resultTypes, effects, parameterTypes, parameterModes,
              archive, nameStarts, nameLengths, identities, owners, archive,
              moduleStarts, moduleLengths, 2, identities, hashSlots, hashFunctions,
              relocations, relocationOwners, relocationIdentities, artifact, identity
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
            setOutputLength(output, plan.length + 32);
            artifactLength = plan.length;
            relocationCount = plan.relocationCount;
            published = 1;
            drop(identity); drop(artifact); drop(relocationIdentities);
            drop(relocationOwners); drop(relocations); drop(publishedRows); drop(functionRows);
            drop(hashFunctions); drop(hashSlots);
            drop(moduleLengths); drop(moduleStarts); drop(owners); drop(identities);
            drop(nameLengths); drop(nameStarts); drop(parameterModes); drop(parameterTypes);
            drop(effects); drop(resultTypes); drop(parameterCounts); drop(firstParameters);
            drop(dependencies); drop(importedStarts); drop(importedRows);
            drop(bodyLengths); drop(bodyStarts); drop(columns);
          }
        }
        """;
  }
}
