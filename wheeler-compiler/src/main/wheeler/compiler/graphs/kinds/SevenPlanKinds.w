//! Owns the closed seven-module graph-plan identities.

module wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenPlanKinds {
  /// Names the seven-module direct-star plan.
  public const long SEVEN_PLAN_DIRECT = 1;
  /// Names the seven-module full-chain plan.
  public const long SEVEN_PLAN_CHAIN = 2;
  /// Names the seven-module six-leaf-fork plan.
  public const long SEVEN_PLAN_FORK = 3;
  /// Names one chain edge beside five direct root imports.
  public const long SEVEN_PLAN_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside four direct root imports.
  public const long SEVEN_PLAN_FORK_AND_DIRECTS = 5;
  /// Names two independent chains beside three direct root imports.
  public const long SEVEN_PLAN_PAIRS_AND_DIRECTS = 6;
  /// Names three independent chains beside one direct root import.
  public const long SEVEN_PLAN_THREE_CHAINS_AND_DIRECT = 7;
  /// Names one three-module chain beside four direct root imports.
  public const long SEVEN_PLAN_LONG_CHAIN_AND_DIRECTS = 8;
}
