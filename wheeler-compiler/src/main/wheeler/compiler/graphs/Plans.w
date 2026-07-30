//! Classifies bounded five-module constant graphs before linking.

module wheeler.compiler.graphs.plans;

import wheeler.compiler.module_linker;

classical class CompilerGraphPlans {
  /// Names the five-module direct-star plan.
  public const long FIVE_PLAN_DIRECT = 1;
  /// Names the five-module chain plan.
  public const long FIVE_PLAN_CHAIN = 2;
  /// Names the five-module four-leaf-fork plan.
  public const long FIVE_PLAN_FORK = 3;
  /// Names a three-leaf fork beside one direct root import.
  public const long FIVE_PLAN_FORK_AND_DIRECT = 4;
  /// Names one chain edge beside three direct root imports.
  public const long FIVE_PLAN_CHAIN_AND_DIRECTS = 5;

  private const long SINGLE_IMPORT = 1;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_IMPORTS = 5;

  /// Carries one validated five-module topology selection.
  public record FiveGraphPlan(long topology, boolean valid) {}

  private boolean directSource(
    borrow utf8 source,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    LinkPlan plan = planConstantImport(source, rootSource, expectedImportCount);
    return plan.valid;
  }

  private boolean edge(borrow utf8 source, borrow utf8 dependentSource, long expectedImportCount) {
    LinkPlan plan = planPrivateConstantImport(source, dependentSource, expectedImportCount);
    return plan.valid;
  }

  private boolean edgeFrom(
    borrow utf8 source,
    borrow utf8 firstCandidate,
    borrow utf8 secondCandidate,
    borrow utf8 thirdCandidate,
    borrow utf8 fourthCandidate,
    long expectedImportCount
  ) {
    if (edge(source, firstCandidate, expectedImportCount)) {
      return true;
    }

    if (edge(source, secondCandidate, expectedImportCount)) {
      return true;
    }

    if (edge(source, thirdCandidate, expectedImportCount)) {
      return true;
    }

    return edge(source, fourthCandidate, expectedImportCount);
  }

  private boolean hasEdge(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    long expectedImportCount
  ) {
    if (
      edgeFrom(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        expectedImportCount
      )
    ) {
      return true;
    }

    if (
      edgeFrom(
        secondSource,
        firstSource,
        thirdSource,
        fourthSource,
        fifthSource,
        expectedImportCount
      )
    ) {
      return true;
    }

    if (
      edgeFrom(
        thirdSource,
        firstSource,
        secondSource,
        fourthSource,
        fifthSource,
        expectedImportCount
      )
    ) {
      return true;
    }

    if (
      edgeFrom(
        fourthSource,
        firstSource,
        secondSource,
        thirdSource,
        fifthSource,
        expectedImportCount
      )
    ) {
      return true;
    }

    return edgeFrom(
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      expectedImportCount
    );
  }

  private boolean allDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    if (directSource(firstSource, rootSource, FIVE_IMPORTS)) {} else {
      return false;
    }

    if (directSource(secondSource, rootSource, FIVE_IMPORTS)) {} else {
      return false;
    }

    if (directSource(thirdSource, rootSource, FIVE_IMPORTS)) {} else {
      return false;
    }

    if (directSource(fourthSource, rootSource, FIVE_IMPORTS)) {} else {
      return false;
    }

    return directSource(fifthSource, rootSource, FIVE_IMPORTS);
  }

  private long directCount(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    long count = 0;
    if (directSource(firstSource, rootSource, expectedImportCount)) {
      count += 1;
    }

    if (directSource(secondSource, rootSource, expectedImportCount)) {
      count += 1;
    }

    if (directSource(thirdSource, rootSource, expectedImportCount)) {
      count += 1;
    }

    if (directSource(fourthSource, rootSource, expectedImportCount)) {
      count += 1;
    }

    if (directSource(fifthSource, rootSource, expectedImportCount)) {
      count += 1;
    }

    return count;
  }

  /// Selects one supported five-module topology independent of source order.
  public FiveGraphPlan planFiveConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    if (
      allDirect(firstSource, secondSource, thirdSource, fourthSource, fifthSource, rootSource)
    ) {
      return new FiveGraphPlan(FIVE_PLAN_DIRECT, true);
    }

    if (
      hasEdge(firstSource, secondSource, thirdSource, fourthSource, fifthSource, FOUR_IMPORTS)
    ) {
      return new FiveGraphPlan(FIVE_PLAN_FORK, true);
    }

    if (
      hasEdge(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        THREE_IMPORTS
      )
    ) {
      return new FiveGraphPlan(FIVE_PLAN_FORK_AND_DIRECT, true);
    }

    if (
      hasEdge(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        SINGLE_IMPORT
      )
    ) {
      long rootImports = directCount(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        FOUR_IMPORTS
      );
      if (rootImports == THREE_IMPORTS) {
        return new FiveGraphPlan(FIVE_PLAN_CHAIN_AND_DIRECTS, true);
      }

      return new FiveGraphPlan(FIVE_PLAN_CHAIN, true);
    }

    return new FiveGraphPlan(0, false);
  }
}
