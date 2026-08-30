package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Executable evidence for canonical package-manifest token windows. */
final class NativeCompilerPackageCanonicalTokenWindowExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_token_window";

  @Test
  void executesClosedTokenWindows() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalTokenWindowExample.w", """
        module example.package_canonical_token_window;

        import wheeler.compiler.packages.canonical_token_window;

        classical class PackageCanonicalTokenWindowExample {
          entry void main() {
            region rows = new region(/* bytes= */ 128, /* allocations= */ 1);
            words starts = allocate(rows, /* length= */ 4);
            set(starts, 0, 0);
            set(starts, 1, 4);
            set(starts, 2, 7);
            set(starts, 3, 12);
            assert(canonicalLineTokenEnd(starts, 0, 4, 10) == 3);
            assert(canonicalLineTokenEnd(starts, 3, 4, 10) == 3);
            assert(canonicalLineTokenEnd(starts, 4, 4, 10) == 4);
            drop(starts);
            drop(rows);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_token_window");

    new VirtualMachine(program).run();
  }
}
