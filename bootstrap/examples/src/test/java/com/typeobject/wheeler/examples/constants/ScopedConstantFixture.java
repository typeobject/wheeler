package com.typeobject.wheeler.examples.constants;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;

/** Runs detached scalar products through the native copier and expression owner. */
final class ScopedConstantFixture {
  static final int COLUMNS = 7;
  static final int HEADER = 1;
  static final int QUALIFIER_START = COLUMNS - 2;
  private static final int EMPTY_WINDOW = 1;
  static final int MAX_PRODUCTS = 16_384;
  static final int MAX_NAME = 256;
  static final int MAX_NAMES = 1_048_576;
  static final int TAIL = 3;
  static final int SENTINEL = 211;

  record Product(long start, long length, long type, long value, long resolved,
                 long qualifierStart, long qualifierLength) {
    long[] cells() {
      return new long[] {start, length, type, value, resolved, qualifierStart, qualifierLength};
    }
  }

  record Input(byte[] spellings, byte[] qualifiers, List<Product> products,
               int prefix, int nameCapacity, int rowCapacity, String mutation, String expression,
               int repeat) {
    int count() { return products.size() * repeat; }
  }

  record Fixture(Program driver, Input input) {
    VirtualMachine machine() {
      return new VirtualMachine(driver, input.expression().getBytes(StandardCharsets.UTF_8));
    }
  }

  private ScopedConstantFixture() {}

  static Input ordinary(String mutation, String expression) {
    byte[] spellings = "café 𝄞|BOUND!BOUND?".getBytes(StandardCharsets.UTF_8);
    int first = "café 𝄞|".getBytes(StandardCharsets.UTF_8).length;
    byte[] qualifiers = "!pkg.left?pkg.right!".getBytes(StandardCharsets.UTF_8);
    return new Input(spellings, qualifiers, List.of(
        new Product(first, "BOUND".length(), 1, 7, 1, 1, "pkg.left".length()),
        new Product(first + "BOUND!".length(), "BOUND".length(), 1, 11, 1,
            "!pkg.left?".length(), "pkg.right".length())),
        TAIL, TAIL + 2 * MAX_NAME + TAIL, HEADER + 2 * COLUMNS + TAIL,
        mutation, expression, 1);
  }

