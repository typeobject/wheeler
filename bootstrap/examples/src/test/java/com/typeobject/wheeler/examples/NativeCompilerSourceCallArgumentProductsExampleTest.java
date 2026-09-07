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
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Exact argument columns, pooled capacity, and atomic rejection evidence. */
final class NativeCompilerSourceCallArgumentProductsExampleTest {
  private static final int ARITY = 64;
  private static final int ARGUMENT_LIMIT = 256 * ARITY;
  private static final int ARGUMENT_WORDS = ARGUMENT_LIMIT * 2;
  private static final int OUTPUT_WORDS = 256 * 2 + ARGUMENT_WORDS * 2;
  private static final String[] TYPES = {
      "long", "boolean", "borrow utf8", "borrow byteview", "borrow mut words", "borrow mut bytes",
      "borrow mut region", "borrow mut longmap"
  };
  private static final int[] TYPE_CODES = {1, 2, 8, 13, 10, 11, 12, 9};
  private static final String[] PARAMETERS = IntStream.range(0, ARITY)
      .mapToObj(index -> TYPES[index % TYPES.length] + " value" + index).toArray(String[]::new);
  private static final int[] ORDER = IntStream.range(0, ARITY).map(index -> (index * 17 + 63) % ARITY)
      .toArray();
  private static final long SENTINEL = -7;

  @Test
  void bindsTypedArgumentsToDefiningValues() throws Exception {
    assertBinding(1, arguments(), ARITY, true);
  }

  @Test
  void fillsBothCompleteArgumentTables() throws Exception {
    // Repeating a call-site range isolates this arena from token and code limits.
    assertBinding(256, arguments(), ARITY, true);
  }

  @Test
  void rejectsArgumentSixtyFiveBeforePublishingAnyCall() throws Exception {
    assertBinding(1, arguments() + ", value0", ARITY + 1, false);
    assertBinding(2, arguments() + ", value0", ARITY + 1, false);
  }

  @Test
  void rejectsUnknownFinalArgumentsWithoutPublishingTheAdmittedPrefix() throws Exception {
    String missing = IntStream.range(0, ARITY).mapToObj(index -> index == ARITY - 1
        ? "missing" : "value" + ORDER[index]).collect(Collectors.joining(", "));
    assertBinding(1, missing, ARITY, false);
    assertBinding(2, missing, ARITY, false);
  }

  @Test
  void rejectsOwnedStorageInsteadOfInventingABorrowMode() throws Exception {
    for (String storage : new String[] {"region", "longmap"}) {
      String[] definitions = PARAMETERS.clone();
      definitions[ARITY - 1] = "borrow mut " + storage + " value63";
      String initializer = storage.equals("region")
          ? "new region(/* bytes= */ ARENA_BYTES, /* allocations= */ 1)" : "allocateMap(value6, 1)";
      String source = "void caller(" + String.join(", ", Arrays.copyOf(definitions, ARITY - 1))
          + ") { " + storage + " value63 = " + initializer + "; target(" + arguments()
          + "); broken(" + arguments() + "); drop(value63); }";
      String targetParameters = Arrays.stream(ORDER).mapToObj(index -> definitions[index])
          .collect(Collectors.joining(", "));
      String oracle = "module example.owned_call; classical class Calls { "
          + "private const long ARENA_BYTES = 4096; " + source
          + " void target(" + targetParameters + ") {}"
          + " void broken(" + targetParameters + ") {} }";
      new WheelerCompiler().compileLibraryModuleFiles(Map.of("Call.w", oracle), "example.owned_call");
      definitions[ARITY - 1] = storage + " value63";
      assertBinding(source, 1, ARITY, false, definitions);
    }
  }

  private static void assertBinding(int calls, String lastArguments, int lastArity, boolean accepted)
      throws Exception {
    String source = "void caller(" + String.join(", ", PARAMETERS) + ") { target("
        + arguments() + "); broken(" + lastArguments + "); }";
    assertBinding(source, calls, lastArity, accepted, PARAMETERS);
  }

