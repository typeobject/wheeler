//! Owns the closed six-module structure and graph-plan identities.

module wheeler.compiler.graphs.six_graph_kinds;

classical class SixGraphKinds {
  /// Names the six-module direct-star structure.
  public const long SIX_STRUCTURE_DIRECT = 1;
  /// Names the six-module full-chain structure.
  public const long SIX_STRUCTURE_CHAIN = 2;
  /// Names the six-module five-leaf-fork structure.
  public const long SIX_STRUCTURE_FORK = 3;
  /// Names one chain edge beside four direct root imports.
  public const long SIX_STRUCTURE_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside three direct root imports.
  public const long SIX_STRUCTURE_FORK_AND_DIRECTS = 5;
  /// Names two independent chains beside two direct root imports.
  public const long SIX_STRUCTURE_PAIRS_AND_DIRECTS = 6;
  /// Names one three-module chain beside three direct root imports.
  public const long SIX_STRUCTURE_LONG_CHAIN_AND_DIRECTS = 7;
  /// Names one four-module chain beside two direct root imports.
  public const long SIX_STRUCTURE_DEEP_CHAIN_AND_DIRECTS = 8;
  /// Names one three-leaf fork beside two direct root imports.
  public const long SIX_STRUCTURE_THREE_LEAF_FORK_AND_DIRECTS = 9;
  /// Names one nested two-leaf fork beside two direct root imports.
  public const long SIX_STRUCTURE_NESTED_FORK_AND_DIRECTS = 10;
  /// Names one uneven two-branch tree beside two direct root imports.
  public const long SIX_STRUCTURE_UNEVEN_TREE_AND_DIRECTS = 11;
  /// Names one fork beside one chain and one direct root import.
  public const long SIX_STRUCTURE_FORK_CHAIN_AND_DIRECT = 12;
  /// Names three independent chains imported directly by the root.
  public const long SIX_STRUCTURE_THREE_CHAINS = 13;
  /// Names one long chain beside one short chain and one direct root import.
  public const long SIX_STRUCTURE_LONG_AND_SHORT_CHAINS = 14;

  /// Names the six-module direct-star plan.
  public const long SIX_PLAN_DIRECT = 1;
  /// Names the six-module full-chain plan.
  public const long SIX_PLAN_CHAIN = 2;
  /// Names the six-module five-leaf-fork plan.
  public const long SIX_PLAN_FORK = 3;
  /// Names one chain edge beside four direct root imports.
  public const long SIX_PLAN_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside three direct root imports.
  public const long SIX_PLAN_FORK_AND_DIRECTS = 5;
  /// Names two independent chains beside two direct root imports.
  public const long SIX_PLAN_PAIRS_AND_DIRECTS = 6;
  /// Names one three-module chain beside three direct root imports.
  public const long SIX_PLAN_LONG_CHAIN_AND_DIRECTS = 7;
  /// Names one four-module chain beside two direct root imports.
  public const long SIX_PLAN_DEEP_CHAIN_AND_DIRECTS = 8;
  /// Names one three-leaf fork beside two direct root imports.
  public const long SIX_PLAN_THREE_LEAF_FORK_AND_DIRECTS = 9;
  /// Names one nested two-leaf fork beside two direct root imports.
  public const long SIX_PLAN_NESTED_FORK_AND_DIRECTS = 10;
  /// Names one uneven two-branch tree beside two direct root imports.
  public const long SIX_PLAN_UNEVEN_TREE_AND_DIRECTS = 11;
  /// Names one fork beside one chain and one direct root import.
  public const long SIX_PLAN_FORK_CHAIN_AND_DIRECT = 12;
  /// Names three independent chains imported directly by the root.
  public const long SIX_PLAN_THREE_CHAINS = 13;
  /// Names one long chain beside one short chain and one direct root import.
  public const long SIX_PLAN_LONG_AND_SHORT_CHAINS = 14;
  /// Bounds the contiguous root-branch plan range without naming another plan.
  public const long SIX_ROOT_BRANCH_PLAN_LIMIT = 15;
}
