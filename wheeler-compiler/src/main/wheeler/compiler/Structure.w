//! Computes canonical section offsets for bootstrap artifacts.

module wheeler.compiler.structure;

import wheeler.compiler.tokens;

classical class Structure {
  private boolean canonicalMinimalNames(
    borrow mut words tokenKinds,
    borrow mut words tokenLengths
  ) {
    if (tokenKinds[2] == 1) {
      if (tokenLengths[2] < 257) {
        if (tokenKinds[6] == 1) {
          return tokenLengths[6] < 257;
        }
      }
    }

    return false;
  }

  /// Returns the first source offset of the bounded entry declaration.
  public long minimalEntryStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 0) == 87497064671293) {
      if (tokenHash(source, tokenStarts, tokenLengths, 1) == 94742904) {
        if (canonicalMinimalNames(tokenKinds, tokenLengths)) {
          if (punctuationAt(source, tokenKinds, tokenStarts, 3, 123)) {
            if (tokenHash(source, tokenStarts, tokenLengths, 4) == 109757585) {
              if (tokenHash(source, tokenStarts, tokenLengths, 5) == 3327612) {
                if (punctuationAt(source, tokenKinds, tokenStarts, 7, 61)) {
                  long width = signedNumberWidth(source, tokenKinds, tokenStarts, 8);
                  if (0 < width) {
                    if (signedNumberValid(source, tokenStarts, tokenLengths, 8)) {
                      long semicolon = 8 + width;
                      if (
                        punctuationAt(source, tokenKinds, tokenStarts, semicolon, 59)
                      ) {
                        return semicolon + 1;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return -1;
  }

  /// Returns the first source offset inside the bounded entry body.
  public long minimalBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long entryStart
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, entryStart) == 96667762) {
      if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 1) == 3625364) {
        if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 2) == 3343801) {
          if (punctuationAt(source, tokenKinds, tokenStarts, entryStart + 3, 40)) {
            if (punctuationAt(source, tokenKinds, tokenStarts, entryStart + 4, 41)) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, entryStart + 5, 123)
              ) {
                return entryStart + 6;
              }
            }
          }
        }
      }
    }

    return -1;
  }
}
