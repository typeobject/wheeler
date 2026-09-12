package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.examples.constants.ConstantProductSource;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/** Builds native structured-call source-product fixtures. */
public final class StructuredCallSourceProductDriver {
  record SymbolProduct(String name, int type, long value, int resolved) {
    SymbolProduct {
      if (!name.isEmpty() && !name.matches("[A-Za-z_][A-Za-z0-9_]{0,255}")) {
        throw new IllegalArgumentException("invalid fixture constant name");
      }
    }

    static SymbolProduct none() {
      return new SymbolProduct("", 0, 0, 0);
    }

    boolean present() {
      return !name.isEmpty();
    }
  }

  record ResultProduct(int callableCount, int capacity, int row, int type) {}

  private StructuredCallSourceProductDriver() {}

  static Program driverWithResultProduct(int bodyStart, int bodyLength, ResultProduct result)
      throws Exception {
    return driverWithProducts(bodyStart, bodyLength, new int[] {1}, false, new int[] {1},
        1, 0, SymbolProduct.none(), result, List.of(), new long[0]);
  }

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      int resultType) throws Exception {
    return driver(bodyStart, bodyLength, parameterCount, firstType, secondType, false, resultType);
  }

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int resultType) throws Exception {
    return driver(
        bodyStart,
        bodyLength,
        parameterCount,
        firstType,
        secondType,
        imported,
        1,
        1,
        resultType);
  }

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int importedParameterType,
      int importedResultType,
      int resultType) throws Exception {
    return driverWithEffect(
        bodyStart,
        bodyLength,
        parameterCount,
        firstType,
        secondType,
        imported,
        importedParameterType,
        importedResultType,
        0,
        resultType);
  }

  static Program driverWithEffect(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int importedParameterType,
      int importedResultType,
      int callableEffect,
      int resultType) throws Exception {
    return driverWithSymbol(
        bodyStart, bodyLength, parameterCount, firstType, secondType, imported,
        importedParameterType, importedResultType, callableEffect, SymbolProduct.none(), resultType);
  }

  static Program driverWithSymbol(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int importedParameterType,
      int importedResultType,
      int callableEffect,
      SymbolProduct symbol,
      int resultType) throws Exception {
    int[] parameterTypes = new int[parameterCount];
    Arrays.fill(parameterTypes, firstType);
    if (1 < parameterCount) {
      parameterTypes[1] = secondType;
    }
    int[] importedTypes = new int[parameterCount];
    Arrays.fill(importedTypes, importedParameterType);
    return driverWithParameters(
        bodyStart, bodyLength, parameterTypes, imported, importedTypes,
        importedResultType, callableEffect, symbol, resultType);
  }

  static Program driverWithParameters(
      int bodyStart,
      int bodyLength,
      int[] parameterTypes,
      boolean imported,
      int[] importedTypes,
      int importedResultType,
      int callableEffect,
      SymbolProduct symbol,
      int resultType) throws Exception {
    return driverWithProducts(bodyStart, bodyLength, parameterTypes, imported, importedTypes,
        importedResultType, callableEffect, symbol, new ResultProduct(1, 64, 0, resultType), List.of(), new long[0]);
  }

  /** Supplies detached imported signatures and declaration-ordered globals, never dependency bodies. */
  public static Program driverWithGlobals(
      int bodyStart, int bodyLength, int[] importedTypes, int importedResultType,
      List<Global> globals, long[] declarationStarts) throws Exception {
    return driverWithProducts(bodyStart, bodyLength, new int[] {1}, true, importedTypes,
        importedResultType, 0, SymbolProduct.none(), new ResultProduct(1, 64, 0, 1), globals,
        declarationStarts);
  }

  private static Program driverWithProducts(
      int bodyStart, int bodyLength, int[] parameterTypes, boolean imported, int[] importedTypes,
      int importedResultType, int callableEffect, SymbolProduct symbol, ResultProduct result,
      List<Global> globals, long[] declarationStarts) throws Exception {
    if (globals.size() != declarationStarts.length) {
      throw new IllegalArgumentException("fixture declarations must cover every global");
    }
    String className = "StructuredCall";
    String callableName = "example.structured_call::recurse";
    var names = new TreeSet<>(List.of("$library", className, callableName));
    for (Global global : globals) {
      if (!global.name().matches("[A-Za-z_][A-Za-z0-9_]{0,255}")) {
        throw new IllegalArgumentException("fixture globals require ASCII identifiers");
      }
      names.add(global.name());
    }
    var stringTable = List.copyOf(names);
    var starts = new LinkedHashMap<String, Integer>();
    int stringBytes = 0;
    var stringSetup = new StringBuilder();
    for (int index = 0; index < stringTable.size(); index++) {
      String name = stringTable.get(index);
      starts.put(name, stringBytes);
      stringSetup.append("writeAscii(strings, ").append(stringBytes).append(", \"")
          .append(name).append("\");\nset(stringStarts, ").append(index).append(", ")
          .append(stringBytes).append(");\nset(stringLengths, ").append(index).append(", ")
          .append(name.length()).append(");\n");
      stringBytes += name.length();
    }
    for (int ordinal = 0; ordinal < globals.size(); ordinal++) {
      Global global = globals.get(ordinal);
      stringSetup.append("set(globals, ").append(ordinal).append(", ")
          .append(starts.get(global.name())).append(");\n")
          .append("set(globals, SOURCE_GLOBAL_LENGTH_ROW + ").append(ordinal).append(", ")
          .append(global.name().length()).append(");\n")
          .append("set(globals, SOURCE_GLOBAL_VALUE_ROW + ").append(ordinal).append(", ")
          .append(global.initialValue()).append(");\n")
          .append("set(globals, SOURCE_GLOBAL_DECLARATION_ROW + ").append(ordinal).append(", ")
          .append(declarationStarts[ordinal]).append(");\n")
          .append("set(globals, SOURCE_GLOBAL_NAME_ID_ROW + ").append(ordinal).append(", ")
          .append(stringTable.indexOf(global.name())).append(");\n");
    }
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.structured_source_module_compiler"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_function_rows"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("StructuredCallSourceProductExample.w", ConstantProductSource.expand("""
        module example.structured_call_source_product;

        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;
        import wheeler.compiler.closure.source_global_schema;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.structured_source_module_compiler;
        import wheeler.compiler.constant_product_schema;
        import wheeler.core.encoding.binary;

        classical class StructuredCallSourceProductExample {
          CONSTANT_PRODUCT_LIMITS
          const long GLOBAL_BYTES = SOURCE_GLOBAL_PUBLICATION_ROWS * FIXTURE_WORD_BYTES;
          const long ARTIFACT_BYTES = 32768;
          const long IDENTITY_BYTES = 256 / 8;
          const long PUBLICATION_BYTES = ARTIFACT_BYTES + IDENTITY_BYTES;
          const long PUBLICATION_BUFFERS = 2;
          const long SENTINEL = 211;
          const long CALLABLES = 4096;
          const long SOURCE_FUNCTIONS = 64;
          const long SYMBOLS = 16384;
          const long STRINGS = 256;
          const long PARAMETERS = 16384;
          const long NAME_BYTES = 1048576;
          const long BODY_COLUMNS = 2;
          const long SYMBOL_COLUMNS = 6;
          const long SIGNATURE_COLUMNS = 3;
          const long IMPORTED_COLUMNS = 8;
          const long PARAMETER_COLUMNS = 2;
          const long PRODUCT_WORDS = BODY_COLUMNS * CALLABLES + SYMBOL_COLUMNS * SYMBOLS
            + SIGNATURE_COLUMNS * CALLABLES + SOURCE_FUNCTIONS * 2 + RESULT_CAPACITY + CALLABLES
            + STRINGS * 2 + IMPORTED_COLUMNS * CALLABLES + PARAMETER_COLUMNS * PARAMETERS;
          const long PRODUCT_BYTES = PRODUCT_WORDS * FIXTURE_WORD_BYTES + ARTIFACT_BYTES
            + NAME_BYTES + CALLABLES * IDENTITY_BYTES;
          const long PRODUCT_BUFFERS = BODY_COLUMNS + SYMBOL_COLUMNS + 4 + 4 + 4;
          const long QUALIFIER_BUFFERS = 4;
          const long QUALIFIER_BYTES = NAME_BYTES + CALLABLES * (QUALIFIER_BUFFERS - 1) * FIXTURE_WORD_BYTES;
          const long CALLS = 256;
          const long RELOCATION_COLUMNS = 3;
          const long RELOCATION_BYTES = CALLS * (RELOCATION_COLUMNS + 1) * FIXTURE_WORD_BYTES
            + CALLS * IDENTITY_BYTES;
          const long DECODED_BYTES = (640 + 24576) * FIXTURE_WORD_BYTES;
          const long LINKED_BYTES = (8192 * 2 + CALLABLES * 2 + 65536) * FIXTURE_WORD_BYTES
            + CALLABLES * IDENTITY_BYTES * 2;
          state long prepared = 0;
          state long published = 0;
          state long valid = 0;
          state long artifactLength = 0;
          state long functionCount = 0;
          state long maxLocalCount = 0;
          state long relocationCount = 0;
          state long relocationTarget = 0;
          state long relocationInstruction = -1;
          state long relocationOwner = -1;
          state long relocationIdentityByte = 0;
          state long retainedFunctionCount = 0;
          state long excludedFunctionCount = 0;
          state long resolvedFunctionTarget = -1;
          state long instructionFourSecondOperand = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region publication = new region(PUBLICATION_BYTES, PUBLICATION_BUFFERS);
            region products = new region(PRODUCT_BYTES, PRODUCT_BUFFERS);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words symbolOwners = allocate(products, /* length= */ 16384);
            words symbolStarts = allocate(products, /* length= */ 16384);
            words symbolLengths = allocate(products, /* length= */ 16384);
            words symbolTypes = allocate(products, /* length= */ 16384);
            words symbolValues = allocate(products, /* length= */ 16384);
            words symbolResolved = allocate(products, /* length= */ 16384);
            words signatureTypes = allocate(products, /* length= */ 12288);
            words parameterCounts = allocate(products, /* length= */ 64);
            words declaredResultTypes = allocate(products, /* length= */ RESULT_CAPACITY);
            words callableEffects = allocate(products, /* length= */ 4096);
            bytes strings = allocateBytes(products, /* length= */ 32768);
            words stringStarts = allocate(products, /* length= */ 256);
            words stringLengths = allocate(products, /* length= */ 256);
            words functionNameIds = allocate(products, /* length= */ 64);
            region globalArena = new region(GLOBAL_BYTES, /* buffers= */ 1);
            words globals = allocate(globalArena, SOURCE_GLOBAL_PUBLICATION_ROWS);
            bytes artifact = allocateBytes(publication, /* length= */ 32768);
            bytes identity = allocateBytes(publication, /* length= */ 32);
            long publicationByte = 0;
            while (publicationByte < ARTIFACT_BYTES) limit ARTIFACT_BYTES {
              setByte(artifact, publicationByte, SENTINEL);
              publicationByte += 1;
            }
            long digestByte = 0;
            while (digestByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
              setByte(identity, digestByte, SENTINEL);
              digestByte += 1;
            }
            words importedRows = allocate(products, /* length= */ 32768);
            words importedParameterRows = allocate(products, /* length= */ 32768);
            bytes importedNames = allocateBytes(products, /* length= */ 1048576);
            bytes importedIdentities = allocateBytes(products, /* length= */ 131072);
            region qualifiers = new region(QUALIFIER_BYTES, QUALIFIER_BUFFERS);
            bytes qualifierNames = allocateBytes(qualifiers, /* length= */ 1048576);
            words qualifierNameStarts = allocate(qualifiers, /* length= */ 4096);
            words qualifierNameLengths = allocate(qualifiers, /* length= */ 4096);
            words qualifierRanks = allocate(qualifiers, /* length= */ 4096);
            region relocations = new region(RELOCATION_BYTES, RELOCATION_COLUMNS);
            words relocationRows = allocate(relocations, /* length= */ 768);
            words relocationOwners = allocate(relocations, /* length= */ 256);
            bytes relocationIdentities = allocateBytes(relocations, /* length= */ 8192);
            IMPORTED_SETUP
            SYMBOL_SETUP
            set(bodyStarts, 0, BODY_START);
            set(bodyLengths, 0, BODY_LENGTH);
            SIGNATURE_SETUP
            set(parameterCounts, 0, PARAMETER_COUNT);
            set(declaredResultTypes, RESULT_ROW, DECLARED_RESULT);
            set(callableEffects, 0, CALLABLE_EFFECT);
            STRING_SETUP
            set(functionNameIds, 0, FUNCTION_NAME_ID);
            CONSTANT_PRODUCT_SETUP
            prepared = 1;
            SourceProductArtifactPlan plan = compileStructuredSourceModuleWithTargets(
              /* classNameId= */ CLASS_NAME_ID, /* globalCount= */ GLOBAL_COUNT,
              /* globalProductStart= */ 0,
              globals,
              input,
              /* symbolNames= */ strings,
              /* constantNames= */ strings,
              proofConstants,
              /* archiveSourceStart= */ 0,
              /* moduleOwner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ CALLABLE_COUNT,
              callableEffects,
              /* importedTargetCount= */ IMPORTED_COUNT,
              importedRows,
              importedParameterRows,
              importedNames,
              importedIdentities,
              qualifierNames,
              qualifierNameStarts,
              qualifierNameLengths,
              qualifierRanks,
              bodyStarts,
              bodyLengths,
              /* symbolCount= */ SYMBOL_COUNT,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              /* signatureTypeCount= */ PARAMETER_COUNT,
              signatureTypes,
              parameterCounts,
              declaredResultTypes,
              strings,
              /* stringBytes= */ STRING_BYTES,
              /* stringCount= */ STRING_COUNT,
              stringStarts,
              stringLengths,
              functionNameIds,
              relocationRows,
              relocationOwners,
              relocationIdentities,
              artifact,
              identity
            );
            artifactLength = plan.length;
            published = 1;
            long artifactByte = 0;
            while (artifactByte < plan.length) limit 32768 {
              setByte(output, artifactByte, artifact[artifactByte]);
              artifactByte += 1;
            }
            setOutputLength(output, plan.length);
            functionCount = plan.functionCount;
            maxLocalCount = plan.maxLocalCount;
            relocationCount = plan.relocationCount;
            if (0 < plan.relocationCount) {
              relocationTarget = relocationRows[256];
              relocationInstruction = relocationRows[0];
              relocationOwner = relocationOwners[0];
              relocationIdentityByte = relocationIdentities[0];
            }
            region decoded = new region(DECODED_BYTES, /* allocations= */ 2);
            words functionRows = allocate(decoded, /* length= */ 640);
            words instructionRows = allocate(decoded, /* length= */ 24576);
            CompiledFunctionPlan compiled = indexCompiledFunctionProducts(
              artifact,
              plan.length,
              functionRows,
              instructionRows
            );
            if (4 < compiled.instructionCount) {
              instructionFourSecondOperand = readSigned(
                artifact,
                instructionRows[8196] + 16
              );
            }
            RetainedFunctionProduct retained = retainLocalFunctionProduct(
              /* localFunctionCount= */ 1,
              compiled.functionCount,
              compiled.instructionCount,
              instructionRows
            );
            retainedFunctionCount = retained.functionCount;
            excludedFunctionCount = retained.excludedFunctionCount;
            drop(instructionRows);
            drop(functionRows);
            drop(decoded);
            region linker = new region(LINKED_BYTES, /* allocations= */ 7);
            words hashSlots = allocate(linker, /* length= */ 8192);
            words hashFunctions = allocate(linker, /* length= */ 8192);
            bytes callableIdentities = allocateBytes(linker, /* length= */ 131072);
            bytes functionIdentities = allocateBytes(linker, /* length= */ 131072);
            words callableFunctions = allocate(linker, /* length= */ 4096);
            words publishedFunctions = allocate(linker, /* length= */ 4096);
            words resolvedTargets = allocate(linker, /* length= */ 65536);
            long linkedIdentityByte = 0;
            while (linkedIdentityByte < 32) limit 32 {
              setByte(
                callableIdentities,
                linkedIdentityByte,
                relocationIdentities[linkedIdentityByte]
              );
              setByte(
                functionIdentities,
                linkedIdentityByte,
                relocationIdentities[linkedIdentityByte]
              );
              linkedIdentityByte += 1;
            }
            mapCallableFunctionRows(
              /* callableCount= */ 1,
              callableIdentities,
              /* functionCount= */ 1,
              functionIdentities,
              hashSlots,
              hashFunctions,
              callableFunctions,
              publishedFunctions
            );
            resolveImportedIdentityFunctionTargets(
              plan.relocationCount,
              relocationIdentities,
              /* functionCount= */ 1,
              functionIdentities,
              hashSlots,
              hashFunctions,
              resolvedTargets
            );
            resolvedFunctionTarget = resolvedTargets[0];
            drop(resolvedTargets);
            drop(publishedFunctions);
            drop(callableFunctions);
            drop(functionIdentities);
            drop(callableIdentities);
            drop(hashFunctions);
            drop(hashSlots);
            drop(linker);
            valid = 1;
            drop(relocationIdentities);
            drop(relocationOwners);
            drop(relocationRows);
            drop(relocations);
            drop(qualifierRanks);
            drop(qualifierNameLengths);
            drop(qualifierNameStarts);
            drop(qualifierNames);
            drop(qualifiers);
            drop(importedIdentities);
            drop(importedNames);
            drop(importedParameterRows);
            drop(importedRows);
            drop(identity);
            drop(artifact);
            drop(publication);
            drop(globals); drop(globalArena);
            drop(functionNameIds);
            drop(stringLengths);
            drop(stringStarts);
            drop(strings);
            drop(callableEffects);
            drop(declaredResultTypes);
            drop(parameterCounts);
            drop(signatureTypes);
            CONSTANT_PRODUCT_CLEANUP
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.replace("STRING_SETUP", stringSetup)
            .replace("FUNCTION_NAME_ID", Integer.toString(stringTable.indexOf(callableName)))
            .replace("CLASS_NAME_ID", Integer.toString(stringTable.indexOf(className)))
            .replace("STRING_BYTES", Integer.toString(stringBytes))
            .replace("STRING_COUNT", Integer.toString(stringTable.size()))
            .replace("GLOBAL_COUNT", Integer.toString(globals.size()))
            .replace("BODY_START", Integer.toString(bodyStart))
            .replace("BODY_LENGTH", Integer.toString(bodyLength))
            .replace("PARAMETER_COUNT", Integer.toString(parameterTypes.length))
            .replace("SIGNATURE_SETUP", signatureRows(parameterTypes))
            .replace("RESULT_CAPACITY", Integer.toString(result.capacity()))
            .replace("RESULT_ROW", Integer.toString(result.row()))
            .replace("DECLARED_RESULT", Integer.toString(result.type()))
            .replace("CALLABLE_COUNT", Integer.toString(result.callableCount()))
            .replace("CALLABLE_EFFECT", Integer.toString(callableEffect))
            .replace("IMPORTED_COUNT", imported ? "2" : "0")
            .replace("IMPORTED_SETUP", imported
                ? "writeAscii(importedNames, 0, \"remoteunused\");\n"
                    + "writeAscii(qualifierNames, 0, \"dep.alphadep.beta\");\n"
                    + "set(qualifierNameLengths, 0, 9);\n"
                    + "set(qualifierNameStarts, 1, 9);\n"
                    + "set(qualifierNameLengths, 1, 8);\n"
                    + "set(importedRows, 12288, 6);\n"
                    + "set(importedRows, 20480, IMPORTED_PARAMETER_COUNT);\n"
                    + "set(importedRows, 24576, IMPORTED_RESULT_TYPE);\n"
                    + "set(importedRows, 28672, " + callableEffect + ");\n"
                    + "set(importedRows, 4097, 1);\n"
                    + "set(importedRows, 8193, 6);\n"
                    + "set(importedRows, 12289, 6);\n"
                    + "set(importedRows, 16385, IMPORTED_PARAMETER_COUNT);\n"
                    + "set(importedRows, 20481, IMPORTED_PARAMETER_COUNT);\n"
                    + "set(importedRows, 24577, IMPORTED_RESULT_TYPE);\n"
                    + "set(importedRows, 28673, " + callableEffect + ");\n"
                    + importedParameterRows(importedTypes)
                    + "setByte(importedIdentities, 0, 42);\n"
                    + "setByte(importedIdentities, 32, 43);"
                : "")
            .replace("IMPORTED_PARAMETER_COUNT", Integer.toString(importedTypes.length))
            .replace("IMPORTED_RESULT_TYPE", Integer.toString(importedResultType))
            .replace("SYMBOL_COUNT", symbol.present() ? "1" : "0")
            .replace("SYMBOL_SETUP", symbol.present()
                ? "writeAscii(strings, 128, \"" + symbol.name() + "\");\n"
                    + "set(symbolOwners, 0, 0);\n"
                    + "set(symbolStarts, 0, 128);\n"
                    + "set(symbolLengths, 0, " + symbol.name().length() + ");\n"
                    + "set(symbolTypes, 0, " + symbol.type() + ");\n"
                    + "set(symbolValues, 0, " + symbol.value() + ");\n"
                    + "set(symbolResolved, 0, " + symbol.resolved() + ");"
                : ""), symbol.present() ? 1 : 0));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.structured_call_source_product");
  }

  private static String signatureRows(int[] types) {
    StringBuilder rows = new StringBuilder();
    for (int index = 0; index < types.length; index++) {
      rows.append("set(signatureTypes, ").append(4096 + index).append(", ")
          .append(index).append(");\n");
      rows.append("set(signatureTypes, ").append(8192 + index).append(", ")
          .append(types[index]).append(");\n");
    }
    return rows.toString();
  }

  private static String importedParameterRows(int[] types) {
    StringBuilder rows = new StringBuilder();
    for (int target = 0; target < 2; target++) {
      for (int index = 0; index < types.length; index++) {
        rows.append("set(importedParameterRows, ").append(target * types.length + index)
            .append(", ").append(types[index]).append(");\n");
      }
    }
    return rows.toString();
  }
}
