//! Resolves names and calls in bounded scalar helper tables.

module wheeler.compiler.scalar_helper_tables;

import wheeler.compiler.encoding;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.ir;
import wheeler.compiler.resolved_return_call_kinds;

classical class ScalarHelperTables {
  /// Carries bounded call targets resolved against one helper table.
  public record ResolvedCalls(long[8] functions, boolean valid) {}

  /// Checks whether one helper returns a Boolean scalar.
  public boolean booleanHelperKind(long kind) {
    return booleanResultHelper(kind);
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

  private long resolveCallFunction(
    borrow utf8 source,
    HelperBody caller,
    SourceRange target,
    boolean forwarding,
    long argumentCount,
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
          if (booleanHelperKind(caller.kind)) {
            if (booleanHelperKind(candidate.kind)) {
              if (parameterCountForHelper(candidate.kind) == argumentCount) {
                found = helper;
              }
            }
          }
        } else {
          if (candidate.kind == HELPER_BOOLEAN_SIGNED_ONE) {
            found = helper;
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
    region callArena = new region(/* bytes= */ 64, /* allocations= */ 1);
    words functionWork = allocate(callArena, MAX_SCALAR_HELPER_CALLS);
    boolean valid = true;
    long call = 0;
    while (call < caller.callCount) limit MAX_SCALAR_HELPER_CALLS {
      if (valid) {
        long callStatement = caller.callStatements[call];
        boolean forwarding = callStatement == caller.resultStatement;
        long argumentCount = 1;
        if (forwarding) {
          argumentCount = returnHelperCallArity(caller.opcodes[callStatement]);
        }

        long function = resolveCallFunction(
          source,
          caller,
          new SourceRange(caller.callTargetStarts[call], caller.callTargetLengths[call]),
          forwarding,
          argumentCount,
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

    long[8] functions = new long[8](
      functionWork[0],
      functionWork[1],
      functionWork[2],
      functionWork[3],
      functionWork[4],
      functionWork[5],
      functionWork[6],
      functionWork[7]
    );
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
