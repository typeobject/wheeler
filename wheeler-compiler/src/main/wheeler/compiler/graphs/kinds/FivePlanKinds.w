//! Owns the closed five-module graph-plan identities.

module wheeler.compiler.graphs.five_plan_kinds;

classical class FivePlanKinds {
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
}
