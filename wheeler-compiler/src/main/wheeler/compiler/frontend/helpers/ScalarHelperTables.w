//! Resolves names and calls in bounded scalar helper tables.

module wheeler.compiler.scalar_helper_tables;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.assignment_call_kinds;
import wheeler.compiler.assignment_call_operands;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.forwarded_helper_result_kinds;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.helper_source_types;
import wheeler.compiler.ir;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_operands;
import wheeler.compiler.void_call_widths;
import wheeler.compiler.wide_local_calls;
import wheeler.compiler.wide_return_sources;

classical class ScalarHelperTables {
  /// Carries bounded call targets resolved against one helper table.
  public record ResolvedCalls(long[64] functions, boolean valid) {}

  /// Checks whether one helper returns a Boolean scalar.
  public boolean booleanHelperKind(long kind) {
    return booleanResultHelper(kind);
  }

  private long callerLocalType(HelperBody caller, long opcode, long local, long argument) {
    if (oneArgumentCallStatement(opcode)) {
      if (oneArgumentCallNamed(opcode)) {
        return helperLocalType(caller, local);
      }

      if (oneArgumentBooleanCall(opcode)) {
        return TYPE_BOOLEAN;
      }

      return TYPE_SIGNED;
    }

    if (twoArgumentCallStatement(opcode)) {
      boolean named = twoArgumentCallFirstNamed(opcode);
      if (argument == 1) {
        named = twoArgumentCallSecondNamed(opcode);
      }

      if (named) {
        return helperLocalType(caller, local);
      }

      if (twoArgumentBooleanCall(opcode)) {
        return TYPE_BOOLEAN;
      }

      return TYPE_SIGNED;
    }

    return helperLocalType(caller, local);
  }

  private boolean callParametersMatch(
    HelperBody caller,
    HelperBody candidate,
    long opcode,
    long argumentCount,
    long firstSource,
    long secondSource
  ) {
    if (candidate.parameterCount == argumentCount) {} else {
      return false;
    }

    long wideFirstSources = firstSource;
    long wideLastSources = secondSource;
    if (argumentCount == 0) {
      return true;
    }

    if (assignmentCallStatement(opcode)) {
      long assignmentArgument = 0;
      while (assignmentArgument < argumentCount) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
        long assignmentSource = assignmentCallSource(
          opcode,
          wideFirstSources,
          wideLastSources,
          assignmentArgument
        );
        if (
          callerLocalType(caller, opcode, assignmentSource, assignmentArgument)
            == candidate.parameterTypes[assignmentArgument]
        ) {} else {
          return false;
        }

        assignmentArgument += 1;
      }

      return true;
    }

    if (voidCallStatement(opcode)) {
      long voidArgument = 0;
      while (voidArgument < argumentCount) limit MAX_VOID_CALL_ARGUMENTS {
        long voidSource = voidCallSource(
          opcode,
          wideFirstSources,
          wideLastSources,
          voidArgument
        );
        if (
          callerLocalType(caller, opcode, voidSource, voidArgument)
            == candidate.parameterTypes[voidArgument]
        ) {} else {
          return false;
        }

        voidArgument += 1;
      }

      return true;
    }

    if (wideLocalCallStatement(opcode)) {
      long argument = 0;
      while (argument < argumentCount) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
        long source = wideLocalCallSource(opcode, wideFirstSources, wideLastSources, argument);
        if (
          callerLocalType(caller, opcode, source, argument) == candidate.parameterTypes[argument]
        ) {} else {
          return false;
        }

        argument += 1;
      }

      return true;
    }

    if (earlyUtf8Call(opcode)) {
      firstSource = firstSource / EARLY_UTF8_CALL_SOURCE_SCALE;
      secondSource = secondSource % EARLY_UTF8_CALL_SOURCE_SCALE;
    } else {
      if (voidCallStatement(opcode)) {} else {
        if (resolvedReturnHelperCall(opcode)) {
          if (4 < argumentCount) {
            firstSource = wideReturnFirstSource(wideFirstSources);
            secondSource = wideReturnSecondSource(wideFirstSources);
          } else {
            firstSource = returnHelperCallFirstSource(opcode);
            if (argumentCount == 2) {
              firstSource -= RETURN_HELPER_CALL_TWO_SOURCE_OFFSET;
            }

            secondSource = returnHelperCallSecondSource(opcode);
          }
        }
      }
    }

    if (
      callerLocalType(caller, opcode, firstSource, 0) == candidate.parameterTypes[0]
    ) {} else {
      return false;
    }

    if (argumentCount == 1) {
      return true;
    }

    if (
      callerLocalType(caller, opcode, secondSource, 1) == candidate.parameterTypes[1]
    ) {} else {
      return false;
    }

    if (argumentCount == 2) {
      return true;
    }

    long thirdSource = voidCallThirdSource(opcode);
    if (2 < argumentCount) {
      if (voidCallStatement(opcode)) {} else {
        if (4 < argumentCount) {
          thirdSource = wideReturnThirdSource(wideFirstSources);
        } else {
          if (threeArgumentCallStatement(opcode)) {
            thirdSource = threeArgumentThirdSource(opcode);
          } else {
            if (fourArgumentCallStatement(opcode)) {
              thirdSource = fourArgumentCallThirdSource(opcode);
            } else {
              thirdSource = returnHelperCallThirdSource(opcode);
            }
          }
        }
      }
    }

    if (
      callerLocalType(caller, opcode, thirdSource, 2) == candidate.parameterTypes[2]
    ) {} else {
      return false;
    }

    if (argumentCount == 3) {
      return true;
    }

    long fourthSource = wideReturnFourthSource(wideFirstSources);
    if (argumentCount == 4) {
      if (fourArgumentCallStatement(opcode)) {
        fourthSource = fourArgumentCallFourthSource(opcode);
      } else {
        fourthSource = returnHelperCallFourthSource(opcode);
      }
    }

    if (
      callerLocalType(caller, opcode, fourthSource, 3) == candidate.parameterTypes[3]
    ) {} else {
      return false;
    }

    if (argumentCount == 4) {
      return true;
    }

    long fifthSource = wideReturnFifthSource(wideLastSources);
    if (
      callerLocalType(caller, opcode, fifthSource, 4) == candidate.parameterTypes[4]
    ) {} else {
      return false;
    }

    if (argumentCount == 5) {
      return true;
    }

    long sixthSource = wideReturnSixthSource(wideLastSources);
    if (
      callerLocalType(caller, opcode, sixthSource, 5) == candidate.parameterTypes[5]
    ) {} else {
      return false;
    }

    if (argumentCount == 6) {
      return true;
    }

    long seventhSource = wideReturnSeventhSource(wideLastSources);
    return callerLocalType(caller, opcode, seventhSource, 6) == candidate.parameterTypes[6];
  }

  /// Compares two helper names in one source.
  public long compareHelpers(borrow utf8 source, HelperBody left, HelperBody right) {
    return compareAsciiSlices(
      source,
      left.name.start,
      left.name.length,
      right.name.start,
      right.name.length
    );
  }

  /// Selects one helper from twenty-three fixed table slots.
  public HelperBody selectedBody(
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
    HelperBody twentyThird,
    long index
  ) {
    if (index == 0) {
      return first;
    }

    if (index == 1) {
      return second;
    }

    if (index == 2) {
      return third;
    }

    if (index == 3) {
      return fourth;
    }

    if (index == 4) {
      return fifth;
    }

    if (index == 5) {
      return sixth;
    }

    if (index == 6) {
      return seventh;
    }

    if (index == 7) {
      return eighth;
    }

    if (index == 8) {
      return ninth;
    }

    if (index == 9) {
      return tenth;
    }

    if (index == 10) {
      return eleventh;
    }

    if (index == 11) {
      return twelfth;
    }

    if (index == 12) {
      return thirteenth;
    }

    if (index == 13) {
      return fourteenth;
    }

    if (index == 14) {
      return fifteenth;
    }

    if (index == 15) {
      return sixteenth;
    }

    if (index == 16) {
      return seventeenth;
    }

    if (index == 17) {
      return eighteenth;
    }

    if (index == 18) {
      return nineteenth;
    }

    if (index == 19) {
      return twentieth;
    }

    if (index == 20) {
      return twentyFirst;
    }

    if (index == 21) {
      return twentySecond;
    }

    return twentyThird;
  }

  /// Checks that all occupied helper names are distinct.
  public boolean uniqueHelpers(
    borrow utf8 source,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
    HelperBody twentyThird,
    long helperCount
  ) {
    long left = 0;
    while (left < helperCount) limit MAX_SCALAR_HELPERS {
      HelperBody leftBody = selectedBody(
        first,
        second,
        third,
        fourth,
        fifth,
        sixth,
        seventh,
        eighth,
        ninth,
        tenth,
        eleventh,
        twelfth,
        thirteenth,
        fourteenth,
        fifteenth,
        sixteenth,
        seventeenth,
        eighteenth,
        nineteenth,
        twentieth,
        twentyFirst,
        twentySecond,
        twentyThird,
        left
      );
      long right = left + 1;
      while (right < helperCount) limit MAX_SCALAR_HELPERS {
        HelperBody rightBody = selectedBody(
          first,
          second,
          third,
          fourth,
          fifth,
          sixth,
          seventh,
          eighth,
          ninth,
          tenth,
          eleventh,
          twelfth,
          thirteenth,
          fourteenth,
          fifteenth,
          sixteenth,
          seventeenth,
          eighteenth,
          nineteenth,
          twentieth,
          twentyFirst,
          twentySecond,
          twentyThird,
          right
        );
        if (compareHelpers(source, leftBody, rightBody) == 0) {
          return false;
        }

        right += 1;
      }

      left += 1;
    }

    return true;
  }

  private boolean localScalarCallMatches(HelperBody candidate, long opcode) {
    // Keep the exact signed form ahead of Boolean-shaped rejection paths.
    if (assignmentCallStatement(opcode)) {
      long assignmentArity = assignmentCallArity(opcode);
      if (candidate.kind == signedScalarHelperKind(assignmentArity)) {
        return candidate.parameterCount == assignmentArity;
      }

      return false;
    }

    if (twoArgumentSignedResultCall(opcode)) {
      if (candidate.kind == HELPER_SIGNED_TWO) {
        return candidate.parameterCount == 2;
      }

      return false;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      if (candidate.kind == HELPER_SIGNED) {
        return candidate.parameterCount == 0;
      }

      return false;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      if (candidate.kind == HELPER_BOOLEAN) {
        return candidate.parameterCount == 0;
      }

      return false;
    }

    if (twoArgumentBooleanSignedCall(opcode)) {
      if (candidate.kind == HELPER_BOOLEAN_SIGNED_TWO) {
        return candidate.parameterCount == 2;
      }

      return false;
    }

    if (twoArgumentBooleanCall(opcode)) {
      if (candidate.kind == HELPER_BOOLEAN_TWO) {
        if (candidate.parameterCount == 2) {
          if (candidate.parameterTypes[0] == TYPE_BOOLEAN) {
            return candidate.parameterTypes[1] == TYPE_BOOLEAN;
          }

          return false;
        }
      }

      return false;
    }

    if (wideLocalCallStatement(opcode)) {
      long arity = wideLocalCallArity(opcode);
      long expectedKind = signedScalarHelperKind(arity);
      if (booleanWideLocalCall(opcode)) {
        expectedKind = booleanScalarHelperKind(arity);
      }

      if (candidate.kind == expectedKind) {
        return candidate.parameterCount == arity;
      }

      return false;
    }

    return localOneArgumentCallMatches(candidate, opcode);
  }

  private boolean localOneArgumentCallMatches(HelperBody candidate, long opcode) {
    if (candidate.parameterCount == 1) {} else {
      return false;
    }

    if (oneArgumentBooleanSignedCall(opcode)) {
      return candidate.kind == HELPER_BOOLEAN_SIGNED_ONE;
    }

    if (oneArgumentBooleanCall(opcode)) {
      if (candidate.kind == HELPER_BOOLEAN_ONE) {
        return candidate.parameterTypes[0] == TYPE_BOOLEAN;
      }

      return false;
    }

    if (oneArgumentCallStatement(opcode)) {
      return candidate.kind == HELPER_SIGNED_ONE;
    }

    return false;
  }

  private long resolveCallFunction(
    borrow utf8 source,
    HelperBody caller,
    SourceRange target,
    boolean forwarding,
    long callOpcode,
    long argumentCount,
    long firstSource,
    long secondSource,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
    HelperBody twentyThird,
    long helperCount
  ) {
    if (target.length == 0) {
      return -1;
    }

    long found = -1;
    long helper = 0;
    while (helper < helperCount) limit MAX_SCALAR_HELPERS {
      HelperBody candidate = selectedBody(
        first,
        second,
        third,
        fourth,
        fifth,
        sixth,
        seventh,
        eighth,
        ninth,
        tenth,
        eleventh,
        twelfth,
        thirteenth,
        fourteenth,
        fifteenth,
        sixteenth,
        seventeenth,
        eighteenth,
        nineteenth,
        twentieth,
        twentyFirst,
        twentySecond,
        twentyThird,
        helper
      );
      long order = compareAsciiSlices(
        source,
        target.start,
        target.length,
        candidate.name.start,
        candidate.name.length
      );
      if (order == 0) {
        if (forwarding) {
          boolean sameResultKind = candidate.kind != HELPER_VOID;
          if (sameResultKind) {
            sameResultKind = booleanHelperKind(caller.kind) == booleanHelperKind(candidate.kind);
          }

          if (sameResultKind) {
            sameResultKind = utf8ResultHelper(caller.kind) == utf8ResultHelper(candidate.kind);
          }

          if (sameResultKind) {
            if (
              callParametersMatch(
                caller,
                candidate,
                callOpcode,
                argumentCount,
                firstSource,
                secondSource
              )
            ) {
              found = helper;
            }
          }
        } else {
          if (voidCallStatement(callOpcode)) {
            if (candidate.kind == HELPER_VOID) {
              if (
                callParametersMatch(
                  caller,
                  candidate,
                  callOpcode,
                  argumentCount,
                  firstSource,
                  secondSource
                )
              ) {
                found = helper;
              }
            }
          } else {
            boolean scalarCall = scalarResultCallStatement(callOpcode);
            if (assignmentCallStatement(callOpcode)) {
              scalarCall = true;
            }

            if (scalarCall) {
              if (localScalarCallMatches(candidate, callOpcode)) {
                if (
                  callParametersMatch(
                    caller,
                    candidate,
                    callOpcode,
                    argumentCount,
                    firstSource,
                    secondSource
                  )
                ) {
                  found = helper;
                }
              }
            } else {
              if (candidate.kind == HELPER_BOOLEAN_SIGNED_ONE) {
                if (candidate.parameterCount == 1) {
                  if (candidate.parameterTypes[0] == TYPE_SIGNED) {
                    found = helper;
                  }
                }
              }
            }
          }
        }
      }

      helper += 1;
    }

    return found;
  }

  /// Resolves both call sites carried by one helper body.
  public ResolvedCalls resolveCalls(
    borrow utf8 source,
    HelperBody caller,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
    HelperBody twentyThird,
    long helperCount
  ) {
    region callArena = new region(/* bytes= */ 512, /* allocations= */ 1);
    words functionWork = allocate(callArena, MAX_SCALAR_HELPER_CALLS);
    boolean valid = true;
    long call = 0;
    while (call < caller.callCount) limit MAX_SCALAR_HELPER_CALLS {
      if (valid) {
        long callStatement = caller.callStatements[call];
        long callOpcode = caller.opcodes[callStatement];
        boolean forwarding = resolvedReturnHelperCall(callOpcode);
        if (earlyUtf8Call(callOpcode)) {
          forwarding = true;
        }

        long argumentCount = 1;
        if (callOpcode == STATEMENT_LOCAL_CALL_NAMED) {
          argumentCount = 0;
        }

        if (callOpcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
          argumentCount = 0;
        }

        if (twoArgumentCallStatement(callOpcode)) {
          argumentCount = 2;
        }

        if (earlyUtf8Call(callOpcode)) {
          argumentCount = 2;
        }

        if (threeArgumentCallStatement(callOpcode)) {
          argumentCount = 3;
        }

        if (wideLocalCallStatement(callOpcode)) {
          argumentCount = wideLocalCallArity(callOpcode);
        }

        if (forwarding) {
          if (earlyUtf8Call(callOpcode)) {
            argumentCount = 2;
          } else {
            argumentCount = returnHelperCallArity(callOpcode);
          }
        }

        if (voidCallStatement(callOpcode)) {
          argumentCount = voidCallArity(callOpcode);
        }

        if (assignmentCallStatement(callOpcode)) {
          argumentCount = assignmentCallArity(callOpcode);
        }

        long function = resolveCallFunction(
          source,
          caller,
          new SourceRange(caller.callTargetStarts[call], caller.callTargetLengths[call]),
          forwarding,
          callOpcode,
          argumentCount,
          caller.operands[callStatement],
          caller.secondaryOperands[callStatement],
          first,
          second,
          third,
          fourth,
          fifth,
          sixth,
          seventh,
          eighth,
          ninth,
          tenth,
          eleventh,
          twelfth,
          thirteenth,
          fourteenth,
          fifteenth,
          sixteenth,
          seventeenth,
          eighteenth,
          nineteenth,
          twentieth,
          twentyFirst,
          twentySecond,
          twentyThird,
          helperCount
        );
        if (-1 < function) {
          set(functionWork, call, function);
        } else {
          valid = false;
        }
      }

      call += 1;
    }

    long[64] functions = freezeHelperCallColumn(functionWork);
    drop(functionWork);
    drop(callArena);
    return new ResolvedCalls(functions, valid);
  }

  /// Installs resolved call identities in one immutable helper body.
  public HelperBody withCalls(HelperBody body, ResolvedCalls calls) {
    return new HelperBody(
      body.name,
      body.opcodes,
      body.operands,
      body.secondaryOperands,
      body.kind,
      body.parameterCount,
      body.parameterTypes,
      body.statementCount,
      body.resultStatement,
      body.callTargetStarts,
      body.callTargetLengths,
      body.callStatements,
      calls.functions,
      body.callCount
    );
  }
}
