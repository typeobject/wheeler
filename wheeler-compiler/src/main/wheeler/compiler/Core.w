//! Lowers one validated bounded source into canonical Wheeler bytecode.

module wheeler.compiler.compiler_core;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.ir;
import wheeler.compiler.library_strings;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_types;
import wheeler.compiler.module_headers;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.opcodes;
import wheeler.compiler.parser;
import wheeler.compiler.program_codegen;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.string_table;
import wheeler.compiler.tokens;
import wheeler.compiler.verifier;
import wheeler.lexer.scanner;

classical class CompilerCore {
  /// Carries the exact bounds of one verified compiler artifact.
  public record CoreCompilation(long length, long codeStart) {}

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
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
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
          0,
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          emptyHelperBody(),
          scanGlobal,
          0,
          0,
          0,
          false
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
              0,
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              emptyHelperBody(),
              parseGlobal,
              0,
              0,
              0,
              false
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

  private long boundedHelperLocalCount(HelperBody body) {
    long count = parameterCountForHelper(body.kind);
    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      count += statementLocalCount(body.opcodes[statement]);
      statement += 1;
    }

    return count;
  }

  private long boundedHelperForwardLength(HelperBody body) {
    long length = 8;
    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      length += statementCodeLength(body.opcodes[statement]);
      statement += 1;
    }

    if (HELPER_REVERSIBLE < body.kind) {
      length -= 8;
    }

    return length;
  }

  private long boundedHelperTypeOffset(MinimalProgram program, long index) {
    long offset = 0;
    long helper = 0;
    while (helper < index) limit MAX_SCALAR_HELPERS {
      offset += boundedHelperLocalCount(helperAt(program, helper)) + 1;
      helper += 1;
    }

    return offset;
  }

  /// Compiles one bounded bootstrap source into caller-owned artifact storage.
  public CoreCompilation compileMinimalCore(borrow utf8 source, borrow mut bytes output) {
    SourceRange noImportedModule = new SourceRange(0, 0);
    return compileMinimalCoreOwned(
      source,
      output,
      noImportedModule,
      /* importedHelperCount= */ 0
    );
  }

  /// Compiles one flattened source while preserving its imported helper owner.
  public CoreCompilation compileMinimalCoreWithHelperImport(
    borrow utf8 source,
    borrow mut bytes output,
    long importedModuleStart,
    long importedModuleLength,
    long importedHelperCount
  ) {
    assert(0 < importedModuleLength);
    assert(importedModuleStart + importedModuleLength < bufferLength(source) + 1);
    assert(0 < importedHelperCount);
    SourceRange importedModule = new SourceRange(importedModuleStart, importedModuleLength);
    return compileMinimalCoreOwned(source, output, importedModule, importedHelperCount);
  }

  private CoreCompilation compileMinimalCoreOwned(
    borrow utf8 source,
    borrow mut bytes output,
    SourceRange importedModule,
    long importedHelperCount
  ) {
    region arena = new region(/* bytes= */ 50208, /* allocations= */ 5);
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
    LibraryStringPlan libraryStrings = planLibraryStrings(
      source,
      program,
      moduleName,
      importedModule,
      importedHelperCount
    );
    if (1 < program.helperCount) {
      if (libraryStrings.valid == 0) {
        assert(0 == 1);
      }
    } else {
      if (strings.valid == 0) {
        assert(0 == 1);
      }
    }

    long nameIndex = strings.nameIndex;
    long globalIndex = strings.globalIndex;
    long helperIndex = strings.helperIndex;
    long proofIndex = strings.proofIndex;
    long mainIndex = strings.mainIndex;
    long stringsLength = strings.encodedLength;
    if (1 < program.helperCount) {
      nameIndex = libraryStrings.nameIndex;
      helperIndex = libraryStrings.helperIndices[0];
      mainIndex = libraryStrings.entryIndex;
      stringsLength = libraryStrings.encodedLength;
    }

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
    boolean resultSlotProgram = resultSlotHelper(helperAt(program, 0).kind);
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
    long helperParameterCount = parameterCountForHelper(helperAt(program, 0).kind);
    long helperLocalCount = helperParameterCount;
    long helperLocalBase = helperParameterCount;
    long helperForwardLength = 8;
    long helperStatementIndex = 0;
    while (helperStatementIndex
      < helperAt(program, 0).statementCount) limit MAX_MINIMAL_STATEMENTS {
      long helperOpcode = helperAt(program, 0).opcodes[helperStatementIndex];
      helperLocalCount += statementLocalCount(helperOpcode);
      helperForwardLength += statementCodeLength(helperOpcode);
      helperStatementIndex += 1;
    }

    if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
      if (resultSlotProgram) {} else {
        helperForwardLength -= 8;
      }
    }

    long helperInverseLength = 0;
    long helperInverseOffset = 4294967295;
    long entryForwardLength = 8 + program.helperCallCount * 16 + entryStatementLength;
    if (helperAt(program, 0).kind == HELPER_REVERSIBLE) {
      helperLocalCount = 0;
      helperForwardLength = 8 + helperAt(program, 0).statementCount * 24;
      helperInverseLength = helperForwardLength;
      helperInverseOffset = helperForwardLength;
      entryForwardLength = 8 + program.helperCallCount * 32 + entryStatementLength;
    }

    if (resultSlotProgram) {
      helperLocalCount = helperParameterCount + RESULT_SLOT_LOCAL_COUNT;
      helperForwardLength = RESULT_SLOT_BODY_LENGTH;
      long helperResultOpcode = helperAt(program, 0).opcodes[helperAt(program, 0).resultStatement];
      if (returnLocalBinaryStatement(helperResultOpcode)) {
        helperForwardLength = RESULT_SLOT_BINARY_BODY_LENGTH;
      }

      if (returnLocalPairStatement(helperResultOpcode)) {
        helperForwardLength = RESULT_SLOT_BINARY_BODY_LENGTH;
      }

      if (resolvedLocalLongBinary(helperResultOpcode)) {
        helperForwardLength = RESULT_SLOT_BINARY_BODY_LENGTH;
      }

      if (resolvedLocalLongPair(helperResultOpcode)) {
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
      if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
        functionsLength += 4;
        entryTypeOffset += 1;
      }

      codeLength = helperForwardLength + helperInverseLength + entryForwardLength;
    }

    if (1 < program.helperCount) {
      codeLength = entryForwardLength;
      entryTypeOffset = 0;
      long helper = 0;
      while (helper < program.helperCount) limit MAX_SCALAR_HELPERS {
        HelperBody body = helperAt(program, helper);
        entryTypeOffset += boundedHelperLocalCount(body) + 1;
        codeLength += boundedHelperForwardLength(body);
        helper += 1;
      }

      functionsLength = 4 + (program.helperCount + 1) * 40;
      functionsLength += (entryTypeOffset + entryLocalCount) * 4;
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

    if (1 < program.helperCount) {
      cursor = writeLibraryStrings(
        output,
        cursor,
        source,
        program,
        moduleName,
        importedModule,
        importedHelperCount,
        libraryStrings
      );
    } else {
      cursor = writeStringTable(output, cursor, source, program, moduleName, strings);
    }

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
    if (1 < program.helperCount) {
      long helperCodeOffset = 0;
      long descriptorHelper = 0;
      while (descriptorHelper < program.helperCount) limit MAX_SCALAR_HELPERS {
        HelperBody descriptorBody = helperAt(program, descriptorHelper);
        cursor = writeFunctionDescriptor(
          output,
          cursor,
          descriptorHelper,
          libraryStrings.helperIndices[descriptorHelper],
          helperCodeOffset,
          boundedHelperForwardLength(descriptorBody),
          /* flags= */ 4,
          4294967295,
          0,
          parameterCountForHelper(descriptorBody.kind),
          boundedHelperLocalCount(descriptorBody),
          boundedHelperTypeOffset(program, descriptorHelper)
        );
        helperCodeOffset += boundedHelperForwardLength(descriptorBody);
        descriptorHelper += 1;
      }

      cursor = writeFunctionDescriptor(
        output,
        cursor,
        program.helperCount,
        mainIndex,
        helperCodeOffset,
        entryForwardLength,
        0,
        4294967295,
        0,
        0,
        entryLocalCount,
        entryTypeOffset
      );
      long typedHelper = 0;
      while (typedHelper < program.helperCount) limit MAX_SCALAR_HELPERS {
        HelperBody typedBody = helperAt(program, typedHelper);
        if (booleanResultHelper(typedBody.kind)) {
          cursor = writeBooleanLocalType(output, cursor);
        } else {
          cursor = writeSignedLocalType(output, cursor);
        }

        long parameterType = 0;
        while (parameterType < parameterCountForHelper(typedBody.kind)) limit 2 {
          if (booleanParameterHelper(typedBody.kind)) {
            cursor = writeBooleanLocalType(output, cursor);
          } else {
            cursor = writeSignedLocalType(output, cursor);
          }

          parameterType += 1;
        }

        cursor = writeSequenceLocalTypes(
          output,
          cursor,
          typedBody.opcodes,
          typedBody.statementCount
        );
        typedHelper += 1;
      }

      cursor = writeSequenceLocalTypes(
        output,
        cursor,
        program.statementOpcodes,
        program.statementCount
      );
    } else {
      if (program.helperCount == 1) {
        long helperFlags = helperAt(program, 0).kind;
        if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
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
        if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
          if (booleanResultHelper(helperAt(program, 0).kind)) {
            cursor = writeBooleanLocalType(output, cursor);
          } else {
            cursor = writeSignedLocalType(output, cursor);
          }
        }

        long helperParameterIndex = 0;
        while (helperParameterIndex < helperParameterCount) limit 2 {
          if (booleanParameterHelper(helperAt(program, 0).kind)) {
            cursor = writeBooleanLocalType(output, cursor);
          } else {
            cursor = writeSignedLocalType(output, cursor);
          }

          helperParameterIndex += 1;
        }

        if (helperAt(program, 0).kind == HELPER_REVERSIBLE) {} else {
          if (resultSlotProgram) {
            cursor = writeBooleanLocalType(output, cursor);
            cursor = writeSignedLocalType(output, cursor);
          } else {
            cursor = writeSequenceLocalTypes(
              output,
              cursor,
              helperAt(program, 0).opcodes,
              helperAt(program, 0).statementCount
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
    return new CoreCompilation(finalCursor, codeOffset);
  }

}
