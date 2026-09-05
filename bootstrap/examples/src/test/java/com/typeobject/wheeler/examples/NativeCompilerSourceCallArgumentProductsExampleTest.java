package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Exact argument columns, pooled capacity, and atomic rejection evidence. */
final class NativeCompilerSourceCallArgumentProductsExampleTest {
  private static final String[] PARAMETERS = {
      "long first", "boolean flag", "borrow utf8 text", "borrow byteview view",
      "borrow mut words cells", "borrow mut bytes data", "long count", "boolean last"
  };
  private static final int[] TYPES = {1, 2, 8, 13, 10, 11, 1, 2};
  private static final int[] ORDER = {7, 0, 5, 2, 6, 1, 4, 3};
  private static final int OUTPUT_WORDS = 256 * 2 + 4096 * 2;
  private static final long SENTINEL = -7;

  @Test
  void bindsTypedArgumentsToDefiningValues() throws Exception {
    assertBinding(1, arguments(), 8, true);
  }

  @Test
  void fillsBothCompleteArgumentTables() throws Exception {
    // Repeat one validated call-site range to isolate the product arena bound.
    // This is not a claim that 256 source calls fit every other compiler pool.
    assertBinding(256, arguments(), 8, true);
  }

  @Test
  void rejectsANinthArgumentBeforePublishingAnyCall() throws Exception {
    assertBinding(1, arguments() + ", first", 9, false);
    assertBinding(2, arguments() + ", first", 9, false);
  }

  @Test
  void rejectsUnknownEighthArgumentsWithoutPublishingTheAdmittedPrefix() throws Exception {
    assertBinding(1, arguments().replace("view", "missing"), 8, false);
    assertBinding(2, arguments().replace("view", "missing"), 8, false);
  }

  private static void assertBinding(int calls, String lastArguments, int lastArity, boolean accepted)
      throws Exception {
    String source = "void caller(" + String.join(", ", PARAMETERS) + ") { target("
        + arguments() + "); broken(" + lastArguments + "); }";
    VirtualMachine machine = new VirtualMachine(
        program(source, calls, lastArity), source.getBytes(StandardCharsets.UTF_8), OUTPUT_WORDS * 8);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(accepted ? 1 : 0, machine.global("valid"));
    assertEquals(accepted ? calls : 0, machine.global("callCount"));
    assertEquals(accepted ? calls * 8 : 0, machine.global("argumentCount"));
    long[] expected = new long[OUTPUT_WORDS];
    Arrays.fill(expected, SENTINEL);
    if (accepted) {
      for (int call = 0; call < calls; call++) {
        expected[call] = call * 8;
        expected[256 + call] = 8;
        for (int argument = 0; argument < 8; argument++) {
          int row = call * 8 + argument;
          expected[512 + row] = ORDER[argument];
          expected[512 + 2048 + row] = TYPES[ORDER[argument]];
          expected[512 + 4096 + row] = ORDER[argument];
          expected[512 + 4096 + 2048 + row] = 0;
        }
      }
    }
    ByteBuffer bytes = ByteBuffer.allocate(OUTPUT_WORDS * 8).order(ByteOrder.LITTLE_ENDIAN);
    for (long word : expected) {
      bytes.putLong(word);
    }
    assertArrayEquals(bytes.array(), machine.hostOutput());
  }

  private static String arguments() {
    return String.join(", ", Arrays.stream(ORDER)
        .mapToObj(index -> PARAMETERS[index].substring(PARAMETERS[index].lastIndexOf(' ') + 1))
        .toList());
  }

  private static Program program(String source, int calls, int lastArity) throws Exception {
    StringBuilder values = new StringBuilder();
    for (int index = 0; index < PARAMETERS.length; index++) {
      String parameter = PARAMETERS[index];
      int start = source.indexOf(parameter);
      int nameOffset = parameter.lastIndexOf(' ') + 1;
      values.append("set(values, ").append(1024 + index).append(", ")
          .append(start + nameOffset).append(");\n");
      values.append("set(values, ").append(2048 + index).append(", ")
          .append(parameter.length() - nameOffset).append(");\n");
      values.append("set(values, ").append(3072 + index).append(", ")
          .append(index).append(");\n");
      values.append("set(values, ").append(5120 + index).append(", ")
          .append(start).append(");\n");
    }
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_argument_products"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("SourceCallArgumentProductsExample.w", """
        module example.source_call_argument_products;

        import wheeler.compiler.closure.source_call_argument_products;
        import wheeler.compiler.encoding;

        classical class SourceCallArgumentProductsExample {
          state long valid = 0;
          state long callCount = 0;
          state long argumentCount = 0;

          private void fill(borrow mut words rows) {
            long row = 0;
            while (row < bufferLength(rows)) limit 4096 {
              set(rows, row, -7);
              row += 1;
            }
          }

          private long publish(borrow mut words rows, borrow mut bytes output, long cursor) {
            long row = 0;
            while (row < bufferLength(rows)) limit 4096 {
              cursor = writeSignedLittleEndian(output, cursor, rows[row], 8);
              row += 1;
            }
            return cursor;
          }

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 366592, /* allocations= */ 8);
            words calls = allocate(products, 1024);
            words callStatements = allocate(products, 256);
            words statements = allocate(products, 28672);
            words values = allocate(products, 7168);
            words argumentStarts = allocate(products, 256);
            words argumentCounts = allocate(products, 256);
            words arguments = allocate(products, 4096);
            words argumentValues = allocate(products, 4096);
            VALUE_SETUP
            long call = 0;
            while (call < CALL_COUNT) limit 256 {
              set(calls, call, CALL_START);
              set(calls, 256 + call, 6);
              set(calls, 512 + call, 8);
              call += 1;
            }
            set(calls, CALL_COUNT - 1, LAST_START);
            set(calls, 512 + CALL_COUNT - 1, LAST_ARITY);
            fill(argumentStarts);
            fill(argumentCounts);
            fill(arguments);
            fill(argumentValues);
            SourceCallArgumentPlan plan = materializeSourceCallArgumentProducts(
              input, 0, CALL_COUNT, calls, callStatements, 1, statements, 8, values,
              argumentStarts, argumentCounts, arguments, argumentValues
            );
            if (plan.valid) {
              valid = 1;
            }
            callCount = plan.callCount;
            argumentCount = plan.argumentCount;
            long cursor = publish(argumentStarts, output, 0);
            cursor = publish(argumentCounts, output, cursor);
            cursor = publish(arguments, output, cursor);
            cursor = publish(argumentValues, output, cursor);
            setOutputLength(output, cursor);
            drop(argumentValues);
            drop(arguments);
            drop(argumentCounts);
            drop(argumentStarts);
            drop(values);
            drop(statements);
            drop(callStatements);
            drop(calls);
            drop(products);
          }
        }
        """.replace("VALUE_SETUP", values)
            .replace("CALL_COUNT", Integer.toString(calls))
            .replace("CALL_START", Integer.toString(source.indexOf("target(")))
            .replace("LAST_START", Integer.toString(source.indexOf("broken(")))
            .replace("LAST_ARITY", Integer.toString(lastArity)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_call_argument_products");
  }
}
