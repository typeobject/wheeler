package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exact cross-buffer name matching and rejection before out-of-range reads. */
final class NativeCompilerConstantNameProductsExampleTest {
  private record Case(long start, long length, long nameStart, long nameLength, boolean matches) {}

  @Test
  void matchesIndependentNamesAndRejectsMalformedWindowsWithoutMutation() throws Exception {
    String prefix = "// café 𝄞\n";
    String source = prefix + "LIMIT " + "A".repeat(256);
    long start = prefix.getBytes(StandardCharsets.UTF_8).length;
    List<Case> cases = List.of(
        new Case(start, 5, 3, 5, true),
        new Case(start + 6, 256, 8, 256, true),
        new Case(start + 6, 257, 8, 257, false),
        new Case(start, 5, 8, 5, false),
        new Case(start, 5, 3, 4, false),
        new Case(start, 5, 3, 6, false),
        new Case(start, 0, 3, 0, false),
        new Case(start, -1, 3, -1, false),
        new Case(start, Long.MIN_VALUE, 3, 5, false),
        new Case(start, Long.MAX_VALUE, 3, 5, false),
        new Case(-1, 5, 3, 5, false),
        new Case(Long.MIN_VALUE, 5, 3, 5, false),
        new Case(Long.MAX_VALUE, 5, 3, 5, false),
        new Case(source.getBytes(StandardCharsets.UTF_8).length - 4, 5, 3, 5, false),
        new Case(start, 5, -1, 5, false),
        new Case(start, 5, Long.MIN_VALUE, 5, false),
        new Case(start, 5, Long.MAX_VALUE, 5, false),
        new Case(start, 5, 261, 5, false),
        new Case(start, 5, 3, Long.MIN_VALUE, false),
        new Case(start, 5, 3, Long.MAX_VALUE, false),
        new Case(start, 1, 264, 1, false));
    byte[] expected = new byte[cases.size() + 265];
    expected[cases.size() + 3] = 'L';
    expected[cases.size() + 4] = 'I';
    expected[cases.size() + 5] = 'M';
    expected[cases.size() + 6] = 'I';
    expected[cases.size() + 7] = 'T';
    java.util.Arrays.fill(expected, cases.size() + 8, cases.size() + 264, (byte) 'A');
    expected[cases.size() + 264] = (byte) 128;
    StringBuilder checks = new StringBuilder();
    for (int index = 0; index < cases.size(); index++) {
      Case row = cases.get(index);
      expected[index] = row.matches() ? (byte) 1 : 0;
      checks.append("boolean matched").append(index).append(" = matchesConstantName(input, ")
          .append(literal(row.start())).append(", ").append(literal(row.length()))
          .append(", names, ").append(literal(row.nameStart())).append(", ")
          .append(literal(row.nameLength())).append(");\n")
          .append("if (matched").append(index).append(") { setByte(output, ")
          .append(index).append(", 1); }\n");
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_constant_values"));
    sources.put("ConstantNames.w", """
        module example.constant_name_products;
        import wheeler.compiler.closure.imported_constant_values;
        classical class ConstantNames {
          entry void main(borrow utf8 input, borrow mut bytes output) {
            region storage = new region(265, 1);
            bytes names = allocateBytes(storage, 265);
            writeAscii(names, 3, "LIMIT");
            long offset = 8;
            while (offset < 264) limit 256 {
              setByte(names, offset, 65);
              offset += 1;
            }
            setByte(names, 264, 128);
            long minimum = -9223372036854775807 - 1;
            %s
            offset = 0;
            while (offset < 265) limit 265 {
              setByte(output, %d + offset, names[offset]);
              offset += 1;
            }
            setOutputLength(output, %d);
            drop(names);
            drop(storage);
          }
        }
        """.formatted(checks, cases.size(), expected.length));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.constant_name_products");
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), expected.length);
    var initial = machine.snapshot();
    machine.run();
    assertArrayEquals(expected, machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static String literal(long value) {
    return value == Long.MIN_VALUE ? "minimum" : Long.toString(value);
  }
}
