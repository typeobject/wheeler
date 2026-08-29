package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Executable evidence for canonical package-manifest line shapes. */
final class NativeCompilerPackageCanonicalLinesExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_lines";

  @Test
  void executesPlainAndDashedLineShapes() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalLinesExample.w", """
        module example.package_canonical_lines;

        import wheeler.compiler.packages.canonical_lines;

        classical class PackageCanonicalLinesExample {
          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 512, /* allocations= */ 3);
            words kinds = allocate(rows, /* length= */ 8);
            words starts = allocate(rows, /* length= */ 8);
            words lengths = allocate(rows, /* length= */ 8);
            set(kinds, 1, 3);
            set(starts, 0, 0);
            set(lengths, 0, 4);
            set(starts, 1, 4);
            set(lengths, 1, 1);
            set(starts, 2, 6);
            set(lengths, 2, 5);
            set(kinds, 3, 3);
            set(kinds, 5, 3);
            set(starts, 3, 12);
            set(lengths, 3, 1);
            set(starts, 4, 14);
            set(lengths, 4, 4);
            set(starts, 5, 18);
            set(lengths, 5, 1);
            set(starts, 6, 20);
            set(lengths, 6, 5);
            assert(canonicalLineShape(source, kinds, starts, lengths, 0, 3));
            assert(canonicalLineEndMatches(starts, lengths, 0, 3, 11));
            assert(canonicalLineShape(source, kinds, starts, lengths, 3, 4));
            assert(canonicalLineEndMatches(starts, lengths, 3, 4, 25));
            assert(canonicalLineShape(source, kinds, starts, lengths, 0, 1) == false);
            assert(canonicalLineEndMatches(starts, lengths, 0, 3, 10) == false);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(rows);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_lines");
    var machine = new VirtualMachine(
        program, "name: value\n- name: value".getBytes(StandardCharsets.US_ASCII));

    machine.run();
  }
}
