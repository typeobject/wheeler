//! Composes source-ordered direct and structured products into callable windows.

module wheeler.compiler.closure.callable_source_composition;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;

classical class CallableSourceComposition {
  private const long CALLABLE_ROWS = 320;
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_WINDOW_ROWS = 768;
  private const long DIRECT_ROWS = 28672;
  private const long LOOP_ROWS = 2304;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long LOOP_WINDOW_ROWS = 768;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_PRODUCTS = 4096;
  private const long MAX_TYPES = 4096;
  private const long SOURCE_STATEMENT_ORDINAL_ROW = 8192;
  private const long TYPE_ROWS = 12288;

  /// Reports complete function code and local-type windows.
  public record CallableSourceCompositionPlan(
    long instructionCount,
    long length,
    long typeCount,
    boolean valid
  ) {}

  private long callAtStatement(long statement, long callCount, borrow mut words callStatements) {
    long selected = -1;
    long matches = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      if (callStatements[call] == statement) {
        selected = call;
        matches += 1;
      }

      call += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long directAtStatement(long statement, long directCount, borrow mut words directRows) {
    long selected = -1;
    long matches = 0;
    long direct = 0;
    while (direct < directCount) limit MAX_PRODUCTS {
      if (directRows[direct] == statement) {
        selected = direct;
        matches += 1;
      }

      direct += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long loopAtStatement(
    long statement,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long loop = 0;
    while (loop < loopCount) limit 256 {
      if (loopRows[loop] == statementRows[statement]) {
        if (
          loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] == statementRows[SOURCE_STATEMENT_ORDINAL_ROW
            + statement]
        ) {
          selected = loop;
          matches += 1;
        }
      }

      loop += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long typeCodeAt(long owner, long local, long typeCount, borrow mut words typeRows) {
    long selected = -1;
    long matches = 0;
    long type = 0;
    while (type < typeCount) limit MAX_TYPES {
      if (typeRows[type] == owner) {
        if (typeRows[4096 + type] == local) {
          selected = typeRows[8192 + type];
          matches += 1;
        }
      }

      type += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Publishes callable-local code and types only after every source product is consumed once.
  public CallableSourceCompositionPlan composeCallableSourceProducts(
    long callableCount,
    long statementCount,
    borrow mut words statementRows,
    long directCount,
    borrow mut words directRows,
    borrow byteview directCode,
    long callCount,
    borrow mut words callStatements,
    borrow mut words callWindowRows,
    borrow byteview callCode,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words loopWindowRows,
    borrow byteview loopCode,
    long signatureTypeCount,
    borrow mut words signatureTypes,
    long directTypeCount,
    borrow mut words directTypes,
    long callTypeCount,
    borrow mut words callTypes,
    long loopTypeCount,
    borrow mut words loopTypes,
    borrow mut words functionResultTypes,
    borrow mut words returnRows,
    borrow mut words callableRows,
    borrow mut words outputTypes,
    borrow mut bytes outputCode
  ) {
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < statementCount);
    assert(statementCount < MAX_PRODUCTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < directCount);
    assert(directCount < MAX_PRODUCTS + 1);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(bufferLength(directCode) == MAX_CODE_BYTES);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callWindowRows) == CALL_WINDOW_ROWS);
    assert(bufferLength(callCode) == MAX_CODE_BYTES);
    assert(-1 < loopCount);
    assert(loopCount < 257);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(bufferLength(loopWindowRows) == LOOP_WINDOW_ROWS);
    assert(bufferLength(loopCode) == MAX_CODE_BYTES);
    assert(-1 < signatureTypeCount);
    assert(signatureTypeCount < MAX_TYPES + 1);
    assert(bufferLength(signatureTypes) == TYPE_ROWS);
    assert(-1 < directTypeCount);
    assert(directTypeCount < MAX_TYPES + 1);
    assert(bufferLength(directTypes) == TYPE_ROWS);
    assert(-1 < callTypeCount);
    assert(callTypeCount < MAX_TYPES + 1);
    assert(bufferLength(callTypes) == TYPE_ROWS);
    assert(-1 < loopTypeCount);
    assert(loopTypeCount < MAX_TYPES + 1);
    assert(bufferLength(loopTypes) == TYPE_ROWS);
    assert(bufferLength(functionResultTypes) == MAX_CALLABLES);
    assert(bufferLength(returnRows) == 192);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(bufferLength(outputTypes) == TYPE_ROWS);
    assert(bufferLength(outputCode) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ 363008, /* allocations= */ 3);
    words stagedCallables = allocate(staging, CALLABLE_ROWS);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    boolean valid = true;
    long consumedDirect = 0;
    long consumedCalls = 0;
    long consumedLoops = 0;
    long codeCursor = 0;
    long instructionCount = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long callableCodeStart = codeCursor;
      long callableInstructionCount = 0;
      long rootBlock = loopBodyRootBlockForOwner(callable, statementCount, statementRows);
      long priorStart = -1;
      long processed = 0;
      while (processed < statementCount) limit MAX_PRODUCTS {
        long statement = nextLoopBodyStatement(
          priorStart,
          statementCount,
          statementRows,
          LOOP_STATEMENT_START_ROW
        );
        if (statement == statementCount) {
          processed = statementCount;
        } else {
          priorStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
          if (statementRows[statement] == callable) {
            if (statementRows[4096 + statement] == rootBlock) {
              long codeStart = -1;
              long codeLength = 0;
              long productInstructionCount = 0;
              boolean callProduct = false;
              boolean directProduct = false;
              if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
                long call = callAtStatement(statement, callCount, callStatements);
                if (-1 < call) {
                  codeStart = callWindowRows[call];
                  codeLength = callWindowRows[512 + call];
                  productInstructionCount = callWindowRows[256 + call];
                  consumedCalls += 1;
                  callProduct = true;
                } else {
                  long direct = directAtStatement(statement, directCount, directRows);
                  if (direct < 0) {
                    valid = false;
                  } else {
                    codeStart = directRows[12288 + direct];
                    codeLength = directRows[16384 + direct];
                    productInstructionCount = directRows[8192 + direct];
                    consumedDirect += 1;
                    directProduct = true;
                  }
                }
              } else {
                long structuredDirect = directAtStatement(statement, directCount, directRows);
                if (-1 < structuredDirect) {
                  codeStart = directRows[12288 + structuredDirect];
                  codeLength = directRows[16384 + structuredDirect];
                  productInstructionCount = directRows[8192 + structuredDirect];
                  consumedDirect += 1;
                  directProduct = true;
                } else {
                  long loop = loopAtStatement(statement, loopCount, loopRows, statementRows);
                  if (loop < 0) {
                    valid = false;
                  } else {
                    codeStart = loopWindowRows[loop];
                    codeLength = loopWindowRows[512 + loop];
                    productInstructionCount = loopWindowRows[256 + loop];
                    consumedLoops += 1;
                  }
                }
              }

              if (codeStart < 0) {
                valid = false;
              }

              if (codeLength < 1) {
                valid = false;
              }

              if (MAX_CODE_BYTES - codeCursor < codeLength) {
                valid = false;
              }

              if (valid) {
                long codeByte = 0;
                while (codeByte < codeLength) limit MAX_CODE_BYTES {
                  if (directProduct) {
                    setByte(stagedCode, codeCursor, directCode[codeStart + codeByte]);
                  } else {
                    if (callProduct) {
                      setByte(stagedCode, codeCursor, callCode[codeStart + codeByte]);
                    } else {
                      setByte(stagedCode, codeCursor, loopCode[codeStart + codeByte]);
                    }
                  }

                  codeCursor += 1;
                  codeByte += 1;
                }

                callableInstructionCount += productInstructionCount;
                instructionCount += productInstructionCount;
              }
            }
          }

          processed += 1;
        }
      }

      if (functionResultTypes[callable] == 0) {
        if (returnRows[callable] != 1) {
          valid = false;
        }

        if (returnRows[64 + callable] != callableInstructionCount) {
          valid = false;
        }

        if (returnRows[128 + callable] != codeCursor - callableCodeStart) {
          valid = false;
        }

        if (MAX_CODE_BYTES - codeCursor < 8) {
          valid = false;
        }

        if (valid) {
          codeCursor = writeInstructionHeader(
            stagedCode,
            codeCursor,
            OPCODE_RETURN,
            INSTRUCTION_FORM_NULLARY
          );
          callableInstructionCount += 1;
          instructionCount += 1;
        }
      } else {
        if (returnRows[callable] != 0) {
          valid = false;
        }

        if (returnRows[64 + callable] + 1 != 0) {
          valid = false;
        }

        if (returnRows[128 + callable] + 1 != 0) {
          valid = false;
        }
      }

      set(stagedCallables, callable, callableCodeStart);
      set(stagedCallables, 64 + callable, codeCursor - callableCodeStart);
      set(stagedCallables, 128 + callable, callableInstructionCount);
      callable += 1;
    }

    if (consumedDirect != directCount) {
      valid = false;
    }

    long nestedCall = 0;
    while (nestedCall < callCount) limit CALL_COUNT_LIMIT {
      long nestedStatement = callStatements[nestedCall];
      if (nestedStatement < 0) {
        valid = false;
      } else {
        if (statementCount - 1 < nestedStatement) {
          valid = false;
        } else {
          long nestedOwner = statementRows[nestedStatement];
          if (nestedOwner < 0) {
            valid = false;
          } else {
            if (callableCount - 1 < nestedOwner) {
              valid = false;
            } else {
              long nestedRoot = loopBodyRootBlockForOwner(
                nestedOwner,
                statementCount,
                statementRows
              );
              if (statementRows[4096 + nestedStatement] != nestedRoot) {
                consumedCalls += 1;
              }
            }
          }
        }
      }

      nestedCall += 1;
    }

    if (consumedCalls != callCount) {
      valid = false;
    }

    long rootLoopCount = 0;
    long countedLoop = 0;
    while (countedLoop < loopCount) limit 256 {
      if (loopRows[2048 + countedLoop] == 1) {
        rootLoopCount += 1;
      }

      countedLoop += 1;
    }

    if (consumedLoops != rootLoopCount) {
      valid = false;
    }

    long typeCount = 0;
    long consumedSignatureTypes = 0;
    long consumedDirectTypes = 0;
    long consumedCallTypes = 0;
    long consumedLoopTypes = 0;
    callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      set(stagedCallables, 192 + callable, typeCount);
      long local = 0;
      boolean selectingType = true;
      while (selectingType) limit 256 {
        long code = -1;
        long signatureCode = typeCodeAt(callable, local, signatureTypeCount, signatureTypes);
        long directCodeType = typeCodeAt(callable, local, directTypeCount, directTypes);
        long callCodeType = typeCodeAt(callable, local, callTypeCount, callTypes);
        long loopCodeType = typeCodeAt(callable, local, loopTypeCount, loopTypes);
        long matches = 0;
        if (-1 < signatureCode) {
          code = signatureCode;
          matches += 1;
          consumedSignatureTypes += 1;
        }

        if (-1 < directCodeType) {
          code = directCodeType;
          matches += 1;
          consumedDirectTypes += 1;
        }

        if (-1 < callCodeType) {
          code = callCodeType;
          matches += 1;
          consumedCallTypes += 1;
        }

        if (-1 < loopCodeType) {
          code = loopCodeType;
          matches += 1;
          consumedLoopTypes += 1;
        }

        if (matches == 0) {
          selectingType = false;
        } else {
          if (matches != 1) {
            valid = false;
          }

          if (MAX_TYPES < typeCount + 1) {
            valid = false;
          } else {
            set(stagedTypes, typeCount, callable);
            set(stagedTypes, 4096 + typeCount, local);
            set(stagedTypes, 8192 + typeCount, code);
            typeCount += 1;
          }

          local += 1;
        }
      }

      set(stagedCallables, 256 + callable, local);
      callable += 1;
    }

    if (consumedSignatureTypes != signatureTypeCount) {
      valid = false;
    }

    if (consumedDirectTypes != directTypeCount) {
      valid = false;
    }

    if (consumedCallTypes != callTypeCount) {
      valid = false;
    }

    if (consumedLoopTypes != loopTypeCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < CALLABLE_ROWS) limit CALLABLE_ROWS {
        set(callableRows, row, stagedCallables[row]);
        row += 1;
      }

      row = 0;
      while (row < TYPE_ROWS) limit TYPE_ROWS {
        set(outputTypes, row, stagedTypes[row]);
        row += 1;
      }

      long outputCodeByte = 0;
      while (outputCodeByte < codeCursor) limit MAX_CODE_BYTES {
        setByte(outputCode, outputCodeByte, stagedCode[outputCodeByte]);
        outputCodeByte += 1;
      }
    }

    drop(stagedCode);
    drop(stagedTypes);
    drop(stagedCallables);
    drop(staging);
    if (valid == false) {
      return new CallableSourceCompositionPlan(0, 0, 0, false);
    }

    return new CallableSourceCompositionPlan(instructionCount, codeCursor, typeCount, true);
  }
}
