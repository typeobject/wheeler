package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for immutable closure body artifact storage. */
final class NativeCompilerCompiledBodyArchiveExampleTest {
  @Test
  void appendsArtifactsAndPublishesStableRanks() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(false), artifact, 1);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(2, machine.global("artifactCount"));
    assertEquals(artifact.length * 2L, machine.global("archiveBytes"));
    assertEquals(0, machine.global("firstRank"));
    assertEquals(1, machine.global("secondRank"));
    assertEquals(artifact.length, machine.global("secondStart"));
    assertEquals(1, machine.global("copiesMatch"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsDuplicateModuleOwnersBeforePublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(true), artifact(), 1);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] artifact() {
    String source = """
        module fixture.body_archive;

        classical class BodyArchive {
          public long identity(long value) {
            return value;
          }
        }
        """;
    return new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("BodyArchive.w", source), "fixture.body_archive"));
  }

  private static Program program(boolean duplicate) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_body_archive"));
    sources.put("CompiledBodyArchiveExample.w", """
        module example.compiled_body_archive;

        import wheeler.compiler.closure.compiled_body_archive;

        classical class CompiledBodyArchiveExample {
          state long artifactCount = 0;
          state long archiveBytes = 0;
          state long firstRank = -1;
          state long secondRank = -1;
          state long secondStart = -1;
          state long copiesMatch = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region storage = new region(/* bytes= */ 16793600, /* allocations= */ 5);
            words modulePublished = allocate(storage, /* length= */ 512);
            words moduleArtifactRanks = allocate(storage, /* length= */ 512);
            words artifactStarts = allocate(storage, /* length= */ 512);
            words artifactLengths = allocate(storage, /* length= */ 512);
            bytes archive = allocateBytes(storage, /* length= */ 16777216);
            CompiledBodyArchivePlan first = appendCompiledBodyArtifact(
              source,
              bufferLength(source),
              /* moduleOwner= */ 1,
              /* artifactCount= */ 0,
              /* archiveBytes= */ 0,
              modulePublished,
              moduleArtifactRanks,
              artifactStarts,
              artifactLengths,
              archive
            );
            CompiledBodyArchivePlan second = appendCompiledBodyArtifact(
              source,
              bufferLength(source),
              /* moduleOwner= */ SECOND_OWNER,
              first.artifactCount,
              first.archiveBytes,
              modulePublished,
              moduleArtifactRanks,
              artifactStarts,
              artifactLengths,
              archive
            );
            artifactCount = second.artifactCount;
            archiveBytes = second.archiveBytes;
            firstRank = moduleArtifactRanks[1];
            secondRank = moduleArtifactRanks[3];
            secondStart = artifactStarts[second.artifactRank];
            if (archive[0] == archive[secondStart]) {
              copiesMatch = 1;
            }
            published = 1;
            setOutputLength(output, 0);
            drop(archive);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(moduleArtifactRanks);
            drop(modulePublished);
            drop(storage);
          }
        }
        """.replace("SECOND_OWNER", duplicate ? "1" : "3"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.compiled_body_archive");
  }
}
