//! Validates the active prefix of one bounded resolved-helper table.

module wheeler.compiler.resolved_helper_validity;

import wheeler.compiler.scalar_helper_call_resolution;

classical class ResolvedHelperValidity {
  private boolean activeResolutionValid(
    long position,
    long helperCount,
    ResolvedHelperBody resolved
  ) {
    if (position < helperCount) {
      return resolved.valid;
    }

    return true;
  }

  /// Checks every active helper resolution without consulting inactive sentinels.
  public boolean resolvedHelpersValid(
    long helperCount,
    ResolvedHelperBody first,
    ResolvedHelperBody second,
    ResolvedHelperBody third,
    ResolvedHelperBody fourth,
    ResolvedHelperBody fifth,
    ResolvedHelperBody sixth,
    ResolvedHelperBody seventh,
    ResolvedHelperBody eighth,
    ResolvedHelperBody ninth,
    ResolvedHelperBody tenth,
    ResolvedHelperBody eleventh,
    ResolvedHelperBody twelfth,
    ResolvedHelperBody thirteenth,
    ResolvedHelperBody fourteenth,
    ResolvedHelperBody fifteenth,
    ResolvedHelperBody sixteenth,
    ResolvedHelperBody seventeenth,
    ResolvedHelperBody eighteenth,
    ResolvedHelperBody nineteenth,
    ResolvedHelperBody twentieth,
    ResolvedHelperBody twentyFirst,
    ResolvedHelperBody twentySecond,
    ResolvedHelperBody twentyThird
  ) {
    if (activeResolutionValid(0, helperCount, first)) {} else {
      return false;
    }

    if (activeResolutionValid(1, helperCount, second)) {} else {
      return false;
    }

    if (activeResolutionValid(2, helperCount, third)) {} else {
      return false;
    }

    if (activeResolutionValid(3, helperCount, fourth)) {} else {
      return false;
    }

    if (activeResolutionValid(4, helperCount, fifth)) {} else {
      return false;
    }

    if (activeResolutionValid(5, helperCount, sixth)) {} else {
      return false;
    }

    if (activeResolutionValid(6, helperCount, seventh)) {} else {
      return false;
    }

    if (activeResolutionValid(7, helperCount, eighth)) {} else {
      return false;
    }

    if (activeResolutionValid(8, helperCount, ninth)) {} else {
      return false;
    }

    if (activeResolutionValid(9, helperCount, tenth)) {} else {
      return false;
    }

    if (activeResolutionValid(10, helperCount, eleventh)) {} else {
      return false;
    }

    if (activeResolutionValid(11, helperCount, twelfth)) {} else {
      return false;
    }

    if (activeResolutionValid(12, helperCount, thirteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(13, helperCount, fourteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(14, helperCount, fifteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(15, helperCount, sixteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(16, helperCount, seventeenth)) {} else {
      return false;
    }

    if (activeResolutionValid(17, helperCount, eighteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(18, helperCount, nineteenth)) {} else {
      return false;
    }

    if (activeResolutionValid(19, helperCount, twentieth)) {} else {
      return false;
    }

    if (activeResolutionValid(20, helperCount, twentyFirst)) {} else {
      return false;
    }

    if (activeResolutionValid(21, helperCount, twentySecond)) {} else {
      return false;
    }

    return activeResolutionValid(22, helperCount, twentyThird);
  }
}
