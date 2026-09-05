//! Owns bounded compiler token-table and name-processing limits.

module wheeler.compiler.compiler_token_limits;

classical class CompilerTokenLimits {
  /// Caps compiler token metadata before comment compaction.
  public const long MAX_COMPILER_TOKENS = 4096;
  /// Reserves the unused final token cell for the resolved global name.
  public const long COMPILER_GLOBAL_NAME_TOKEN = MAX_COMPILER_TOKENS - 1;
  /// Distinguishes Boolean parameter markers from signed parameter markers.
  public const long BOOLEAN_PARAMETER_TOKEN_BIAS = MAX_COMPILER_TOKENS;
  /// Caps direct imports in one bounded compiler source.
  public const long MAX_MODULE_IMPORTS = 64;
  /// Caps tokens consumed by one module or import name.
  public const long MAX_QUALIFIED_NAME_TOKENS = 64;
  /// Caps UTF-8 bytes compared in one module or import name.
  public const long MAX_QUALIFIED_NAME_BYTES = 256;
}
