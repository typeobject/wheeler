//! Owns bounded source-program statement and resolution-table capacities.

module wheeler.compiler.compiler_program_limits;

classical class CompilerProgramLimits {
  /// Caps source statements in one bounded entry or helper body.
  public const long MAX_MINIMAL_STATEMENTS = 64;
  /// Holds two parameter names before a full helper statement table.
  public const long MAX_HELPER_RESOLUTION_STARTS = MAX_MINIMAL_STATEMENTS + 2;
  /// Holds disjoint helper and entry statement-resolution tables.
  public const long MAX_PROGRAM_RESOLUTION_STARTS = MAX_HELPER_RESOLUTION_STARTS
    + MAX_MINIMAL_STATEMENTS;
}
