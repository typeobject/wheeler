package com.typeobject.wheeler.examples;

import java.util.List;
import org.junit.jupiter.api.Test;

/** A global fallback cannot bypass a wrong-type or ambiguous local declaration. */
final class NativeCompilerGlobalCallBindingExampleTest {
  @Test
  void preservesLocalPrecedenceCountedWindowsAndBothDestinationDomains() throws Exception {
    var program = NativeSourceFrontFixture.program(List.of(
        "wheeler.compiler.assignment_call_arities",
        "wheeler.compiler.assignment_call_identities",
        "wheeler.compiler.assignment_call_kinds",
        "wheeler.compiler.assignment_call_resolution",
        "wheeler.compiler.compiler_token_limits",
        "wheeler.compiler.local_resolution"), 4096, "", """
        assert(count == 23);
        region scratch = new region(/* bytes= */ 32, /* allocations= */ 1);
        words prior = allocate(scratch, 4);
        long zero = STATEMENT_ASSIGN_CALL_ZERO_NAMED;
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 0, 17, zero) == -1);
        set(starts, COMPILER_GLOBAL_NAME_TOKEN, starts[0]);
        set(lengths, COMPILER_GLOBAL_NAME_TOKEN, lengths[0]);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 0, 17, zero)
          == STATEMENT_GLOBAL_ASSIGN_CALL_BASE);
        set(prior, 0, 2);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 1, 17) == 1);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 1, 17, zero)
          == resolvedAssignmentCall(0, 1));
        set(prior, 0, 7);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 1, 17) == 1);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 1, 17, zero) == -1);
        set(prior, 0, 12);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 1, 17, zero)
          == STATEMENT_GLOBAL_ASSIGN_CALL_BASE);
        set(prior, 0, 2);
        set(prior, 1, 7);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 2, 17) == 2);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 2, 17, zero) == -1);
        set(prior, 0, -3);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 1, 17, zero)
          == resolvedAssignmentCall(0, 0));
        set(prior, 0, -3 - BOOLEAN_PARAMETER_TOKEN_BIAS);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 1, 17, zero) == -1);
        long minimum = -9223372036854775807 - 1;
        long maximum = 9223372036854775807;
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, minimum, 17, zero) == -1);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, maximum, 17, zero) == -1);
        assert(resolveAssignmentCallOpcode(source, starts, lengths, prior, 5, 17, zero) == -1);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 0, minimum) == -1);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 0, maximum) == -1);
        set(prior, 0, minimum);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 1, 17) == -1);
        set(prior, 0, maximum);
        assert(priorDeclarationNameCount(source, starts, lengths, prior, 1, 17) == -1);
        long arity = 0;
        while (arity < 8) limit 8 {
          long global = resolvedGlobalAssignmentCall(arity);
          assert(globalAssignmentCallStatement(global));
          assert(assignmentCallStatement(global));
          assert(assignmentCallArity(global) == arity);
          assert(assignmentCallTarget(global) == 0);
          long lastLocal = resolvedAssignmentCall(arity, 255);
          assert(assignmentCallStatement(lastLocal));
          assert(globalAssignmentCallStatement(lastLocal) == false);
          assert(assignmentCallArity(lastLocal) == arity);
          assert(assignmentCallTarget(lastLocal) == 255);
          assert(resolvedAssignmentCall(arity, 256) == -1);
          arity += 1;
        }
        assert(resolvedGlobalAssignmentCall(-1) == -1);
        assert(resolvedGlobalAssignmentCall(8) == -1);
        assert(resolvedGlobalAssignmentCall(maximum) == -1);
        assert(resolvedAssignmentCall(minimum, 0) == -1);
        assert(resolvedAssignmentCall(maximum, 0) == -1);
        assert(assignmentCallTarget(STATEMENT_ASSIGN_CALL_ZERO_NAMED) == -1);
        assert(assignmentCallArity(GLOBAL_ASSIGNMENT_CALL_END) == -1);
        set(starts, COMPILER_GLOBAL_NAME_TOKEN, oldStarts[COMPILER_GLOBAL_NAME_TOKEN]);
        set(lengths, COMPILER_GLOBAL_NAME_TOKEN, oldLengths[COMPILER_GLOBAL_NAME_TOKEN]);
        drop(prior);
        drop(scratch);
        """);
    NativeSourceFrontFixture.check(program,
        "// café 𝄞\nobserved ; long observed = 0 ; boolean observed = false ; "
            + "long other = 0 ; observed = helper ( ) ;", machine -> {});
  }
}
