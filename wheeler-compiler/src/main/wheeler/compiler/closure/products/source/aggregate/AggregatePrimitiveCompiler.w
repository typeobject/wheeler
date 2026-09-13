//! Compiles a private, claim-free aggregate projection through counted source products.

module wheeler.compiler.closure.aggregate_primitive_compiler;

import wheeler.compiler.closure.archive_structured_source_module_compiler;
import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.closure.callable_type_products;
import wheeler.compiler.closure.source_callable_front_products;
import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.compiler_token_limits;

classical class AggregatePrimitiveCompiler {
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_ARTIFACT_BYTES = 32768;
  private const long MAX_CALLABLES = 4096;
  private const long IDENTITY_BYTES = 32;
  private const long CALLABLE_FRONT_COLUMNS = 14;
  private const long CALLABLE_TYPE_COLUMNS = 1;
  private const long PARAMETER_FRONT_COLUMNS = 3;
  private const long PARAMETER_TYPE_COLUMNS = 1;
  private const long TOKEN_COLUMNS = 3;
  private const long MODULE_RANGE_WORDS = 2;
  private const long PARAMETER_TOTAL_WORDS = 1;
  private const long WORD_BYTES = 8;
  private const long SOURCE_BUFFERS = 1;
  private const long PRODUCT_WORDS = MAX_CALLABLES * (
    CALLABLE_FRONT_COLUMNS + CALLABLE_TYPE_COLUMNS
  ) + MAX_CLOSURE_PARAMETERS * (PARAMETER_FRONT_COLUMNS + PARAMETER_TYPE_COLUMNS)
    + MAX_COMPILER_TOKENS * TOKEN_COLUMNS + MODULE_RANGE_WORDS + PARAMETER_TOTAL_WORDS;
  private const long PRODUCT_BYTES = PRODUCT_WORDS * WORD_BYTES + MAX_SOURCE_BYTES;
  private const long PRODUCT_BUFFERS = CALLABLE_FRONT_COLUMNS + CALLABLE_TYPE_COLUMNS
    + PARAMETER_FRONT_COLUMNS + PARAMETER_TYPE_COLUMNS + TOKEN_COLUMNS + 2 + SOURCE_BUFFERS;

  private void requirePrimitiveSourceWindow(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long classNameStart,
    long classNameLength,
    borrow byteview artifact,
    borrow byteview identity
  ) {
    assert(-1 < sourceStart);
    assert(sourceStart < bufferLength(source) + 1);
    assert(0 < sourceLength);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    assert(classNameStart < sourceStart + sourceLength);
    assert(sourceStart < classNameStart + 1);
    assert(0 < classNameLength);
    assert(classNameLength < MAX_QUALIFIED_NAME_BYTES + 1);
    assert(classNameLength < sourceStart + sourceLength - classNameStart + 1);
    assert(bufferLength(artifact) == MAX_ARTIFACT_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);
  }

  /// Compiles a private primitive view, not the final nominal source artifact.
  /// The caller retains original claims, aggregate operations, and projection coordinates.
  /// Class-name coordinates belong to this view's admitted declaration products.
  /// Attached claims reject rather than certify a placeholder instruction count.
  public SourceProductArtifactPlan compileAggregatePrimitiveSource(
    long targetKind,
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long classNameStart,
    long classNameLength,
    long constantCount,
    borrow mut words constants,
    borrow byteview constantNames,
    borrow mut words constantNameStarts,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    requirePrimitiveSourceWindow(
      source,
      sourceStart,
      sourceLength,
      classNameStart,
      classNameLength,
      artifact,
      identity
    );
    region staging = new region(/* bytes= */ PRODUCT_BYTES, /* allocations= */ PRODUCT_BUFFERS);
    bytes sourceBytes = allocateBytes(staging, sourceLength);
    words owners = allocate(staging, MAX_CALLABLES);
    words visibilities = allocate(staging, MAX_CALLABLES);
    words nameStarts = allocate(staging, MAX_CALLABLES);
    words nameLengths = allocate(staging, MAX_CALLABLES);
    words signatureStarts = allocate(staging, MAX_CALLABLES);
    words signatureLengths = allocate(staging, MAX_CALLABLES);
    words bodyStarts = allocate(staging, MAX_CALLABLES);
    words bodyLengths = allocate(staging, MAX_CALLABLES);
    words parameterCounts = allocate(staging, MAX_CALLABLES);
    words firstParameters = allocate(staging, MAX_CALLABLES);
    words resultTypeStarts = allocate(staging, MAX_CALLABLES);
    words resultTypeLengths = allocate(staging, MAX_CALLABLES);
    words effects = allocate(staging, MAX_CALLABLES);
    words resultSlotWidths = allocate(staging, MAX_CALLABLES);
    words parameterTypeStarts = allocate(staging, MAX_CLOSURE_PARAMETERS);
    words parameterTypeLengths = allocate(staging, MAX_CLOSURE_PARAMETERS);
    words parameterModes = allocate(staging, MAX_CLOSURE_PARAMETERS);
    words kinds = allocate(staging, MAX_COMPILER_TOKENS);
    words starts = allocate(staging, MAX_COMPILER_TOKENS);
    words lengths = allocate(staging, MAX_COMPILER_TOKENS);
    words moduleRange = allocate(staging, MODULE_RANGE_WORDS);
    words parameterTotal = allocate(staging, PARAMETER_TOTAL_WORDS);
    words resultTypes = allocate(staging, MAX_CALLABLES);
    words parameterTypes = allocate(staging, MAX_CLOSURE_PARAMETERS);
    long copied = 0;
    while (copied < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(sourceBytes, copied, source[sourceStart + copied]);
      copied += 1;
    }

    utf8 sourceText = freezeUtf8(sourceBytes);
    assert(sourceClassicalClaimsAbsent(sourceText, kinds, starts, lengths, moduleRange));
    long callableCount = stageSourceCallableProducts(
      sourceText,
      sourceStart,
      /* owner= */ 0,
      /* firstCallable= */ 0,
      kinds,
      starts,
      lengths,
      moduleRange,
      owners,
      visibilities,
      nameStarts,
      nameLengths,
      signatureStarts,
      signatureLengths,
      bodyStarts,
      bodyLengths,
      parameterCounts,
      firstParameters,
      resultTypeStarts,
      resultTypeLengths,
      effects,
      resultSlotWidths,
      parameterTypeStarts,
      parameterTypeLengths,
      parameterModes,
      parameterTotal
    );
    assert(-1 < callableCount);
    CallableTypeProductPlan types = materializePrimitiveCallableTypes(
      source,
      callableCount,
      parameterTotal[0],
      resultTypeStarts,
      resultTypeLengths,
      firstParameters,
      parameterCounts,
      parameterTypeStarts,
      parameterTypeLengths,
      parameterModes,
      resultTypes,
      parameterTypes
    );
    assert(types.valid);
    SourceProductArtifactPlan result = compileStructuredArchiveModule(
      targetKind,
      source,
      sourceStart,
      sourceLength,
      /* moduleOwner= */ 0,
      /* moduleNames= */ source,
      sourceStart + moduleRange[0],
      moduleRange[1],
      classNameStart,
      classNameLength,
      /* firstCallable= */ 0,
      callableCount,
      bodyStarts,
      bodyLengths,
      constantCount,
      constants,
      constantNames,
      constantNameStarts,
      firstParameters,
      parameterCounts,
      resultTypes,
      effects,
      parameterTypes,
      parameterModes,
      /* callableNames= */ source,
      nameStarts,
      nameLengths,
      artifact,
      identity
    );
    drop(parameterTypes);
    drop(resultTypes);
    drop(parameterTotal);
    drop(moduleRange);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(parameterModes);
    drop(parameterTypeLengths);
    drop(parameterTypeStarts);
    drop(resultSlotWidths);
    drop(effects);
    drop(resultTypeLengths);
    drop(resultTypeStarts);
    drop(firstParameters);
    drop(parameterCounts);
    drop(bodyLengths);
    drop(bodyStarts);
    drop(signatureLengths);
    drop(signatureStarts);
    drop(nameLengths);
    drop(nameStarts);
    drop(visibilities);
    drop(owners);
    drop(sourceText);
    drop(staging);
    return result;
  }
}
