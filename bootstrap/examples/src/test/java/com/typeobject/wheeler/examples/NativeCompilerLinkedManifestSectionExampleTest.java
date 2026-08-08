package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for linked root manifests and function name products. */
final class NativeCompilerLinkedManifestSectionExampleTest {
  @Test
  void resolvesRootEntryAndFunctionNames() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(functionCount(artifact)), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expectedManifest(artifact), machine.hostOutput());
    assertEquals(functionName(artifact, 0), machine.global("firstName"));
    assertEquals(functionName(artifact, 1), machine.global("secondName"));
  }

  @Test
  void rejectsOutOfRangeFunctionNamesBeforePublication() throws Exception {
    byte[] artifact = artifact();
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    bytes.putInt(sectionStart(artifact, 5) + 8, stringCount(artifact));
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(functionCount(artifact)), artifact, 1_048_576);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] artifact() {
    String source = """
        module fixture.linked_manifest;

        classical class LinkedManifest {
          public long helper(long value) {
            return value;
          }

          entry void main() {
            assert(helper(7) == 7);
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("LinkedManifest.w", source), "fixture.linked_manifest");
    return new BytecodeWriter().write(program);
  }

  private static byte[] expectedManifest(byte[] artifact) {
    int start = sectionStart(artifact, 1);
    byte[] manifest = Arrays.copyOfRange(artifact, start, start + 24);
    ByteBuffer bytes = ByteBuffer.wrap(manifest).order(ByteOrder.LITTLE_ENDIAN);
    bytes.putInt(4, bytes.getInt(4) + 3);
    return manifest;
  }

  private static int functionName(byte[] artifact, int function) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getInt(sectionStart(artifact, 5) + 4 + function * 40 + 4);
  }

  private static int functionCount(byte[] artifact) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getInt(sectionStart(artifact, 5));
  }

  private static int stringCount(byte[] artifact) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getInt(sectionStart(artifact, 2));
  }

  private static int sectionStart(byte[] artifact, int type) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int count = bytes.getInt(24);
    for (int index = 0; index < count; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == type) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing section " + type);
  }

  private static Program program(int expectedFunctionCount) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_names"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_string_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_manifest_section"));
    sources.put("LinkedManifestSectionExample.w", """
        module example.linked_manifest_section;

        import wheeler.compiler.closure.compiled_function_names;
        import wheeler.compiler.closure.compiled_string_products;
        import wheeler.compiler.closure.linked_manifest_section;

        classical class LinkedManifestSectionExample {
          state long firstName = -1;
          state long secondName = -1;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 598016, /* allocations= */ 8);
            words artifactRanks = allocate(rows, /* length= */ 16384);
            words stringStarts = allocate(rows, /* length= */ 16384);
            words stringLengths = allocate(rows, /* length= */ 16384);
            words finalStrings = allocate(rows, /* length= */ 16384);
            words functionNames = allocate(rows, /* length= */ 4096);
            words finalFunctionNames = allocate(rows, /* length= */ 4096);
            words moduleFirstFunctions = allocate(rows, /* length= */ 512);
            words moduleFunctionCounts = allocate(rows, /* length= */ 512);
            CompiledStringPlan strings = appendCompiledStringProducts(
              source,
              bufferLength(source),
              /* artifactBase= */ 0,
              /* artifactRank= */ 0,
              /* closureStringCount= */ 0,
              artifactRanks,
              stringStarts,
              stringLengths
            );
            long string = 0;
            while (string < strings.stringCount) limit 16384 {
              set(finalStrings, string, string);
              string += 1;
            }
            set(functionNames, 0, 0);
            set(functionNames, 1, 0);
            set(functionNames, 2, 0);
            appendCompiledFunctionNames(
              source,
              bufferLength(source),
              /* moduleStringBase= */ 0,
              strings.stringCount,
              /* firstFunction= */ 3,
              /* expectedFunctionCount= */ %d,
              functionNames
            );
            resolveLinkedFunctionNameIds(
              /* functionCount= */ %d,
              strings.closureStringCount,
              functionNames,
              finalStrings,
              finalFunctionNames
            );
            firstName = finalFunctionNames[3];
            secondName = finalFunctionNames[4];
            set(moduleFirstFunctions, 0, 3);
            set(moduleFunctionCounts, 0, %d);
            long manifestBytes = emitLinkedManifestSection(
              source,
              bufferLength(source),
              /* rootModule= */ 0,
              /* rootStringBase= */ 0,
              strings.stringCount,
              strings.closureStringCount,
              finalStrings,
              moduleFirstFunctions,
              moduleFunctionCounts,
              output,
              /* outputStart= */ 0
            );
            published = 1;
            setOutputLength(output, manifestBytes);
            drop(moduleFunctionCounts);
            drop(moduleFirstFunctions);
            drop(finalFunctionNames);
            drop(functionNames);
            drop(finalStrings);
            drop(stringLengths);
            drop(stringStarts);
            drop(artifactRanks);
            drop(rows);
          }
        }
        """.formatted(
          expectedFunctionCount,
          expectedFunctionCount + 3,
          expectedFunctionCount
        ));
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_manifest_section");
  }
}
