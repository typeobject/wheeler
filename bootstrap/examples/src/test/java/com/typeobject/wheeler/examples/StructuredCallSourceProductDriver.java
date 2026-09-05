package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

/** Builds native structured-call source-product fixtures. */
final class StructuredCallSourceProductDriver {
  record SymbolProduct(int start, int length, int type, long value, int resolved) {
    static SymbolProduct none() {
      return new SymbolProduct(-1, 0, 0, 0, 0);
    }

    boolean present() {
      return 0 <= start;
    }
  }

  private StructuredCallSourceProductDriver() {}

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType) throws Exception {
    return driver(bodyStart, bodyLength, parameterCount, firstType, secondType, false);
  }

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported) throws Exception {
    return driver(
        bodyStart,
        bodyLength,
        parameterCount,
        firstType,
        secondType,
        imported,
        1,
        1);
  }

  static Program driver(
      int bodyStart,
      int bodyLength,
      int parameterCount,
      int firstType,
      int secondType,
      boolean imported,
      int importedParameterType,
      int importedResultType) throws Exception {
    return driverWithEffect(
        bodyStart,
        bodyLength,
        parameterCount,
        firstType,
        secondType,
        imported,
        importedParameterType,
        importedResultType,
        0);
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
      int callableEffect) throws Exception {
    return driverWithSymbol(
        bodyStart, bodyLength, parameterCount, firstType, secondType, imported,
        importedParameterType, importedResultType, callableEffect, SymbolProduct.none());
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
      SymbolProduct symbol) throws Exception {
    int[] parameterTypes = new int[parameterCount];
    Arrays.fill(parameterTypes, firstType);
    if (1 < parameterCount) {
      parameterTypes[1] = secondType;
    }
    int[] importedTypes = new int[parameterCount];
    Arrays.fill(importedTypes, importedParameterType);
    return driverWithParameters(
        bodyStart, bodyLength, parameterTypes, imported, importedTypes,
        importedResultType, callableEffect, symbol);
  }

  static Program driverWithParameters(
      int bodyStart,
      int bodyLength,
      int[] parameterTypes,
      boolean imported,
      int[] importedTypes,
      int importedResultType,
      int callableEffect,
      SymbolProduct symbol) throws Exception {
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
    sources.put("StructuredCallSourceProductExample.w", """
        module example.structured_call_source_product;

        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.structured_source_module_compiler;
        import wheeler.core.encoding.binary;

        classical class StructuredCallSourceProductExample {
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
            region publication = new region(/* bytes= */ 32800, /* allocations= */ 2);
            region products = new region(/* bytes= */ 2903904, /* allocations= */ 19);
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
            words callableEffects = allocate(products, /* length= */ 4096);
            bytes strings = allocateBytes(products, /* length= */ 32768);
            words stringStarts = allocate(products, /* length= */ 256);
            words stringLengths = allocate(products, /* length= */ 256);
            words functionNameIds = allocate(products, /* length= */ 64);
            bytes artifact = allocateBytes(publication, /* length= */ 32768);
            bytes identity = allocateBytes(publication, /* length= */ 32);
            words importedRows = allocate(products, /* length= */ 32768);
            words importedParameterRows = allocate(products, /* length= */ 32768);
            bytes importedNames = allocateBytes(products, /* length= */ 1048576);
            bytes importedIdentities = allocateBytes(products, /* length= */ 131072);
            region qualifiers = new region(/* bytes= */ 1146880, /* allocations= */ 4);
            bytes qualifierNames = allocateBytes(qualifiers, /* length= */ 1048576);
            words qualifierNameStarts = allocate(qualifiers, /* length= */ 4096);
            words qualifierNameLengths = allocate(qualifiers, /* length= */ 4096);
            words qualifierRanks = allocate(qualifiers, /* length= */ 4096);
            region relocations = new region(/* bytes= */ 16384, /* allocations= */ 3);
            words relocationRows = allocate(relocations, /* length= */ 768);
            words relocationOwners = allocate(relocations, /* length= */ 256);
            bytes relocationIdentities = allocateBytes(relocations, /* length= */ 8192);
            IMPORTED_SETUP
            SYMBOL_SETUP
            set(bodyStarts, 0, BODY_START);
            set(bodyLengths, 0, BODY_LENGTH);
            SIGNATURE_SETUP
            set(parameterCounts, 0, PARAMETER_COUNT);
            set(callableEffects, 0, CALLABLE_EFFECT);
            writeAscii(strings, 0, "$library");
            writeAscii(strings, 8, "StructuredCall");
            writeAscii(strings, 22, "example.structured_call::recurse");
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 8);
            set(stringStarts, 1, 8);
            set(stringLengths, 1, 14);
            set(stringStarts, 2, 22);
            set(stringLengths, 2, 32);
            set(functionNameIds, 0, 2);
            SourceProductArtifactPlan plan = compileStructuredSourceModuleWithTargets(
              input,
              /* archiveSourceStart= */ 0,
              /* moduleOwner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
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
              strings,
              /* stringBytes= */ 54,
              /* stringCount= */ 3,
              stringStarts,
              stringLengths,
              functionNameIds,
              relocationRows,
              relocationOwners,
              relocationIdentities,
              artifact,
              identity
            );
            long artifactByte = 0;
            while (artifactByte < plan.length) limit 32768 {
              setByte(output, artifactByte, artifact[artifactByte]);
              artifactByte += 1;
            }
            setOutputLength(output, plan.length);
            artifactLength = plan.length;
            functionCount = plan.functionCount;
            maxLocalCount = plan.maxLocalCount;
            relocationCount = plan.relocationCount;
            if (0 < plan.relocationCount) {
              relocationTarget = relocationRows[256];
              relocationInstruction = relocationRows[0];
              relocationOwner = relocationOwners[0];
              relocationIdentityByte = relocationIdentities[0];
            }
            region decoded = new region(/* bytes= */ 201728, /* allocations= */ 2);
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
            region linker = new region(/* bytes= */ 983040, /* allocations= */ 7);
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
            drop(functionNameIds);
            drop(stringLengths);
            drop(stringStarts);
            drop(strings);
            drop(callableEffects);
            drop(parameterCounts);
            drop(signatureTypes);
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
        """.replace("BODY_START", Integer.toString(bodyStart))
            .replace("BODY_LENGTH", Integer.toString(bodyLength))
            .replace("PARAMETER_COUNT", Integer.toString(parameterTypes.length))
            .replace("SIGNATURE_SETUP", signatureRows(parameterTypes))
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
                ? "set(symbolOwners, 0, 0);\n"
                    + "set(symbolStarts, 0, " + symbol.start() + ");\n"
                    + "set(symbolLengths, 0, " + symbol.length() + ");\n"
                    + "set(symbolTypes, 0, " + symbol.type() + ");\n"
                    + "set(symbolValues, 0, " + symbol.value() + ");\n"
                    + "set(symbolResolved, 0, " + symbol.resolved() + ");"
                : ""));
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
