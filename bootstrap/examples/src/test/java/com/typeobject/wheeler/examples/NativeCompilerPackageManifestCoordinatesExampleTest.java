package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Executes current and preceding coordinates for consecutive manifest entries. */
final class NativeCompilerPackageManifestCoordinatesExampleTest {
  @Test
  void executesDependencyCoordinates() throws Exception {
    assertCoordinates("wheeler.compiler.packages.manifest_dependency_coordinates", """
        assert(manifestDependencyNameToken(4) == 10);
        assert(manifestDependencyVersionToken(4) == 13);
        assert(manifestDependencyNextToken(4) == 14);
        assert(manifestDependencyPreviousNameToken(0, 0) == -1);
        assert(manifestDependencyPreviousNameToken(4, 0) == -1);
        assert(manifestDependencyPreviousNameToken(14, 1) == 10);
        assert(manifestDependencyPreviousNameToken(24, 2) == 20);
        assert(manifestDependencyValueStart(starts, 0) == 42);
        assert(manifestDependencyValueLength(lengths, 0) == 11);
        """);
  }

  @Test
  void executesCapabilityCoordinates() throws Exception {
    assertCoordinates("wheeler.compiler.packages.manifest_capability_coordinates", """
        assert(manifestCapabilityNameToken(4) == 7);
        assert(manifestCapabilityPathToken(4) == 10);
        assert(manifestCapabilityNextToken(4) == 11);
        assert(manifestCapabilityPreviousRowToken(0, 0) == -1);
        assert(manifestCapabilityPreviousRowToken(4, 0) == -1);
        assert(manifestCapabilityPreviousRowToken(11, 1) == 4);
        assert(manifestCapabilityPreviousRowToken(18, 2) == 11);
        assert(manifestCapabilityValueStart(starts, 0) == 42);
        assert(manifestCapabilityValueLength(lengths, 0) == 11);
        """);
  }

  @Test
  void executesTargetCoordinatesAndCompletedSourceSpans() throws Exception {
    assertCoordinates("wheeler.compiler.packages.manifest_target_coordinates", """
        assert(manifestTargetKindToken(4) == 7);
        assert(manifestTargetNameToken(4) == 10);
        assert(manifestTargetRootToken(4) == 13);
        assert(manifestTargetModuleKeyToken(4) == 14);
        assert(manifestTargetModuleToken(4) == 16);
        assert(manifestTargetSourcesKeyToken(4) == 17);
        assert(manifestTargetFirstSourceRowToken(4) == 19);
        assert(manifestTargetSourceTailToken(4, 0) == 19);
        assert(manifestTargetSourceTailToken(4, 1) == 21);
        assert(manifestTargetSourceTailToken(4, 1024) == 2067);
        assert(manifestTargetTailToken(4, 0) == 14);
        assert(manifestTargetSourceCount(4, 14) == 0);
        long count = 1;
        while (count < 1025) limit 1024 {
          long tail = manifestTargetTailToken(4, count);
          assert(tail == manifestTargetSourceTailToken(4, count));
          assert(manifestTargetSourceCount(4, tail) == count);
          count += 1;
        }
        assert(manifestTargetSelectorToken(19) == 20);
        assert(manifestTargetNextSourceRowToken(19) == 21);
        assert(manifestTargetTestToken(21) == 23);
        assert(manifestTargetNextToken(21) == 24);
        assert(manifestTargetValueStart(starts, 0) == 42);
        assert(manifestTargetValueLength(lengths, 0) == 11);
        """);
  }

  private static void assertCoordinates(String module, String assertions) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(module));
    sources.put("ManifestCoordinates.w", """
        module example.manifest_coordinates;
        import MODULE;
        classical class ManifestCoordinates {
          entry void main() {
            region arena = new region(16, 2);
            words starts = allocate(arena, 1);
            words lengths = allocate(arena, 1);
            set(starts, 0, 41);
            set(lengths, 0, 13);
            ASSERTIONS
            assert(starts[0] == 41);
            assert(lengths[0] == 13);
            drop(lengths);
            drop(starts);
            drop(arena);
          }
        }
        """.replace("MODULE", module).replace("ASSERTIONS", assertions));
    new VirtualMachine(new WheelerCompiler().compileModuleFiles(
        sources, "example.manifest_coordinates")).run();
  }
}
