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
  /// Names one four-leaf fork beside two direct root imports.
  public const long SEVEN_PLAN_WIDE_FORK_AND_DIRECTS = 9;
  /// Names one five-leaf fork beside one direct root import.
  public const long SEVEN_PLAN_FIVE_LEAF_FORK_AND_DIRECT = 10;
  /// Names one three-leaf fork beside three direct root imports.
  public const long SEVEN_PLAN_THREE_LEAF_FORK_AND_DIRECTS = 11;
  /// Names one nested two-leaf fork beside three direct root imports.
  public const long SEVEN_PLAN_NESTED_FORK_AND_DIRECTS = 12;
  /// Names one four-module chain beside three direct root imports.
  public const long SEVEN_PLAN_FOUR_CHAIN_AND_DIRECTS = 13;
  /// Names one three-module chain and one two-module chain beside two direct imports.
  public const long SEVEN_PLAN_LONG_SHORT_CHAINS_AND_DIRECTS = 14;
  /// Names one two-leaf fork and one two-module chain beside two direct imports.
  public const long SEVEN_PLAN_FORK_CHAIN_AND_DIRECTS = 15;
  /// Names two three-module chains beside one direct root import.
  public const long SEVEN_PLAN_TWO_LONG_CHAINS_AND_DIRECT = 16;
  /// Names one five-module chain beside two direct root imports.
  public const long SEVEN_PLAN_FIVE_CHAIN_AND_DIRECTS = 17;
  /// Names one six-module chain beside one direct root import.
  public const long SEVEN_PLAN_SIX_CHAIN_AND_DIRECT = 18;
  /// Names one nested three-leaf fork beside two direct root imports.
  public const long SEVEN_PLAN_NESTED_THREE_FORK_AND_DIRECTS = 19;
  /// Names one deep nested two-leaf fork beside two direct root imports.
  public const long SEVEN_PLAN_DEEP_NESTED_FORK_AND_DIRECTS = 20;
  /// Names one uneven nested fork beside two direct root imports.
  public const long SEVEN_PLAN_UNEVEN_NESTED_FORK_AND_DIRECTS = 21;
}
