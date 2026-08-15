package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Builds the production counted archive-closure evidence program. */
final class NativeCompilerArchiveClosureProgram {
  record PhysicalModule(String path, String name) {}

  private static final List<String> MODULE_NAMES = CompilerSources.sortedModuleNames();
  static final List<PhysicalModule> PHYSICAL_MODULES = NativeCompilerPhysicalModules.all();
  static final List<PhysicalModule> PHYSICAL_CALLABLE_MODULES =
      NativeCompilerPhysicalModules.importedCallableProducts();
  static final PhysicalModule PHYSICAL_REVERSIBLE_MODULE = PHYSICAL_MODULES.stream()
      .filter(module -> module.name().equals(
          "wheeler.compiler.closure.reversible_token_coordinates"))
      .findFirst()
      .orElseThrow();

  private NativeCompilerArchiveClosureProgram() {}

  private static String physicalOwnerRows(
      List<PhysicalModule> comparableModules,
      List<PhysicalModule> callableModules) {
    StringBuilder rows = new StringBuilder();
    for (int index = 0; index < comparableModules.size(); index++) {
      rows.append("set(physicalOwners, ").append(index).append(", ")
          .append(physicalOwner(comparableModules.get(index))).append(");\n");
    }
    for (int index = 0; index < callableModules.size(); index++) {
      rows.append("set(physicalOwners, ").append(comparableModules.size() + index)
          .append(", ").append(physicalOwner(callableModules.get(index)))
          .append(");\n");
    }
    return rows.toString();
  }

  static int physicalOwner(PhysicalModule module) {
    int owner = MODULE_NAMES.indexOf(module.name());
    if (owner < 0) {
      throw new IllegalStateException(
          "Physical module is outside compiler target: " + module.name());
    }
    return owner;
  }

  static Program program() throws Exception {
    return program(
        /* compilePhysicalProducts= */ true,
        PHYSICAL_MODULES,
        PHYSICAL_CALLABLE_MODULES);
  }

  static Program structuredProductProgram() throws Exception {
    return program(
        /* compilePhysicalProducts= */ true,
        List.of(PHYSICAL_MODULES.getLast()),
        List.of());
  }

  static Program reversibleProductProgram() throws Exception {
    return program(
        /* compilePhysicalProducts= */ true,
        List.of(PHYSICAL_REVERSIBLE_MODULE),
        List.of());
  }

  static Program metadataProgram() throws Exception {
    return program(
        /* compilePhysicalProducts= */ false,
        PHYSICAL_MODULES,
        PHYSICAL_CALLABLE_MODULES);
  }

  private static Program program(
      boolean compilePhysicalProducts,
      List<PhysicalModule> comparableModules,
      List<PhysicalModule> callableModules) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_module_sources"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_dependency_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_function_rows"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.callable_identities"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_type_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_callable_bodies"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_body_archive"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_constant_executor"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_call_relocations"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_constant_values"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.module_callables"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.module_symbols"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.package_target"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.product_root_source"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.plan"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.schedule"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.scalar_module_identities"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("ArchiveClosureExample.w", """
        module example.archive_closure;

        import wheeler.compiler.closure.archive_module_sources;
        import wheeler.compiler.closure.archive_sources;
        import wheeler.compiler.closure.callable_dependency_products;
        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.callable_identities;
        import wheeler.compiler.closure.callable_type_products;
        import wheeler.compiler.closure.compiled_body_archive;
        import wheeler.compiler.closure.compiled_callable_bodies;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.counted_constant_executor;
        import wheeler.compiler.closure.imported_call_relocations;
        import wheeler.compiler.closure.imported_callable_stubs;
        import wheeler.compiler.closure.imported_constant_values;
        import wheeler.compiler.closure.module_callables;
        import wheeler.compiler.closure.module_manifest;
        import wheeler.compiler.closure.module_symbols;
        import wheeler.compiler.closure.package_target;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.closure.product_root_source;
        import wheeler.compiler.closure.scalar_module_identities;
        import wheeler.compiler.closure.schedule;
        import wheeler.compiler.closure.source_call_products;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.symbol_identities;

