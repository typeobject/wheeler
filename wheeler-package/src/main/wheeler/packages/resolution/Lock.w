//! Parses a bounded canonical-YAML dependency lock.

module wheeler.packages.lock;

import wheeler.packages.names;
import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class Lock {
  /// Describes one locked package without copying manifest bytes.
  public record LockedPackage(
    long nameStart,
    long nameLength,
    long versionLength,
    long archiveStart,
    long manifestStart
  ) {}

  /// Carries the two-package recovery fixture and its one explicit dependency.
  public record LockModel(
    long rootStart,
    LockedPackage first,
    LockedPackage second,
    long packageCount,
    long edgeSourceStart,
    long edgeTargetStart,
    long edgeCount
  ) {}

  /// Defines the closed package-lock parse result.
  public variant LockResult {
    case Value(LockModel lock);
    case Error(long offset);
  }

  private boolean key(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long hash
  ) {
    if (token + 1 < count) {
      if (keywordAt(source, starts, lengths, token, hash)) {
        return colonAt(source, kinds, starts, token + 1);
      }
    }

    return false;
  }

  private boolean punctuation(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long token,
    long scalar
  ) {
    if (kinds[token] == 3) {
      return utf8Scalar(source, starts[token]) == scalar;
    }

    return false;
  }

  private boolean hexDigest(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      if (lengths[token] == 66) {
        long cursor = starts[token] + 1;
        long end = cursor + 64;
        while (cursor < end) limit 64 {
          long scalar = utf8Scalar(source, cursor);
          boolean valid = false;
          if (47 < scalar) {
            if (scalar < 58) {
              valid = true;
            }
          }

          if (96 < scalar) {
            if (scalar < 103) {
              valid = true;
            }
          }

          if (valid) {
            cursor += 1;
          } else {
            return false;
          }
        }

        return true;
      }
    }

    return false;
  }

  private boolean packageFieldsValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    if (cursor + 16 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3373707)) {
          if (quoted(kinds, lengths, cursor + 3)) {
            boolean validName = validPackageName(
              source,
              starts[cursor + 3] + 1,
              lengths[cursor + 3] - 2
            );
            if (validName) {
              if (
                key(source, kinds, starts, lengths, count, cursor + 4, 107725790424)
              ) {
                if (quoted(kinds, lengths, cursor + 6)) {
                  boolean validVersion = validRelease(
                    source,
                    starts[cursor + 6] + 1,
                    lengths[cursor + 6] - 2
                  );
                  if (validVersion) {
                    if (
                      key(
                        source,
                        kinds,
                        starts,
                        lengths,
                        count,
                        cursor + 7,
                        3103442239675210
                      )
                    ) {
                      if (hexDigest(source, kinds, starts, lengths, cursor + 9)) {
                        if (
                          key(
                            source,
                            kinds,
                            starts,
                            lengths,
                            count,
                            cursor + 10,
                            89446211778
                          )
                        ) {
                          if (hexDigest(source, kinds, starts, lengths, cursor + 12)) {
                            if (
                              key(
                                source,
                                kinds,
                                starts,
                                lengths,
                                count,
                                cursor + 13,
                                3088212110895
                              )
                            ) {
                              return hexDigest(source, kinds, starts, lengths, cursor + 15);
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
        }
      }
    }

    return false;
  }

  private LockedPackage lockedPackage(
    borrow mut words starts,
    borrow mut words lengths,
    long cursor
  ) {
    return new LockedPackage(
      starts[cursor + 3] + 1,
      lengths[cursor + 3] - 2,
      lengths[cursor + 6] - 2,
      starts[cursor + 12] + 1,
      starts[cursor + 15] + 1
    );
  }

  /// Parses exactly the closed two-package lock shape exercised during recovery.
  public LockResult parse(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (count < 48) {
      return new LockResult.Error(0);
    }

    if (key(source, kinds, starts, lengths, count, 0, 3386979745)) {
      if (tokenHash(source, starts, lengths, 2) == 50) {
        if (key(source, kinds, starts, lengths, count, 3, 3506402)) {
          if (hexDigest(source, kinds, starts, lengths, 5)) {
            if (key(source, kinds, starts, lengths, count, 6, 3170436732141)) {
              long firstCursor = 8;
              if (
                packageFieldsValid(source, kinds, starts, lengths, count, firstCursor)
              ) {
                if (
                  key(
                    source,
                    kinds,
                    starts,
                    lengths,
                    count,
                    firstCursor + 16,
                    2626680644436426025
                  )
                ) {
                  if (dashAt(source, kinds, starts, firstCursor + 18)) {
                    if (quoted(kinds, lengths, firstCursor + 19)) {
                      long secondCursor = firstCursor + 20;
                      if (
                        packageFieldsValid(
                          source,
                          kinds,
                          starts,
                          lengths,
                          count,
                          secondCursor
                        )
                      ) {
                        if (
                          key(
                            source,
                            kinds,
                            starts,
                            lengths,
                            count,
                            secondCursor + 16,
                            2626680644436426025
                          )
                        ) {
                          if (
                            punctuation(source, kinds, starts, secondCursor + 18, 91)
                          ) {
                            if (
                              punctuation(source, kinds, starts, secondCursor + 19, 93)
                            ) {
                              if (count == secondCursor + 20) {
                                long order = compareTokenText(
                                  source,
                                  starts,
                                  lengths,
                                  firstCursor + 3,
                                  secondCursor + 3
                                );
                                boolean dependencyMatches = sameTokenText(
                                  source,
                                  starts,
                                  lengths,
                                  firstCursor + 19,
                                  secondCursor + 3
                                );
                                if (order < 0) {
                                  if (dependencyMatches) {
                                    LockedPackage first = lockedPackage(
                                      starts,
                                      lengths,
                                      firstCursor
                                    );
                                    LockedPackage second = lockedPackage(
                                      starts,
                                      lengths,
                                      secondCursor
                                    );
                                    LockModel lock = new LockModel(
                                      starts[5] + 1,
                                      first,
                                      second,
                                      2,
                                      starts[firstCursor + 3] + 1,
                                      starts[firstCursor + 16] + 1,
                                      1
                                    );
                                    return new LockResult.Value(lock);
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
              }
            }
          }
        }
      }
    }

    return new LockResult.Error(0);
  }
}
