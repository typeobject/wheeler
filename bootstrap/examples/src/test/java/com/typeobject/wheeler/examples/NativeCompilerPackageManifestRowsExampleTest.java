package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Arrays;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Native evidence for package-manifest fixed-width row capacity. */
final class NativeCompilerPackageManifestRowsExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_rows";

  @Test
  void executesPartialCompleteNegativeAndOverflowingRows() throws Exception {
    assertCapacity("manifestTargetRowCapacity", 10);
    assertCapacity("manifestSourceRowCapacity", 2);
    assertCapacity("manifestDependencyRowCapacity", 5);
    assertCapacity("manifestCapabilityRowCapacity", 4);
  }

  private static void assertCapacity(String function, int width) throws Exception {
    int[] lengths = {1, width - 1, width, width + 1, width * 2 - 1, width * 2, width * 2 + 1};
    long[] rows = {Long.MIN_VALUE, -1, 0, 1, 2, Long.MAX_VALUE / width + 1, Long.MAX_VALUE};
    StringBuilder body = new StringBuilder("region output = new region(")
        .append(Arrays.stream(lengths).sum() * 8).append(", ")
        .append(lengths.length).append(");\n");
    for (int index = 0; index < lengths.length; index++) {
      int length = lengths[index];
      String table = "rows" + index;
      body.append("words ").append(table).append(" = allocate(output, ")
          .append(length).append(");\n");
      for (int cell = 0; cell < length; cell++) {
        body.append("set(").append(table).append(", ").append(cell).append(", ")
            .append(cell + 11).append(");\n");
      }
      for (long row : rows) {
        String literal = row == Long.MIN_VALUE ? "(-9223372036854775807 - 1)" : Long.toString(row);
        body.append("assert(").append(function).append("(").append(table).append(", ")
            .append(literal).append(") == ").append(0 <= row && row < length / width)
            .append(");\n");
      }
      for (int cell = 0; cell < length; cell++) {
        body.append("assert(").append(table).append('[').append(cell).append("] == ")
            .append(cell + 11).append(");\n");
      }
      body.append("drop(").append(table).append(");\n");
    }
    body.append("drop(output);\n");
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestRowsExample.w", """
        module example.package_manifest_rows;
        import wheeler.compiler.packages.manifest_rows;
        classical class PackageManifestRowsExample {
          entry void main() {
        """ + body + "}\n}\n");
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.package_manifest_rows");
    var machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    machine.run();
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