  private static void assertBinding(String source, int calls, int lastArity, boolean accepted,
      String[] definitions) throws Exception {
    VirtualMachine machine = new VirtualMachine(program(source, calls, lastArity, definitions),
        source.getBytes(StandardCharsets.UTF_8), OUTPUT_WORDS * 8);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(accepted ? 1 : 0, machine.global("valid"));
    assertEquals(accepted ? calls : 0, machine.global("callCount"));
    assertEquals(accepted ? calls * ARITY : 0, machine.global("argumentCount"));
    long[] expected = new long[OUTPUT_WORDS];
    Arrays.fill(expected, SENTINEL);
    if (accepted) {
      for (int call = 0; call < calls; call++) {
        expected[call] = call * ARITY;
        expected[256 + call] = ARITY;
        for (int argument = 0; argument < ARITY; argument++) {
          int row = call * ARITY + argument;
          expected[512 + row] = ORDER[argument];
          expected[512 + ARGUMENT_LIMIT + row] = TYPE_CODES[ORDER[argument] % TYPES.length];
          expected[512 + ARGUMENT_WORDS + row] = ORDER[argument];
          expected[512 + ARGUMENT_WORDS + ARGUMENT_LIMIT + row] = 0;
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
    return Arrays.stream(ORDER).mapToObj(index -> "value" + index).collect(Collectors.joining(", "));
  }

  private static Program program(String source, int calls, int lastArity, String[] definitions)
      throws Exception {
    StringBuilder values = new StringBuilder();
    for (int index = 0; index < definitions.length; index++) {
      String parameter = definitions[index];
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

        import wheeler.compiler.closure.direct_statement_coordinates;
        import wheeler.compiler.closure.source_call_argument_products;
        import wheeler.compiler.encoding;
        import wheeler.compiler.module_linker;

        classical class SourceCallArgumentProductsExample {
          private const long ARGUMENT_TABLE_WORDS = ARGUMENT_WORD_COUNT;
          private const long PRODUCT_BYTES = 301056 + ARGUMENT_TABLE_WORDS * 16;
          private const long TOKEN_BYTES = 98304;
          state long valid = 0;
          state long callCount = 0;
          state long argumentCount = 0;

          private void requireBufferDomain(borrow utf8 source, borrow mut words values) {
            region tokens = new region(/* bytes= */ TOKEN_BYTES, /* allocations= */ 3);
            words kinds = allocate(tokens, 4096);
            words starts = allocate(tokens, 4096);
            words lengths = allocate(tokens, 4096);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            long local = 6;
            while (local < ARITY) limit ARITY {
              long regionType = directBufferLocalType(source, 0, local, ARITY, values,
                count, starts, lengths);
              long mapType = directBufferLocalType(source, 0, local + 1, ARITY, values,
                count, starts, lengths);
              assert(regionType == -1);
              assert(mapType == -1);
              local += 8;
            }
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(tokens);
          }

          private void fill(borrow mut words rows) {
            long row = 0;
            while (row < bufferLength(rows)) limit ARGUMENT_TABLE_WORDS {
              set(rows, row, -7);
              row += 1;
            }
          }

          private long publish(borrow mut words rows, borrow mut bytes output, long cursor) {
            long row = 0;
            while (row < bufferLength(rows)) limit ARGUMENT_TABLE_WORDS {
              cursor = writeSignedLittleEndian(output, cursor, rows[row], 8);
              row += 1;
            }
            return cursor;
          }

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ PRODUCT_BYTES, /* allocations= */ 8);
            words calls = allocate(products, 1024);
            words callStatements = allocate(products, 256);
            words statements = allocate(products, 28672);
            words values = allocate(products, 7168);
            words argumentStarts = allocate(products, 256);
            words argumentCounts = allocate(products, 256);
            words arguments = allocate(products, ARGUMENT_TABLE_WORDS);
            words argumentValues = allocate(products, ARGUMENT_TABLE_WORDS);
            VALUE_SETUP
            requireBufferDomain(input, values);
            long call = 0;
            while (call < CALL_COUNT) limit 256 {
              set(calls, call, CALL_START);
              set(calls, 256 + call, 6);
              set(calls, 512 + call, ARITY);
              call += 1;
            }
            set(calls, CALL_COUNT - 1, LAST_START);
            set(calls, 512 + CALL_COUNT - 1, LAST_ARITY);
            fill(argumentStarts);
            fill(argumentCounts);
            fill(arguments);
            fill(argumentValues);
            SourceCallArgumentPlan plan = materializeSourceCallArgumentProducts(
              input, 0, CALL_COUNT, calls, callStatements, 1, statements, ARITY, values,
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
            .replace("LAST_ARITY", Integer.toString(lastArity))
            .replace("ARITY", Integer.toString(ARITY))
            .replace("ARGUMENT_WORD_COUNT", Integer.toString(ARGUMENT_WORDS)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_call_argument_products");
  }
}
