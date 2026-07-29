//! Implements the bounded bootstrap compiler as one importable library module.

module wheeler.compiler.driver;

import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_types;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.opcodes;
import wheeler.compiler.parser;
import wheeler.compiler.program_codegen;
import wheeler.compiler.statement_forms;
import wheeler.compiler.string_table;
import wheeler.compiler.tokens;
import wheeler.compiler.verifier;
import wheeler.lexer.scanner;

classical class CompilerDriver {
  /// Carries the exact bounds of one verified compiler artifact.
  public record Compilation(long length, long codeStart) {}

  private long compactCompilerTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readCursor];
      boolean emit = true;
      if (kind == 4) {
        emit = false;
      }

      if (kind == 5) {
        emit = false;
      }

      if (emit) {
        set(tokenKinds, writeCursor, kind);
        set(tokenStarts, writeCursor, tokenStarts[readCursor]);
        set(tokenLengths, writeCursor, tokenLengths[readCursor]);
        writeCursor += 1;
      }

      readCursor += 1;
    }

    return writeCursor;
  }

  private long discardLeadingTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    long readCursor = bodyStart;
    long writeCursor = 0;
    while (readCursor < count) limit 512 {
      set(tokenKinds, writeCursor, tokenKinds[readCursor]);
      set(tokenStarts, writeCursor, tokenStarts[readCursor]);
      set(tokenLengths, writeCursor, tokenLengths[readCursor]);
      readCursor += 1;
      writeCursor += 1;
    }

    return writeCursor;
  }

  private MinimalProgram requireMinimalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    borrow mut words moduleRange
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic scanDiagnostic) {
        assert(0 == 1);
        SourceRange scanName = new SourceRange(scanDiagnostic.offset, 0);
        SourceRange scanGlobal = new SourceRange(scanDiagnostic.offset, 0);
        return new MinimalProgram(
          scanName,
          scanGlobal,
          0,
          0,
          0,
          emptyStatementOpcodes(),
          emptyStatementOperands(),
          emptyStatementOperands(),
          scanGlobal,
          0,
          emptyStatementOpcodes(),
          emptyStatementOperands(),
          emptyStatementOperands(),
          0,
          scanGlobal,
          0,
          0,
          0,
          0
        );
      }
      case ScanResult.Value(long count) {
        long semanticCount = compactCompilerTokens(tokenKinds, tokenStarts, tokenLengths, count);
        long bodyStart = moduleBodyStart(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          moduleRange,
          semanticCount
        );
        if (bodyStart < 0) {
          assert(0 == 1);
        }

        semanticCount = discardLeadingTokens(
          tokenKinds,
          tokenStarts,
          tokenLengths,
          bodyStart,
          semanticCount
        );
        MinimalProgramResult parsed = parseMinimalProgram(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          statementStarts,
          semanticCount
        );
        match (parsed) {
          case MinimalProgramResult.Error(long parseOffset) {
            assert(0 == 1);
            SourceRange parseName = new SourceRange(parseOffset, 0);
            SourceRange parseGlobal = new SourceRange(parseOffset, 0);
            return new MinimalProgram(
              parseName,
              parseGlobal,
              0,
              0,
              0,
              emptyStatementOpcodes(),
              emptyStatementOperands(),
              emptyStatementOperands(),
              parseGlobal,
              0,
              emptyStatementOpcodes(),
              emptyStatementOperands(),
              emptyStatementOperands(),
              0,
              parseGlobal,
              0,
              0,
              0,
              0
            );
          }
          case MinimalProgramResult.Value(MinimalProgram program) {
            return program;
          }
        }
      }
    }
  }

  private long writeSequenceLocalTypes(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long count
  ) {
    long index = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeStatementLocalTypes(output, cursor, opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  /// Compiles one bounded bootstrap source into caller-owned artifact storage.
  public Compilation compileMinimal(borrow utf8 source, borrow mut bytes output) {
    region arena = new region(/* bytes= */ 25632, /* allocations= */ 5);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words statementStarts = allocate(arena, MAX_PROGRAM_RESOLUTION_STARTS);
    words moduleRange = allocate(arena, 2);
    MinimalProgram program = requireMinimalProgram(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      moduleRange
    );
    SourceRange moduleName = new SourceRange(moduleRange[0], moduleRange[1]);
    StringTablePlan strings = planStringTable(source, program, moduleName);
    if (strings.valid == 0) {
      assert(0 == 1);
    }

    long nameIndex = strings.nameIndex;
    long globalIndex = strings.globalIndex;
    long helperIndex = strings.helperIndex;
    long proofIndex = strings.proofIndex;
    long mainIndex = strings.mainIndex;
    long stringsLength = strings.encodedLength;
    long typesLength = 16;
    if (program.globalCount == 1) {
      typesLength = 32;
    }

    long sectionCount = 6 + program.proofCount;
    long manifestOffset = align8(40 + sectionCount * 32);
    long stringsOffset = align8(manifestOffset + 24);
    long typesOffset = align8(stringsOffset + stringsLength);
    long variantsOffset = align8(typesOffset + typesLength);
    long functionsOffset = align8(variantsOffset + 4);
    boolean resultSlotProgram = resultSlotHelper(program.helperKind);
    long localCount = 0;
    long codeLength = 8;
    long statementIndex = 0;
    while (statementIndex < program.statementCount) limit MAX_MINIMAL_STATEMENTS {
      long statementOpcode = program.statementOpcodes[statementIndex];
      if (resultSlotProgram) {
        localCount += resultSlotEntryLocalCount(statementOpcode);
        codeLength += resultSlotEntryCodeLength(statementOpcode);
      } else {
        localCount += statementLocalCount(statementOpcode);
        codeLength += statementCodeLength(statementOpcode);
      }

      statementIndex += 1;
    }

    long entryLocalCount = localCount;
    long entryStatementLength = codeLength - 8;
    long functionsLength = 44 + localCount * 4;
    long helperParameterCount = parameterCountForHelper(program.helperKind);
    long helperLocalCount = helperParameterCount;
    long helperLocalBase = helperParameterCount;
    long helperForwardLength = 8;
    long helperStatementIndex = 0;
    while (helperStatementIndex < program.helperStatementCount) limit MAX_MINIMAL_STATEMENTS {
      long helperOpcode = program.helperOpcodes[helperStatementIndex];
      helperLocalCount += statementLocalCount(helperOpcode);
      helperForwardLength += statementCodeLength(helperOpcode);
      helperStatementIndex += 1;
    }

    if (HELPER_REVERSIBLE < program.helperKind) {
      if (resultSlotProgram) {} else {
        helperForwardLength -= 8;
      }
    }

    long helperInverseLength = 0;
    long helperInverseOffset = 4294967295;
    long entryForwardLength = 8 + program.helperCallCount * 16 + entryStatementLength;
    if (program.helperKind == HELPER_REVERSIBLE) {
      helperLocalCount = 0;
      helperForwardLength = 8 + program.helperStatementCount * 24;
      helperInverseLength = helperForwardLength;
      helperInverseOffset = helperForwardLength;
      entryForwardLength = 8 + program.helperCallCount * 32 + entryStatementLength;
    }

    if (resultSlotProgram) {
      helperLocalCount = helperParameterCount + RESULT_SLOT_LOCAL_COUNT;
      helperForwardLength = RESULT_SLOT_BODY_LENGTH;
      if (returnLocalBinaryStatement(program.helperOpcodes[0])) {
        helperForwardLength = RESULT_SLOT_BINARY_BODY_LENGTH;
      }

      if (returnLocalPairStatement(program.helperOpcodes[0])) {
        helperForwardLength = RESULT_SLOT_BINARY_BODY_LENGTH;
      }

      helperInverseLength = helperForwardLength;
      helperInverseOffset = helperForwardLength;
      entryForwardLength = 8 + entryStatementLength;
    }

    long entryTypeOffset = helperLocalCount;
    if (program.helperCount == 1) {
      localCount = helperLocalCount;
      functionsLength = 84 + helperLocalCount * 4 + entryLocalCount * 4;
      if (HELPER_REVERSIBLE < program.helperKind) {
        functionsLength += 4;
        entryTypeOffset += 1;
      }

      codeLength = helperForwardLength + helperInverseLength + entryForwardLength;
    }

    long codeOffset = align8(functionsOffset + functionsLength);
    long proofOffset = align8(codeOffset + codeLength);
    long fileLength = align8(codeOffset + codeLength);
    if (program.proofCount == 1) {
      fileLength = align8(proofOffset + 28);
    }

    assert(fileLength < bufferLength(output) + 1);

    writeAscii(output, 0, "WHEELBC");
    long cursor = 8;
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U16);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U16);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, fileLength, ENCODING_WIDTH_U64);
    cursor = writeUnsignedLittleEndian(output, cursor, sectionCount, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 32, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 40, ENCODING_WIDTH_U64);

    cursor = writeDirectoryEntry(output, cursor, 1, manifestOffset, 24);
    cursor = writeDirectoryEntry(output, cursor, 2, stringsOffset, stringsLength);
    cursor = writeDirectoryEntry(output, cursor, 3, typesOffset, typesLength);
    cursor = writeDirectoryEntry(output, cursor, 4, variantsOffset, 4);
    cursor = writeDirectoryEntry(output, cursor, 5, functionsOffset, functionsLength);
    cursor = writeDirectoryEntry(output, cursor, 6, codeOffset, codeLength);
    if (program.proofCount == 1) {
      cursor = writeDirectoryEntry(output, cursor, 10, proofOffset, 28);
    }

    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, nameIndex, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, program.helperCount, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 4000000, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 4000000, ENCODING_WIDTH_U64);

    cursor = writeStringTable(output, cursor, source, program, moduleName, strings);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, program.globalCount, ENCODING_WIDTH_U32);
    if (program.globalCount == 1) {
      cursor = writeUnsignedLittleEndian(output, cursor, globalIndex, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeSignedLittleEndian(output, cursor, program.initialValue, ENCODING_WIDTH_U64);
    }

    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      1 + program.helperCount,
      ENCODING_WIDTH_U32
    );
    if (program.helperCount == 1) {
      long helperFlags = program.helperKind;
      if (HELPER_REVERSIBLE < program.helperKind) {
        helperFlags = 4;
      }

      if (resultSlotProgram) {
        helperFlags = RESULT_SLOT_FUNCTION_FLAGS;
      }

      cursor = writeFunctionDescriptor(
        output,
        cursor,
        0,
        helperIndex,
        0,
        helperForwardLength,
        helperFlags,
        helperInverseOffset,
        helperInverseLength,
        helperParameterCount,
        helperLocalCount,
        0
      );
      cursor = writeFunctionDescriptor(
        output,
        cursor,
        1,
        mainIndex,
        helperForwardLength + helperInverseLength,
        entryForwardLength,
        0,
        4294967295,
        0,
        0,
        entryLocalCount,
        entryTypeOffset
      );
      if (HELPER_REVERSIBLE < program.helperKind) {
        if (booleanResultHelper(program.helperKind)) {
          cursor = writeBooleanLocalType(output, cursor);
        } else {
          cursor = writeSignedLocalType(output, cursor);
        }
      }

      long helperParameterIndex = 0;
      while (helperParameterIndex < helperParameterCount) limit 2 {
        if (booleanParameterHelper(program.helperKind)) {
          cursor = writeBooleanLocalType(output, cursor);
        } else {
          cursor = writeSignedLocalType(output, cursor);
        }

        helperParameterIndex += 1;
      }

      if (program.helperKind == HELPER_REVERSIBLE) {} else {
        if (resultSlotProgram) {
          cursor = writeBooleanLocalType(output, cursor);
          cursor = writeSignedLocalType(output, cursor);
        } else {
          cursor = writeSequenceLocalTypes(
            output,
            cursor,
            program.helperOpcodes,
            program.helperStatementCount
          );
        }
      }

      if (resultSlotProgram) {
        long resultEntryType = 0;
        while (resultEntryType < program.statementCount) limit MAX_MINIMAL_STATEMENTS {
          cursor = writeResultSlotEntryLocalTypes(
            output,
            cursor,
            program.statementOpcodes[resultEntryType]
          );
          resultEntryType += 1;
        }
      } else {
        cursor = writeSequenceLocalTypes(
          output,
          cursor,
          program.statementOpcodes,
          program.statementCount
        );
      }
    } else {
      cursor = writeFunctionDescriptor(
        output,
        cursor,
        0,
        mainIndex,
        0,
        codeLength,
        0,
        4294967295,
        0,
        0,
        localCount,
        0
      );
      cursor = writeSequenceLocalTypes(
        output,
        cursor,
        program.statementOpcodes,
        program.statementCount
      );
    }

    cursor = align8(cursor);

    cursor = writeProgramCode(output, cursor, program, helperLocalBase, resultSlotProgram);

    cursor = writeInstructionHeader(output, cursor, OPCODE_HALT, INSTRUCTION_FORM_NULLARY);
    if (program.proofCount == 1) {
      cursor = align8(cursor);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, proofIndex, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ -1, ENCODING_WIDTH_U64);
      cursor = align8(cursor);
    }

    long finalCursor = cursor;
    long verification = verifyArtifact(output, finalCursor);
    assert(verification == 1);

    drop(moduleRange);
    drop(statementStarts);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(arena);
    return new Compilation(finalCursor, codeOffset);
  }

  /// Compiles one root with one direct scalar-constant module.
  public Compilation compileMinimalWithConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, /* expectedImportCount= */ 1);
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    region linkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    Compilation compiled = compileMinimal(linkedSource, output);
    drop(linkedSource);
    drop(linkedArena);
    return compiled;
  }

  private Compilation compileMinimalWithConstantChain(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      assert(0 == 1);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      assert(0 == 1);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimal(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  /// Compiles one root with two direct modules or one two-edge constant chain.
  public Compilation compileMinimalWithConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstChain = planPrivateConstantImport(
      firstImportedSource,
      secondImportedSource,
      /* expectedImportCount= */ 1
    );
    if (firstChain.valid) {
      return compileMinimalWithConstantChain(
        firstImportedSource,
        secondImportedSource,
        rootSource,
        output
      );
    }

    LinkPlan secondChain = planPrivateConstantImport(
      secondImportedSource,
      firstImportedSource,
      /* expectedImportCount= */ 1
    );
    if (secondChain.valid) {
      return compileMinimalWithConstantChain(
        secondImportedSource,
        firstImportedSource,
        rootSource,
        output
      );
    }

    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ 2
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);
    Compilation compiled = compileMinimal(secondLinkedSource, output);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }
}
