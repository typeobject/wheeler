package com.typeobject.wheeler.examples.names;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.UnaryOperator;

/** Supplies shared native fronts and counted scalar facts to the archive compiler. */
final class UnqualifiedArchiveFixture {
  static final int SOURCE_BYTES = 32_768;
  static final int IDENTITY_BYTES = 32;
  static final int SENTINEL = 211;
  private static final String CLASS_NAME = "Unqualified";
  private static final String ORACLE_MODULE = "oracle.unqualified";
  private static final String PREFIX = "\u03c0 outside \ud834\udd1e\n";
  private static final String SUFFIX = "\noutside \u03c0";
  /** One already resolved, unqualified signed fact, not an expression evaluator. */
  record Constant(String name, long value) {}
  /** Independent semantic artifact and the intact immutable archive input. */
  record Fixture(Program driver, Program expected, byte[] input, String source) {}

  static Fixture fixture(String members, int target, List<Constant> constants, UnaryOperator<String> change)
      throws Exception {
    String source = "// caf\u00e9 \ud834\udd1e\r\nclassical class " + CLASS_NAME + " {\n" + members + "\n}";
    return sourceFixture(source, target, constants, change);
  }

  static Fixture sourceFixture(String source, int target, List<Constant> constants, UnaryOperator<String> change)
      throws Exception {
    int sourceStart = PREFIX.getBytes(StandardCharsets.UTF_8).length;
    int sourceLength = source.getBytes(StandardCharsets.UTF_8).length;
    int classStart = sourceStart + source.substring(0, source.indexOf(CLASS_NAME)).getBytes(StandardCharsets.UTF_8).length;
    Program expected = target == 2 ? libraryOracle(source) : new WheelerCompiler().compile(source);
    StringBuilder scalarWrites = new StringBuilder("set(constants, 0, " + constants.size() + ");\n");
    int nameBytes = 0;
    for (int row = 0; row < constants.size(); row++) {
      Constant value = constants.get(row);
      String first = "CONSTANT_PRODUCT_HEADER_ROWS + " + row + " * CONSTANT_PRODUCT_COLUMNS";
      scalarWrites.append("writeAscii(constantNames, ").append(nameBytes).append(", \"")
          .append(value.name()).append("\");\n")
          .append("set(constantStarts, ").append(row).append(", ").append(nameBytes).append(");\n");
      String[] columns = {"CONSTANT_NAME_START", "CONSTANT_NAME_LENGTH", "CONSTANT_TYPE", "CONSTANT_VALUE",
          "CONSTANT_RESOLVED", "CONSTANT_MODULE_START", "CONSTANT_MODULE_LENGTH"};
      String[] fields = {Integer.toString(nameBytes), Integer.toString(value.name().length()), "CONSTANT_SIGNED",
          Long.toString(value.value()), "1", "0", "0"};
      for (int column = 0; column < fields.length; column++) {
        scalarWrites.append("set(constants, ").append(first).append(" + ").append(columns[column]).append(", ")
            .append(fields[column]).append(");\n");
      }
      nameBytes += value.name().length();
    }
    String driver = """
        module example.unqualified_archive;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.callable_type_products;
        import wheeler.compiler.closure.source_callable_front_products;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.compiler_token_limits;
        import wheeler.compiler.constant_product_schema;
        import wheeler.compiler.opcodes;
        classical class UnqualifiedDriver {
          const long SOURCE_BYTES = 32768;
          const long CALLABLES = 4096;
          const long PARAMETERS = 16384;
          const long CALLABLE_COLUMNS = 14 + 1;
          const long PARAMETER_COLUMNS = 3 + 1;
          const long TOKEN_COLUMNS = 3;
          const long MODULE_WORDS = 2;
          const long PARAMETER_COUNTER = 1;
          const long REPORT_WORDS = 5;
          const long CONSTANT_NAME_BYTES = FIXTURE_NAME_BYTES;
          const long WORD_BYTES = 8;
          const long IDENTITY_BYTES = 32;
          const long SOURCE_START = INPUT_START;
          const long SOURCE_LENGTH = INPUT_LENGTH;
          const long ARENA_WORDS = CALLABLES * CALLABLE_COLUMNS + PARAMETERS * PARAMETER_COLUMNS
            + MAX_COMPILER_TOKENS * TOKEN_COLUMNS + MODULE_WORDS + PARAMETER_COUNTER
            + CONSTANT_PRODUCT_ROWS + MAX_CONSTANT_PRODUCTS + REPORT_WORDS;
          const long ARENA_BYTES = ARENA_WORDS * WORD_BYTES + SOURCE_LENGTH
            + CONSTANT_NAME_BYTES + IDENTITY_BYTES;
          const long WORD_BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS + TOKEN_COLUMNS + 2 + 3;
          const long BYTE_BUFFERS = 3;
          const long ARENA_BUFFERS = WORD_BUFFERS + BYTE_BUFFERS;
          state long phase = 0;
          state long functionCapacity = INTERPRETER_FUNCTION_COUNT;
          state long frameCapacity = INTERPRETER_LOCAL_WIDTH;
          entry void main(borrow byteview input, borrow mut bytes output) {
            region arena = new region(ARENA_BYTES, ARENA_BUFFERS);
            bytes selected = allocateBytes(arena, SOURCE_LENGTH);
            words owners = allocate(arena, CALLABLES);
            words visibility = allocate(arena, CALLABLES);
            words names = allocate(arena, CALLABLES);
            words nameLengths = allocate(arena, CALLABLES);
            words signatures = allocate(arena, CALLABLES);
            words signatureLengths = allocate(arena, CALLABLES);
            words bodies = allocate(arena, CALLABLES);
            words bodyLengths = allocate(arena, CALLABLES);
            words parameterCounts = allocate(arena, CALLABLES);
            words firstParameters = allocate(arena, CALLABLES);
            words resultStarts = allocate(arena, CALLABLES);
            words resultLengths = allocate(arena, CALLABLES);
            words effects = allocate(arena, CALLABLES);
            words slots = allocate(arena, CALLABLES);
            words parameterStarts = allocate(arena, PARAMETERS);
            words parameterLengths = allocate(arena, PARAMETERS);
            words modes = allocate(arena, PARAMETERS);
            words kinds = allocate(arena, MAX_COMPILER_TOKENS);
            words starts = allocate(arena, MAX_COMPILER_TOKENS);
            words lengths = allocate(arena, MAX_COMPILER_TOKENS);
            words moduleRange = allocate(arena, MODULE_WORDS);
            words parameterTotal = allocate(arena, PARAMETER_COUNTER);
            words results = allocate(arena, CALLABLES);
            words types = allocate(arena, PARAMETERS);
            words constants = allocate(arena, CONSTANT_PRODUCT_ROWS);
            words constantStarts = allocate(arena, MAX_CONSTANT_PRODUCTS);
            bytes constantNames = allocateBytes(arena, CONSTANT_NAME_BYTES);
            bytes identity = allocateBytes(arena, IDENTITY_BYTES);
            words report = allocate(arena, REPORT_WORDS);
            SCALAR_WRITES
            long copied = 0;
            while (copied < SOURCE_LENGTH) limit SOURCE_BYTES {
              setByte(selected, copied, input[SOURCE_START + copied]); copied += 1;
            }
            utf8 source = freezeUtf8(selected);
            long callableCount = stageSourceCallableProducts(source, SOURCE_START, 0, 0,
              kinds, starts, lengths, moduleRange, owners, visibility, names, nameLengths,
              signatures, signatureLengths, bodies, bodyLengths, parameterCounts, firstParameters,
              resultStarts, resultLengths, effects, slots, parameterStarts, parameterLengths, modes,
              parameterTotal);
            assert(-1 < callableCount);
            CallableTypeProductPlan typed = materializePrimitiveCallableTypes(input, callableCount,
              parameterTotal[0], resultStarts, resultLengths, firstParameters, parameterCounts,
              parameterStarts, parameterLengths, modes, results, types);
            assert(typed.valid);
            long byte = 0;
            while (byte < SOURCE_BYTES) limit SOURCE_BYTES { setByte(output, byte, 211); byte += 1; }
            long digestByte = 0;
            while (digestByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
              setByte(identity, digestByte, 211); digestByte += 1;
            }
            long reportCell = 0;
            while (reportCell < REPORT_WORDS) limit REPORT_WORDS {
              set(report, reportCell, 211); reportCell += 1;
            }
            phase = 1;
            SourceProductArtifactPlan compiled = compileStructuredArchiveModule(TARGET_KIND,
              input, SOURCE_START, SOURCE_LENGTH, 0,
              input, SOURCE_START + moduleRange[0], moduleRange[1], CLASS_START, CLASS_LENGTH,
              0, callableCount, bodies, bodyLengths,
              CONSTANT_COUNT, constants, constantNames, constantStarts,
              firstParameters, parameterCounts, results, effects, types, modes,
              input, names, nameLengths, output, identity);
            set(report, 0, compiled.length); set(report, 1, compiled.codeStart);
            set(report, 2, compiled.functionCount); set(report, 3, compiled.maxLocalCount);
            set(report, 4, compiled.relocationCount);
            phase = 2;
            drop(report); drop(identity); drop(constantNames); drop(constantStarts); drop(constants);
            drop(types); drop(results); drop(parameterTotal); drop(moduleRange);
            drop(lengths); drop(starts); drop(kinds); drop(modes);
            drop(parameterLengths); drop(parameterStarts); drop(slots); drop(effects);
            drop(resultLengths); drop(resultStarts); drop(firstParameters); drop(parameterCounts);
            drop(bodyLengths); drop(bodies); drop(signatureLengths); drop(signatures);
            drop(nameLengths); drop(names); drop(visibility); drop(owners); drop(source); drop(arena);
          }
        }
        """.replace("FIXTURE_NAME_BYTES", Integer.toString(Math.max(1, nameBytes)))
        .replace("INPUT_START", Integer.toString(sourceStart)).replace("INPUT_LENGTH", Integer.toString(sourceLength))
        .replace("SCALAR_WRITES", scalarWrites).replace("TARGET_KIND", Integer.toString(target))
        .replace("CLASS_START", Integer.toString(classStart)).replace("CLASS_LENGTH", Integer.toString(CLASS_NAME.length()))
        .replace("CONSTANT_COUNT", Integer.toString(constants.size()));
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.source_callable_front_products"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.callable_type_products"));
    CoreSources.addBinaryClosure(modules);
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put("Driver.w", change.apply(driver));
    return new Fixture(new WheelerCompiler().compileModuleFiles(modules, "example.unqualified_archive"),
        expected, (PREFIX + source + SUFFIX).getBytes(StandardCharsets.UTF_8), source);
  }

  private static Program libraryOracle(String source) {
    // Only the oracle needs a module wrapper. Remove its namespace in semantic IR, not in code bytes.
    Program qualified = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Library.w", "module " + ORACLE_MODULE + ";\n" + source), ORACLE_MODULE);
    List<FunctionBody> functions = qualified.functions().stream().map(function -> new FunctionBody(
        function.id(), unqualify(function.name()), function.coherent(), function.parameterCount(),
        function.localTypes(), function.resultType(), function.implicitResultSlot(),
        function.forward(), function.inverse())).toList();
    List<ProofCertificate> proofs = qualified.proofCertificates().stream().map(proof -> new ProofCertificate(
        proof.id(), unqualify(proof.name()), proof.rule(), proof.subjectId(), proof.argument())).toList();
    return new Program(qualified.name(), qualified.kind(), qualified.entryFunctionId(), qualified.globals(),
        qualified.recordTypes(), qualified.variantTypes(), qualified.arrayTypes(), qualified.sliceTypes(),
        functions, proofs, qualified.quantumRegisters(), qualified.quantumCircuits(), qualified.workflow(),
        qualified.requiredInstructionExtensions(), qualified.maxHistoryRecords(), qualified.maxSteps());
  }

  private static String unqualify(String name) {
    String prefix = ORACLE_MODULE + "::";
    return name.startsWith(prefix) ? name.substring(prefix.length()) : name;
  }
}
