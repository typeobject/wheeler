//! Classifies bounded five-module constant graphs before linking.

module wheeler.compiler.graphs.plans;

import wheeler.compiler.graphs.five_plan_kinds;
import wheeler.compiler.graphs.five_structures;

classical class CompilerGraphPlans {

  /// Carries one validated topology and deterministic leaf-first source order.
  public record FiveGraphPlan(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    boolean valid
  ) {}

  private FiveGraphPlan invalidPlan() {
    return new FiveGraphPlan(0, 0, 0, 0, 0, 0, false);
  }

  private FiveGraphPlan orderedPlan(long topology, FiveGraphStructure structure) {
    return new FiveGraphPlan(
      topology,
      structure.first,
      structure.second,
      structure.third,
      structure.fourth,
      structure.fifth,
      true
    );
  }

  private long publicTopology(long structure) {
    if (structure == FIVE_STRUCTURE_DIRECT) {
      return FIVE_PLAN_DIRECT;
    }

    if (structure == FIVE_STRUCTURE_CHAIN) {
      return FIVE_PLAN_CHAIN;
    }

    if (structure == FIVE_STRUCTURE_FORK) {
      return FIVE_PLAN_FORK;
    }

    if (structure == FIVE_STRUCTURE_FORK_AND_DIRECT) {
      return FIVE_PLAN_FORK_AND_DIRECT;
    }

    if (structure == FIVE_STRUCTURE_CHAIN_AND_DIRECTS) {
      return FIVE_PLAN_CHAIN_AND_DIRECTS;
    }

    if (structure == FIVE_STRUCTURE_FORK_AND_TWO_DIRECTS) {
      return FIVE_PLAN_FORK_AND_TWO_DIRECTS;
    }

    if (structure == FIVE_STRUCTURE_PAIRS_AND_DIRECT) {
      return FIVE_PLAN_PAIRS_AND_DIRECT;
    }

    if (structure == FIVE_STRUCTURE_LONG_CHAIN_AND_DIRECTS) {
      return FIVE_PLAN_LONG_CHAIN_AND_DIRECTS;
    }

    if (structure == FIVE_STRUCTURE_DEEP_CHAIN_AND_DIRECT) {
      return FIVE_PLAN_DEEP_CHAIN_AND_DIRECT;
    }

    if (structure == FIVE_STRUCTURE_NESTED_FORK_AND_DIRECT) {
      return FIVE_PLAN_NESTED_FORK_AND_DIRECT;
    }

    if (structure == FIVE_STRUCTURE_NESTED_FORK) {
      return FIVE_PLAN_NESTED_FORK;
    }

    if (structure == FIVE_STRUCTURE_SHARED_DIAMOND) {
      return FIVE_PLAN_SHARED_DIAMOND;
    }

    return 0;
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
    FiveGraphStructure structure = planFiveStructure(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    if (structure.valid) {
      long topology = publicTopology(structure.topology);
      if (0 < topology) {
        return orderedPlan(topology, structure);
      }
    }

    return invalidPlan();
  }
}