        classical class ArchiveClosureExample {
          private const long MAX_ARCHIVE_BYTES = 16777216;
          private const long MAX_EXTERNALS = 64;
          private const long MAX_IMPORTS = 3072;
          private const long MAX_MANIFEST_BYTES = 262144;
          private const long MAX_MODULES = 512;
          private const long MAX_SYMBOLS = 16384;

          state long moduleCount = 0;
          state long importCount = 0;
          state long archiveEntryCount = 0;
          state long rootEntry = 0;
          state long rootDataStart = 0;
          state long rootDataLength = 0;
          state long rootOrder = 0;
          state long rootExecutable = 0;
          state long executableCount = 0;
          state long peakActiveSources = 0;
          state long rootGeneration = 0;
          state long compilerTarget = -1;
          state long symbolCount = 0;
          state long resolvedSymbolCount = 0;
          state long rootLocalSymbols = 0;
          state long rootImportedSymbols = 0;
          state long maxImportedSymbols = 0;
          state long symbolGeneration = 0;
          state long callableCount = 0;
          state long callableParameterCount = 0;
          state long borrowedParameterCount = 0;
          state long mutableParameterCount = 0;
          state long resultSlotCallableCount = 0;
          state long rootLocalCallables = 0;
          state long rootImportedCallables = 0;
          state long maxImportedCallables = 0;
          state long callableGeneration = 0;
          state long firstCallableSignatureLength = 0;
          state long firstCallableBodyLength = 0;
          state long firstCallableResultTypeLength = 0;
          state long lastCallableParameterCount = 0;
          state long lastCallableEffects = 0;
          state long firstCallableIdentityPrefix = 0;
          state long lastCallableIdentityPrefix = 0;
          state long callableIdentitiesPublished = 0;
          state long invalidCallableIdentityRejected = 0;
          state long compiledCallableBodyLength = 0;
          state long compiledCallableBodyIdentityPrefix = 0;
          state long compiledCallableModuleLength = 0;
          state long compiledCallableModuleIdentityPrefix = 0;
          state long compiledCallableFunctionCount = 0;
          state long compiledCallableMaxLocalCount = 0;
          state long physicalModuleProductLength = 0;
          state long physicalModuleProductFunctions = 0;
          state long physicalModuleProductCount = 0;
          state long physicalCallableProductCount = 0;
          state long physicalCallableRelocationCount = 0;
          state long physicalResolvedCallableTargetCount = 0;
          state long physicalRetainedProductLength = 0;
          state long physicalRetainedFunctionCount = 0;
          state long physicalRetainedInstructionCount = 0;
          state long physicalArchivedProductLength = 0;
          state long physicalArchivedProductCount = 0;
          state long physicalModuleOwner = -1;
          state long packageIdentityPrefix = 0;
          state long firstSymbolIdentityPrefix = 0;
          state long lastSymbolIdentityPrefix = 0;
          state long firstModuleIdentityPrefix = 0;
          state long lastModuleIdentityPrefix = 0;
          state long moduleIdentitiesPublished = 0;
          state long lastSymbolValue = 0;
          state long lastSymbolResolved = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            long archiveLength = source[0]
              + source[1] * 256
              + source[2] * 65536
              + source[3] * 16777216;
            assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
            long manifestLength = bufferLength(source) - archiveLength - 4;
            assert(0 < manifestLength);
            assert(manifestLength < MAX_MANIFEST_BYTES + 1);
            region inputArena = new region(/* bytes= */ 17039360, /* allocations= */ 2);
            bytes archive = allocateBytes(inputArena, archiveLength);
            bytes manifest = allocateBytes(inputArena, manifestLength);
            long cursor = 0;
            while (cursor < archiveLength) limit MAX_ARCHIVE_BYTES {
              setByte(archive, cursor, source[cursor + 4]);
              cursor += 1;
            }

            cursor = 0;
            while (cursor < manifestLength) limit MAX_MANIFEST_BYTES {
              setByte(manifest, cursor, source[archiveLength + cursor + 4]);
              cursor += 1;
            }

            region columns = new region(/* bytes= */ 6627368, /* allocations= */ 95);
            words archivePathStarts = allocate(columns, MAX_MODULES);
            words archivePathLengths = allocate(columns, MAX_MODULES);
            words archiveDataStarts = allocate(columns, MAX_MODULES);
            words archiveDataLengths = allocate(columns, MAX_MODULES);
            words externalStarts = allocate(columns, MAX_EXTERNALS);
            words externalLengths = allocate(columns, MAX_EXTERNALS);
            words moduleStarts = allocate(columns, MAX_MODULES);
            words moduleLengths = allocate(columns, MAX_MODULES);
            words sourceStarts = allocate(columns, MAX_MODULES);
            words sourceLengths = allocate(columns, MAX_MODULES);
            words identityStarts = allocate(columns, MAX_MODULES);
            words edgeOwners = allocate(columns, MAX_IMPORTS);
            words edgeStarts = allocate(columns, MAX_IMPORTS);
            words edgeLengths = allocate(columns, MAX_IMPORTS);
            words edgeTargets = allocate(columns, MAX_IMPORTS);
            words moduleEntries = allocate(columns, MAX_MODULES);
            words archiveSourceStarts = allocate(columns, MAX_MODULES);
            words archiveSourceLengths = allocate(columns, MAX_MODULES);
            words firstImports = allocate(columns, MAX_MODULES);
            words directImportCounts = allocate(columns, MAX_MODULES);
            words importRanks = allocate(columns, MAX_IMPORTS);
            words leafFirstOrder = allocate(columns, MAX_MODULES);
            words executableOwners = allocate(columns, MAX_MODULES);
            words moduleSlots = allocate(columns, MAX_MODULES);
            words moduleGenerations = allocate(columns, MAX_MODULES);
            words moduleFirstSymbols = allocate(columns, MAX_MODULES);
            words moduleSymbolCounts = allocate(columns, MAX_MODULES);
            words moduleProductNameStarts = allocate(columns, MAX_MODULES);
            words moduleProductNameLengths = allocate(columns, MAX_MODULES);
            words moduleImportedSymbolCounts = allocate(columns, MAX_MODULES);
            words edgeSymbolCounts = allocate(columns, MAX_IMPORTS);
            words symbolOwners = allocate(columns, MAX_SYMBOLS);
            words symbolStarts = allocate(columns, MAX_SYMBOLS);
            words symbolLengths = allocate(columns, MAX_SYMBOLS);
            words symbolKinds = allocate(columns, MAX_SYMBOLS);
            words symbolVisibilities = allocate(columns, MAX_SYMBOLS);
            words symbolTypes = allocate(columns, MAX_SYMBOLS);
            words symbolValues = allocate(columns, MAX_SYMBOLS);
            words symbolResolved = allocate(columns, MAX_SYMBOLS);
            words moduleFirstCallables = allocate(columns, MAX_MODULES);
            words moduleCallableCounts = allocate(columns, MAX_MODULES);
            words moduleImportedCallableCounts = allocate(columns, MAX_MODULES);
            words edgeCallableCounts = allocate(columns, MAX_IMPORTS);
            words callableOwners = allocate(columns, /* length= */ 4096);
            words callableVisibilities = allocate(columns, /* length= */ 4096);
            words callableNameStarts = allocate(columns, /* length= */ 4096);
            words callableNameLengths = allocate(columns, /* length= */ 4096);
            words callableSignatureStarts = allocate(columns, /* length= */ 4096);
            words callableSignatureLengths = allocate(columns, /* length= */ 4096);
            words callableBodyStarts = allocate(columns, /* length= */ 4096);
            words callableBodyLengths = allocate(columns, /* length= */ 4096);
            words callableParameterCounts = allocate(columns, /* length= */ 4096);
            words callableFirstParameters = allocate(columns, /* length= */ 4096);
            words callableResultTypeStarts = allocate(columns, /* length= */ 4096);
            words callableResultTypeLengths = allocate(columns, /* length= */ 4096);
            words callableEffects = allocate(columns, /* length= */ 4096);
            words callableResultSlotWidths = allocate(columns, /* length= */ 4096);
            words parameterTypeStarts = allocate(columns, MAX_SYMBOLS);
            words parameterTypeLengths = allocate(columns, MAX_SYMBOLS);
            words parameterModes = allocate(columns, MAX_SYMBOLS);
            words physicalAggregates = allocate(columns, /* length= */ 832);
            words physicalCalls = allocate(columns, /* length= */ 1024);
            words physicalResultTypes = allocate(columns, /* length= */ 4096);
            words physicalOwners = allocate(columns, /* length= */ 128);
            words physicalImportedRows = allocate(columns, /* length= */ 114689);
            bytes physicalProductSource = allocateBytes(columns, /* length= */ 32768);
            words callableProductNameStarts = allocate(columns, /* length= */ 4096);
            bytes callableProductNames = allocateBytes(columns, /* length= */ 1048576);
            words physicalParameterTypes = allocate(columns, /* length= */ 16384);
            words primitiveCallables = allocate(columns, /* length= */ 4096);
            words physicalDependencyRows = allocate(columns, /* length= */ 8192);
            words externalFirstCallables = allocate(columns, /* length= */ 64);
            words externalCallableCounts = allocate(columns, /* length= */ 64);
            words externalCallableVisibilities = allocate(columns, /* length= */ 4096);
            words physicalFunctionRows = allocate(columns, /* length= */ 640);
            words physicalInstructionRows = allocate(columns, /* length= */ 24576);
            words physicalFunctionOwners = allocate(columns, /* length= */ 64);
            words physicalFunctionVisibilities = allocate(columns, /* length= */ 64);
            bytes physicalFunctionIdentities = allocateBytes(columns, /* length= */ 2048);
            words physicalRelocationRows = allocate(columns, /* length= */ 12288);
            bytes physicalRelocationIdentities = allocateBytes(columns, /* length= */ 131072);
            words callableHashSlots = allocate(columns, /* length= */ 8192);
            words callableHashFunctions = allocate(columns, /* length= */ 8192);
            words callableFunctionRows = allocate(columns, /* length= */ 4096);
            words callablePublishedRows = allocate(columns, /* length= */ 4096);
            words physicalTargetRows = allocate(columns, /* length= */ 65536);
            words physicalStubCallableRows = allocate(columns, /* length= */ 64);
            PHYSICAL_MODULE_OWNERS
            bytes packageIdentity = allocateBytes(columns, /* length= */ 32);
            bytes symbolIdentities = allocateBytes(columns, MAX_SYMBOLS * 32);
            bytes moduleIdentities = allocateBytes(columns, MAX_MODULES * 32);
            bytes callableIdentities = allocateBytes(columns, /* length= */ 131072);
            bytes rejectedCallableIdentities = allocateBytes(columns, /* length= */ 131072);
            bytes compiledCallableArtifact = allocateBytes(columns, /* length= */ 32768);
            bytes compiledCallableIdentity = allocateBytes(columns, /* length= */ 32);
            bytes expected = allocateBytes(columns, /* length= */ 256);
            ArchiveSourceIndexResult indexed = indexArchiveSources(
              archive,
              archivePathStarts,
              archivePathLengths,
              archiveDataStarts,
              archiveDataLengths
            );
            match (indexed) {
              case ArchiveSourceIndexResult.Value(ArchiveSourceIndex archiveIndex) {
                BootstrapModuleManifestPlan manifestPlan = parseBootstrapModuleManifest(
                  manifest,
                  expected,
                  externalStarts,
                  externalLengths,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  edgeOwners,
                  edgeStarts,
                  edgeLengths,
                  edgeTargets
                );
                long selectedCompilerTarget = -1;
                CompilerToolTargetResult selectedTarget = validateCompilerToolTarget(
                  archive,
                  archiveIndex,
                  manifest,
                  manifestPlan,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths
                );
                match (selectedTarget) {
                  case CompilerToolTargetResult.Value(CompilerToolTarget target) {
                    selectedCompilerTarget = target.target;
                  }
                  case CompilerToolTargetResult.Error(long targetOffset) {
                    assert(targetOffset < 0);
                  }
                }
                assert(-1 < selectedCompilerTarget);
                ArchiveModuleSourcePlan plan = joinArchiveModuleSources(
                  archive,
                  archiveIndex,
                  archivePathStarts,
                  archivePathLengths,
                  archiveDataStarts,
                  archiveDataLengths,
                  manifest,
                  manifestPlan,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  moduleEntries
                );
                CountedClosurePlan closure = planClosureStructure(
                  archive,
                  manifest,
                  manifestPlan,
                  edgeOwners,
                  edgeTargets,
                  moduleEntries,
                  archiveDataStarts,
                  archiveDataLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder
                );
                CountedModuleSymbolPlan symbols = indexCountedModuleSymbols(
                  archive,
                  manifest,
                  closure,
                  edgeTargets,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  moduleImportedSymbolCounts,
                  edgeSymbolCounts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  symbolValues,
                  symbolResolved
                );
                CountedModuleCallablePlan callables = indexCountedModuleCallables(
                  archive,
                  manifest,
                  closure,
                  edgeTargets,
                  firstImports,
                  directImportCounts,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleFirstCallables,
                  moduleCallableCounts,
                  moduleImportedCallableCounts,
                  edgeCallableCounts,
                  callableOwners,
                  callableVisibilities,
                  callableNameStarts,
                  callableNameLengths,
                  callableSignatureStarts,
                  callableSignatureLengths,
                  callableBodyStarts,
                  callableBodyLengths,
                  callableParameterCounts,
                  callableFirstParameters,
                  callableResultTypeStarts,
                  callableResultTypeLengths,
                  callableEffects,
                  callableResultSlotWidths,
                  parameterTypeStarts,
                  parameterTypeLengths,
                  parameterModes
                );
                long callableProductNameBytes = copyCallableNameProducts(
                  archive,
                  callables.callableCount,
                  callableNameStarts,
                  callableNameLengths,
                  callableProductNameStarts,
                  callableProductNames
                );
                if (0 < callables.callableCount) {
                  assert(0 < callableProductNameBytes);
                }
                AvailablePrimitiveCallableTypePlan availableTypes =
                  materializeAvailablePrimitiveCallableTypes(
                    archive,
                    callables.callableCount,
                    callables.parameterCount,
                    callableResultTypeStarts,
                    callableResultTypeLengths,
                    callableFirstParameters,
                    callableParameterCounts,
                    parameterTypeStarts,
                    parameterTypeLengths,
                    parameterModes,
                    physicalResultTypes,
                    physicalParameterTypes,
                    primitiveCallables
                  );
                if (0 < callables.callableCount) {
                  assert(0 < availableTypes.validCount);
                }
                publishCountedSymbolIdentities(
                  archive,
                  manifest,
                  closure,
                  symbols.symbolCount,
                  identityStarts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  packageIdentity,
                  symbolIdentities
                );
                boolean callableIdentityPublication = publishCallableIdentities(
                  archive,
                  manifest,
                  closure.moduleCount,
                  callables.callableCount,
                  identityStarts,
                  callableOwners,
                  callableVisibilities,
                  callableNameStarts,
                  callableNameLengths,
                  callableResultTypeStarts,
                  callableResultTypeLengths,
                  callableEffects,
                  callableFirstParameters,
                  callableParameterCounts,
                  parameterTypeStarts,
                  parameterTypeLengths,
                  parameterModes,
                  packageIdentity,
                  callableIdentities
                );
                if (callableIdentityPublication) {
                  mapCallableFunctionRows(
                    callables.callableCount,
                    callableIdentities,
                    callables.callableCount,
                    callableIdentities,
                    callableHashSlots,
                    callableHashFunctions,
                    callableFunctionRows,
                    callablePublishedRows
                  );
                }
                if (closure.moduleCount == 3) {
                  if (0 < callables.parameterCount) {
                    long savedMode = parameterModes[0];
                    set(parameterModes, 0, 3);
                    boolean invalidCallableIdentity = publishCallableIdentities(
                      archive,
                      manifest,
                      closure.moduleCount,
                      callables.callableCount,
                      identityStarts,
                      callableOwners,
                      callableVisibilities,
                      callableNameStarts,
                      callableNameLengths,
                      callableResultTypeStarts,
                      callableResultTypeLengths,
                      callableEffects,
                      callableFirstParameters,
                      callableParameterCounts,
                      parameterTypeStarts,
                      parameterTypeLengths,
                      parameterModes,
                      packageIdentity,
                      rejectedCallableIdentities
                    );
                    set(parameterModes, 0, savedMode);
                    if (invalidCallableIdentity == false) {
                      if (rejectedCallableIdentities[0] == 0) {
                        invalidCallableIdentityRejected = 1;
                      }
                    }
                  }
                }
                if (closure.moduleCount == 3) {
                  if (callables.callableCount == 6) {
                    CompiledCallableBody compiledCallable = compileCallableBodyProduct(
                      archive,
                      callableSignatureStarts[0],
                      callableSignatureLengths[0],
                      callableBodyStarts[0],
                      callableBodyLengths[0],
                      compiledCallableArtifact,
                      compiledCallableIdentity
                    );
                    compiledCallableBodyLength = compiledCallable.length;
                    compiledCallableBodyIdentityPrefix = compiledCallableIdentity[0]
                        * 16777216
                      + compiledCallableIdentity[1] * 65536
                      + compiledCallableIdentity[2] * 256
                      + compiledCallableIdentity[3];
                    CompiledCallableBody compiledModule = compileCallableModuleProduct(
                      archive,
                      /* owner= */ 1,
                      /* firstCallable= */ 1,
                      /* callableCount= */ 3,
                      callableOwners,
                      callableSignatureStarts,
                      callableSignatureLengths,
                      callableBodyStarts,
                      callableBodyLengths,
                      compiledCallableArtifact,
                      compiledCallableIdentity
                    );
                    compiledCallableModuleLength = compiledModule.length;
                    compiledCallableFunctionCount = compiledModule.functionCount;
                    compiledCallableMaxLocalCount = compiledModule.maxLocalCount;
                    compiledCallableModuleIdentityPrefix = compiledCallableIdentity[0]
                        * 16777216
                      + compiledCallableIdentity[1] * 65536
                      + compiledCallableIdentity[2] * 256
                      + compiledCallableIdentity[3];
                  }
                }
                ScalarModuleIdentityPlan scalarIdentities = publishScalarModuleIdentities(
                  archive,
                  manifest,
                  closure,
                  leafFirstOrder,
                  identityStarts,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  firstImports,
                  directImportCounts,
                  edgeTargets,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  packageIdentity,
                  symbolIdentities,
                  symbolValues,
                  symbolResolved,
                  moduleIdentities
                );
                region products = new region(/* bytes= */ 4210688, /* allocations= */ 5);
                bytes bodyArchive = allocateBytes(products, /* length= */ 4194304);
                words bodyModulePublished = allocate(products, /* length= */ 512);
                words bodyModuleRanks = allocate(products, /* length= */ 512);
                words bodyStarts = allocate(products, /* length= */ 512);
                words bodyLengths = allocate(products, /* length= */ 512);
                PHYSICAL_PRODUCT_COMPILATION
                classifyClosureExecutableOwners(
                  archive,
                  manifest,
                  closure,
                  moduleStarts,
                  moduleLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  executableOwners
                );
                CountedConstantExecution constantExecution = compileCountedConstantRoot(
                  archive,
                  closure.rootModule,
                  executableOwners[closure.rootModule],
                  archiveSourceStarts,
                  archiveSourceLengths,
                  firstImports,
                  directImportCounts,
                  edgeTargets,
                  edgeSymbolCounts,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  symbolStarts,
                  symbolLengths,
                  symbolVisibilities,
                  symbolTypes,
                  symbolValues,
                  symbolResolved,
                  output
                );
                ClosureSourceSchedule schedule = stageClosureSources(
                  archive,
                  manifest,
                  closure,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleSlots,
                  moduleGenerations
                );
                long selectedRootEntry = moduleEntries[plan.rootModule];
                long executableModule = 0;
                long parsedExecutables = 0;
                long largestImportedSymbols = 0;
                while (executableModule < closure.moduleCount) limit MAX_MODULES {
                  parsedExecutables += executableOwners[executableModule];
                  if (
                    largestImportedSymbols < moduleImportedSymbolCounts[executableModule]
                  ) {
                    largestImportedSymbols = moduleImportedSymbolCounts[executableModule];
                  }

                  executableModule += 1;
                }
                long largestImportedCallables = 0;
                long callableModule = 0;
                while (callableModule < closure.moduleCount) limit MAX_MODULES {
                  if (
                    largestImportedCallables
                      < moduleImportedCallableCounts[callableModule]
                  ) {
                    largestImportedCallables = moduleImportedCallableCounts[callableModule];
                  }

                  callableModule += 1;
                }
                long parsedResolvedSymbols = 0;
                long resolvedSymbol = 0;
                while (resolvedSymbol < symbols.symbolCount) limit MAX_SYMBOLS {
                  parsedResolvedSymbols += symbolResolved[resolvedSymbol];
                  resolvedSymbol += 1;
                }

                long selectedRootOrder = 0;
                while (
                  leafFirstOrder[selectedRootOrder] != closure.rootModule
                ) limit MAX_MODULES {
                  selectedRootOrder += 1;
                }
                moduleCount = plan.moduleCount;
                importCount = manifestPlan.importCount;
                archiveEntryCount = plan.archiveEntryCount;
                rootEntry = selectedRootEntry;
                rootDataStart = archiveDataStarts[selectedRootEntry];
                rootDataLength = archiveDataLengths[selectedRootEntry];
                rootOrder = selectedRootOrder;
                rootExecutable = executableOwners[closure.rootModule];
                executableCount = parsedExecutables;
                peakActiveSources = schedule.peakActiveSources;
                rootGeneration = moduleGenerations[closure.rootModule];
                compilerTarget = selectedCompilerTarget;
                symbolCount = symbols.symbolCount;
                resolvedSymbolCount = parsedResolvedSymbols;
                rootLocalSymbols = moduleSymbolCounts[closure.rootModule];
                rootImportedSymbols = moduleImportedSymbolCounts[closure.rootModule];
                maxImportedSymbols = largestImportedSymbols;
                symbolGeneration = symbols.finalGeneration;
                callableCount = callables.callableCount;
                callableParameterCount = callables.parameterCount;
                long parameter = 0;
                while (parameter < callables.parameterCount) limit MAX_SYMBOLS {
                  if (0 < parameterModes[parameter]) {
                    borrowedParameterCount += 1;
                  }
                  if (parameterModes[parameter] == 2) {
                    mutableParameterCount += 1;
                  }
                  parameter += 1;
                }
                long slotCallable = 0;
                while (slotCallable < callables.callableCount) limit 4096 {
                  if (callableResultSlotWidths[slotCallable] == 2) {
                    resultSlotCallableCount += 1;
                  }
                  slotCallable += 1;
                }
                rootLocalCallables = moduleCallableCounts[closure.rootModule];
                rootImportedCallables = moduleImportedCallableCounts[closure.rootModule];
                maxImportedCallables = largestImportedCallables;
                callableGeneration = callables.finalGeneration;
                if (0 < callables.callableCount) {
                  firstCallableSignatureLength = callableSignatureLengths[0];
                  firstCallableBodyLength = callableBodyLengths[0];
                  firstCallableResultTypeLength = callableResultTypeLengths[0];
                  lastCallableParameterCount = callableParameterCounts[
                    callables.callableCount - 1
                  ];
                  lastCallableEffects = callableEffects[callables.callableCount - 1];
                }
                packageIdentityPrefix = packageIdentity[0] * 16777216
                  + packageIdentity[1] * 65536
                  + packageIdentity[2] * 256
                  + packageIdentity[3];
                if (0 < symbols.symbolCount) {
                  firstSymbolIdentityPrefix = symbolIdentities[0] * 16777216
                    + symbolIdentities[1] * 65536
                    + symbolIdentities[2] * 256
                    + symbolIdentities[3];
                  long finalIdentity = (symbols.symbolCount - 1) * 32;
                  lastSymbolIdentityPrefix = symbolIdentities[finalIdentity] * 16777216
                    + symbolIdentities[finalIdentity + 1] * 65536
                    + symbolIdentities[finalIdentity + 2] * 256
                    + symbolIdentities[finalIdentity + 3];
                  lastSymbolValue = symbolValues[symbols.symbolCount - 1];
                  lastSymbolResolved = symbolResolved[symbols.symbolCount - 1];
                }
                if (callableIdentityPublication) {
                  if (0 < callables.callableCount) {
                    long finalCallableIdentity = (callables.callableCount - 1) * 32;
                    firstCallableIdentityPrefix = callableIdentities[0] * 16777216
                      + callableIdentities[1] * 65536
                      + callableIdentities[2] * 256
                      + callableIdentities[3];
                    lastCallableIdentityPrefix = callableIdentities[finalCallableIdentity]
                        * 16777216
                      + callableIdentities[finalCallableIdentity + 1] * 65536
                      + callableIdentities[finalCallableIdentity + 2] * 256
                      + callableIdentities[finalCallableIdentity + 3];
                  }
                  callableIdentitiesPublished = 1;
                }
                if (scalarIdentities.valid) {
                  long rootModuleIdentity = closure.rootModule * 32;
                  firstModuleIdentityPrefix = moduleIdentities[0] * 16777216
                    + moduleIdentities[1] * 65536
                    + moduleIdentities[2] * 256
                    + moduleIdentities[3];
                  lastModuleIdentityPrefix = moduleIdentities[rootModuleIdentity] * 16777216
                    + moduleIdentities[rootModuleIdentity + 1] * 65536
                    + moduleIdentities[rootModuleIdentity + 2] * 256
                    + moduleIdentities[rootModuleIdentity + 3];
                  moduleIdentitiesPublished = 1;
                }
                published = 1;
                if (constantExecution.attempted) {
                  setOutputLength(output, constantExecution.length);
                } else {
                  if (0 < compiledCallableModuleLength) {
                    long artifactByte = 0;
                    while (
                      artifactByte < compiledCallableModuleLength
                    ) limit 32768 {
                      setByte(output, artifactByte, compiledCallableArtifact[artifactByte]);
                      artifactByte += 1;
                    }
                    setOutputLength(output, compiledCallableModuleLength);
                  } else {
                    PHYSICAL_PRODUCT_PUBLICATION
                  }
                }
                drop(bodyLengths);
                drop(bodyStarts);
                drop(bodyModuleRanks);
                drop(bodyModulePublished);
                drop(bodyArchive);
                drop(products);
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(offset < 0);
              }
            }
            drop(expected);
            drop(compiledCallableIdentity);
            drop(compiledCallableArtifact);
            drop(rejectedCallableIdentities);
            drop(callableIdentities);
            drop(moduleIdentities);
            drop(symbolIdentities);
            drop(packageIdentity);
            drop(physicalStubCallableRows);
            drop(physicalTargetRows);
            drop(callablePublishedRows);
            drop(callableFunctionRows);
            drop(callableHashFunctions);
            drop(callableHashSlots);
            drop(physicalRelocationIdentities);
            drop(physicalRelocationRows);
            drop(physicalFunctionIdentities);
            drop(physicalFunctionVisibilities);
            drop(physicalFunctionOwners);
            drop(physicalInstructionRows);
            drop(physicalFunctionRows);
            drop(externalCallableVisibilities);
            drop(externalCallableCounts);
            drop(externalFirstCallables);
            drop(physicalDependencyRows);
            drop(primitiveCallables);
            drop(physicalParameterTypes);
            drop(callableProductNames);
            drop(callableProductNameStarts);
            drop(physicalProductSource);
            drop(physicalImportedRows);
            drop(physicalOwners);
            drop(physicalResultTypes);
            drop(physicalCalls);
            drop(physicalAggregates);
            drop(parameterModes);
            drop(parameterTypeLengths);
            drop(parameterTypeStarts);
            drop(callableResultSlotWidths);
            drop(callableEffects);
            drop(callableResultTypeLengths);
            drop(callableResultTypeStarts);
            drop(callableFirstParameters);
            drop(callableParameterCounts);
            drop(callableBodyLengths);
            drop(callableBodyStarts);
            drop(callableSignatureLengths);
            drop(callableSignatureStarts);
            drop(callableNameLengths);
            drop(callableNameStarts);
            drop(callableVisibilities);
            drop(callableOwners);
            drop(edgeCallableCounts);
            drop(moduleImportedCallableCounts);
            drop(moduleCallableCounts);
            drop(moduleFirstCallables);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolVisibilities);
            drop(symbolKinds);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(edgeSymbolCounts);
            drop(moduleImportedSymbolCounts);
            drop(moduleProductNameLengths);
            drop(moduleProductNameStarts);
            drop(moduleSymbolCounts);
            drop(moduleFirstSymbols);
            drop(moduleGenerations);
            drop(moduleSlots);
            drop(executableOwners);
            drop(leafFirstOrder);
            drop(importRanks);
            drop(directImportCounts);
            drop(firstImports);
            drop(archiveSourceLengths);
            drop(archiveSourceStarts);
            drop(moduleEntries);
            drop(edgeTargets);
            drop(edgeLengths);
            drop(edgeStarts);
            drop(edgeOwners);
            drop(identityStarts);
            drop(sourceLengths);
            drop(sourceStarts);
            drop(moduleLengths);
            drop(moduleStarts);
            drop(externalLengths);
            drop(externalStarts);
            drop(archiveDataLengths);
            drop(archiveDataStarts);
            drop(archivePathLengths);
            drop(archivePathStarts);
            drop(columns);
            drop(manifest);
            drop(archive);
            drop(inputArena);
          }
        }
        """
            .replace(
                "PHYSICAL_MODULE_OWNERS",
                physicalOwnerRows(comparableModules, callableModules))
            .replace(
                "PHYSICAL_PRODUCT_COMPILATION",
                compilePhysicalProducts ? NativeCompilerPhysicalProductSource.compilation() : "")
            .replace("PHYSICAL_PRODUCT_PUBLICATION", NativeCompilerPhysicalProductSource.publication())
            .replace("PHYSICAL_COMPARABLE_COUNT", Integer.toString(comparableModules.size()))
            .replace(
                "STRUCTURED_SOURCE_MODULE_OWNER",
                Integer.toString(physicalOwner(PHYSICAL_MODULES.getLast())))
            .replace(
                "REVERSIBLE_SOURCE_MODULE_OWNER",
                Integer.toString(physicalOwner(PHYSICAL_REVERSIBLE_MODULE)))
            .replace("PHYSICAL_CLOSURE_MODULE_COUNT", Integer.toString(
                CompilerSources.bootstrapModuleManifest().modules().size()))
            .replace(
                "PHYSICAL_MODULE_COUNT",
                Integer.toString(comparableModules.size() + callableModules.size())));
    return new WheelerCompiler().compileModuleFiles(sources, "example.archive_closure");
  }

}