  static Fixture fixture(Input input) throws Exception {
    int rawRows = HEADER + input.count() * COLUMNS;
    var byteWrites = new StringBuilder();
    byteWrites(byteWrites, "spellings", input.spellings());
    byteWrites(byteWrites, "qualifiers", input.qualifiers());
    var tableWrites = new StringBuilder();
    for (int product = 0; product < input.products().size(); product++) {
      long[] cells = input.products().get(product).cells();
      for (int column = 0; column < cells.length; column++) {
        tableWrites.append("set(raw, CONSTANT_PRODUCT_HEADER_ROWS + (copyIndex * ")
            .append(input.products().size()).append(" + ").append(product)
            .append(") * CONSTANT_PRODUCT_COLUMNS + ").append(column)
            .append(", ").append(cells[column]).append(");\n");
      }
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.scoped_constant_products"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.constant_expressions"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("ScopedConstants.w", """
        module example.scoped_constants;
        import wheeler.compiler.closure.scoped_constant_products;
        import wheeler.compiler.compiler_token_limits;
        import wheeler.compiler.constant_expressions;
        import wheeler.compiler.constant_product_schema;
        import wheeler.compiler.module_linker;
        classical class ScopedConstants {
          private const long SPELLING_BYTES = %d;
          private const long QUALIFIER_BYTES = %d;
          private const long NAME_BYTES = %d;
          private const long INPUT_ROWS = %d;
          private const long OUTPUT_ROWS = %d;
          private const long PRODUCT_COUNT = %d;
          private const long REPEATS = %d;
          private const long PREFIX = %d;
          private const long TAIL = %d;
          private const long SENTINEL = %d;
          private const long TOKEN_COLUMNS = 3;
          private const long WORD_BYTES = 8;
          private const long BYTE_BUFFERS = 3;
          private const long PRODUCT_BUFFERS = 2;
          private const long ARENA_BYTES = SPELLING_BYTES + QUALIFIER_BYTES + NAME_BYTES
            + (INPUT_ROWS + OUTPUT_ROWS + TOKEN_COLUMNS * MAX_COMPILER_TOKENS) * WORD_BYTES;
          private const long ALLOCATIONS = BYTE_BUFFERS + PRODUCT_BUFFERS + TOKEN_COLUMNS;
          state long prepared = 0;
          state long published = 0;
          state long completed = 0;
          state long productCount = -1;
          state long nameBytes = -1;
          state long valid = 0;
          state long signed = 0;
          state long value = 0;
          entry void main(borrow utf8 source) {
            region arena = new region(ARENA_BYTES, ALLOCATIONS);
            bytes spellings = allocateBytes(arena, SPELLING_BYTES);
            bytes qualifiers = allocateBytes(arena, QUALIFIER_BYTES);
            bytes names = allocateBytes(arena, NAME_BYTES);
            words raw = allocate(arena, INPUT_ROWS);
            words products = allocate(arena, OUTPUT_ROWS);
            words kinds = allocate(arena, MAX_COMPILER_TOKENS);
            words starts = allocate(arena, MAX_COMPILER_TOKENS);
            words lengths = allocate(arena, MAX_COMPILER_TOKENS);
            %s
            long copyIndex = 0;
            while (copyIndex < REPEATS) limit MAX_CONSTANT_PRODUCTS {
              %s
              copyIndex += 1;
            }
            set(raw, 0, PRODUCT_COUNT);
            long byteIndex = 0;
            while (byteIndex < NAME_BYTES) limit CONSTANT_PRODUCT_NAME_BYTES {
              setByte(names, byteIndex, SENTINEL);
              byteIndex += 1;
            }
            long rowIndex = 0;
            while (rowIndex < OUTPUT_ROWS) limit CONSTANT_PRODUCT_ROWS + TAIL {
              set(products, rowIndex, SENTINEL);
              rowIndex += 1;
            }
            long requested = PRODUCT_COUNT;
            long outputStart = PREFIX;
            %s
            prepared = 1;
            ScopedConstantProductPlan plan = copyScopedConstantProducts(
              spellings, qualifiers, requested, raw, outputStart, names, products
            );
            productCount = plan.productCount;
            nameBytes = plan.nameBytes;
            published = 1;
            if (bufferLength(source) != 0) {
              long count = scanSemanticTokens(source, kinds, starts, lengths);
              ExpressionValue expression = evaluateScalarExpressionWithProducts(
                source, starts, lengths, 0, 0, 0, count, names, products
              );
              if (expression.valid) { valid = 1; }
              if (expression.signed) { signed = 1; }
              value = expression.value;
            }
            completed = 1;
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(products);
            drop(raw);
            drop(names);
            drop(qualifiers);
            drop(spellings);
            drop(arena);
          }
        }
        """.formatted(Math.max(EMPTY_WINDOW, input.spellings().length),
            Math.max(EMPTY_WINDOW, input.qualifiers().length),
            input.nameCapacity(), rawRows, input.rowCapacity(), input.count(), input.repeat(),
            input.prefix(), TAIL, SENTINEL, byteWrites, tableWrites, input.mutation()));
    return new Fixture(new WheelerCompiler().compileModuleFiles(sources, "example.scoped_constants"), input);
  }

  private static void byteWrites(StringBuilder target, String name, byte[] bytes) {
    for (int index = 0; index < bytes.length; index++) {
      target.append("setByte(").append(name).append(", ").append(index).append(", ")
          .append(Byte.toUnsignedInt(bytes[index])).append(");\n");
    }
  }
}
