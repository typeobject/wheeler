//! Classifies bounded five-module constant graphs before linking.

module wheeler.compiler.graphs.plans;

import wheeler.compiler.graphs.five_structures;

classical class CompilerGraphPlans {
  /// Names the five-module direct-star plan.
  public const long FIVE_PLAN_DIRECT = 1;
  /// Names the five-module full-chain plan.
  public const long FIVE_PLAN_CHAIN = 2;
  /// Names the five-module four-leaf-fork plan.
  public const long FIVE_PLAN_FORK = 3;
  /// Names a three-leaf fork beside one direct import.
  public const long FIVE_PLAN_FORK_AND_DIRECT = 4;
  /// Names one chain edge beside three direct imports.
  public const long FIVE_PLAN_CHAIN_AND_DIRECTS = 5;
  /// Names a two-leaf fork beside two direct imports.
  public const long FIVE_PLAN_FORK_AND_TWO_DIRECTS = 6;
  /// Names two independent edges beside one direct import.
  public const long FIVE_PLAN_PAIRS_AND_DIRECT = 7;
  /// Names a three-module chain beside two direct imports.
  public const long FIVE_PLAN_LONG_CHAIN_AND_DIRECTS = 8;
  /// Names a four-module chain beside one direct import.
  public const long FIVE_PLAN_DEEP_CHAIN_AND_DIRECT = 9;
  /// Names a nested fork beside one direct import.
  public const long FIVE_PLAN_NESTED_FORK_AND_DIRECT = 10;
  /// Names two nested fork levels.
  public const long FIVE_PLAN_NESTED_FORK = 11;
  /// Names a shared diamond with one side leaf.
  public const long FIVE_PLAN_SHARED_DIAMOND = 12;

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
