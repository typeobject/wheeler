//! Resolves one helper's calls against a complete bounded table.

module wheeler.compiler.scalar_helper_call_resolution;

import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_tables;

classical class ScalarHelperCallResolution {
  /// Carries one helper after bounded call resolution.
  public record ResolvedHelperBody(HelperBody body, boolean valid) {}

  /// Resolves one helper against a complete bounded table.
  public ResolvedHelperBody resolvedHelperBody(
    borrow utf8 source,
    HelperBody body,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
    HelperBody twentyThird,
    long helperCount
  ) {
    ResolvedCalls calls = resolveCalls(
      source,
      body,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      eighth,
      ninth,
      tenth,
      eleventh,
      twelfth,
      thirteenth,
      fourteenth,
      fifteenth,
      sixteenth,
      seventeenth,
      eighteenth,
      nineteenth,
      twentieth,
      twentyFirst,
      twentySecond,
      twentyThird,
      helperCount
    );
    return new ResolvedHelperBody(withCalls(body, calls), calls.valid);
  }

}
