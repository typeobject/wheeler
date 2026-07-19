//! Parses bounded canonical-YAML package manifests.

module wheeler.packages.manifest;

import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class Manifest {
  /// Defines one quoted source range without copying its bytes.
  public record QuotedRange(long start, long length) {}

  /// Carries the bounded manifest fields used by the recovery examples.
  public record ManifestHeader(
    QuotedRange name,
    QuotedRange version,
    QuotedRange profile,
    QuotedRange targetName,
    QuotedRange targetRoot,
    QuotedRange targetModule,
    QuotedRange targetSource,
    QuotedRange targetSecondSource,
    QuotedRange targetThirdSource,
    QuotedRange targetFourthSource,
    long targetSourceCount,
    long targetTest,
    QuotedRange secondTargetName,
    QuotedRange secondTargetRoot,
    long secondTargetTest,
    long targetCount,
    QuotedRange dependencyName,
    QuotedRange dependencyVersion,
    QuotedRange secondDependencyName,
    QuotedRange secondDependencyVersion,
    long dependencyCount,
    QuotedRange capabilityName,
    QuotedRange capabilityPath,
    QuotedRange secondCapabilityName,
    QuotedRange secondCapabilityPath,
    long capabilityCount
  ) {}

  /// Defines the closed parse result; malformed YAML never returns a partial model.
  public variant ManifestResult {
    case Value(ManifestHeader header);
    case Error(long offset);
  }

  private record TargetParse(
    boolean valid,
    long next,
    QuotedRange name,
    QuotedRange root,
    QuotedRange module,
    QuotedRange firstSource,
    QuotedRange secondSource,
    QuotedRange thirdSource,
    QuotedRange fourthSource,
    long sourceCount,
    long test
  ) {}

  private record DependencyParse(
    boolean valid,
    long next,
    QuotedRange name,
    QuotedRange version
  ) {}

  private record CapabilityParse(boolean valid, long next, QuotedRange name, QuotedRange path) {}

  private boolean negated(boolean value) {
    if (value) {
      return false;
    }

    return true;
  }

  private QuotedRange emptyRange() {
    return new QuotedRange(0, 0);
  }

  private QuotedRange range(borrow mut words starts, borrow mut words lengths, long token) {
    return new QuotedRange(starts[token] + 1, lengths[token] - 2);
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

  private long booleanToken(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long hash = tokenHash(source, starts, lengths, token);
    if (hash == 3569038) {
      return 1;
    }

    if (hash == 97196323) {
      return 0;
    }

    return -1;
  }

  private boolean targetKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      long hash = quotedHash(source, starts, lengths, token);
      if (hash == 2733284766595777) {
        return true;
      }

      if (hash == 98950456507) {
        return true;
      }

      return hash == 3565976;
    }

    return false;
  }

  private boolean dependencyKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      long hash = quotedHash(source, starts, lengths, token);
      if (hash == 3255221479) {
        return true;
      }

      if (hash == 84736749587766587) {
        return true;
      }

      return hash == 94094958;
    }

    return false;
  }

  private TargetParse parseTarget(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    QuotedRange empty = emptyRange();
    TargetParse invalid = new TargetParse(
      false,
      cursor,
      empty,
      empty,
      empty,
      empty,
      empty,
      empty,
      empty,
      0,
      0
    );
    if (cursor + 12 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3292052)) {
          if (targetKind(source, kinds, starts, lengths, cursor + 3)) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3373707)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                if (
                  key(source, kinds, starts, lengths, count, cursor + 7, 3506402)
                ) {
                  if (quoted(kinds, lengths, cursor + 9)) {
                    boolean validRoot = validLogicalPath(
                      source,
                      starts[cursor + 9] + 1,
                      lengths[cursor + 9] - 2
                    );
                    if (validRoot) {
                      QuotedRange name = range(starts, lengths, cursor + 6);
                      QuotedRange root = range(starts, lengths, cursor + 9);
                      QuotedRange module = empty;
                      QuotedRange first = empty;
                      QuotedRange second = empty;
                      QuotedRange third = empty;
                      QuotedRange fourth = empty;
                      long sourceCount = 0;
                      long next = cursor + 10;
                      if (
                        key(source, kinds, starts, lengths, count, next, 3226183276)
                      ) {
                        if (quoted(kinds, lengths, next + 2)) {
                          boolean validModule = validModuleName(
                            source,
                            starts[next + 2] + 1,
                            lengths[next + 2] - 2
                          );
                          if (validModule) {
                            module = range(starts, lengths, next + 2);

                            next += 3;
                            if (
                              key(source, kinds, starts, lengths, count, next, 105352305592)
                            ) {
                              next += 2;
                              boolean scanning = true;
                              while (scanning) limit 4 {
                                if (next + 1 < count) {
                                  if (dashAt(source, kinds, starts, next)) {
                                    if (quoted(kinds, lengths, next + 1)) {
                                      boolean validSource = validLogicalPath(
                                        source,
                                        starts[next + 1] + 1,
                                        lengths[next + 1] - 2
                                      );
                                      if (validSource) {
                                        if (sourceCount == 0) {
                                          first = range(starts, lengths, next + 1);
                                        }

                                        if (sourceCount == 1) {
                                          second = range(starts, lengths, next + 1);
                                        }

                                        if (sourceCount == 2) {
                                          third = range(starts, lengths, next + 1);
                                        }

                                        if (sourceCount == 3) {
                                          fourth = range(starts, lengths, next + 1);
                                        }

                                        sourceCount += 1;
                                        next += 2;
                                      } else {
                                        return invalid;
                                      }
                                    } else {
                                      scanning = false;
                                    }
                                  } else {
                                    scanning = false;
                                  }
                                } else {
                                  scanning = false;
                                }
                              }

                              if (sourceCount == 0) {
                                return invalid;
                              }
                            } else {
                              return invalid;
                            }
                          } else {
                            return invalid;
                          }
                        } else {
                          return invalid;
                        }
                      }

                      if (
                        key(source, kinds, starts, lengths, count, next, 3556498)
                      ) {
                        long test = booleanToken(source, starts, lengths, next + 2);
                        if (-1 < test) {
                          return new TargetParse(
                            true,
                            next + 3,
                            name,
                            root,
                            module,
                            first,
                            second,
                            third,
                            fourth,
                            sourceCount,
                            test
                          );
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

    return invalid;
  }

  private DependencyParse parseDependency(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    QuotedRange empty = emptyRange();
    DependencyParse invalid = new DependencyParse(false, cursor, empty, empty);
    if (cursor + 9 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3292052)) {
          if (dependencyKind(source, kinds, starts, lengths, cursor + 3)) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3373707)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validName = validPackageName(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validName) {
                  if (
                    key(source, kinds, starts, lengths, count, cursor + 7, 107725790424)
                  ) {
                    if (quoted(kinds, lengths, cursor + 9)) {
                      boolean validVersion = validConstraint(
                        source,
                        starts[cursor + 9] + 1,
                        lengths[cursor + 9] - 2
                      );
                      if (validVersion) {
                        return new DependencyParse(
                          true,
                          cursor + 10,
                          range(starts, lengths, cursor + 6),
                          range(starts, lengths, cursor + 9)
                        );
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

    return invalid;
  }

  private CapabilityParse parseCapability(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    QuotedRange empty = emptyRange();
    CapabilityParse invalid = new CapabilityParse(false, cursor, empty, empty);
    if (cursor + 6 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3373707)) {
          if (quoted(kinds, lengths, cursor + 3)) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3433509)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validPath = validLogicalPath(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validPath) {
                  return new CapabilityParse(
                    true,
                    cursor + 7,
                    range(starts, lengths, cursor + 3),
                    range(starts, lengths, cursor + 6)
                  );
                }
              }
            }
          }
        }
      }
    }

    return invalid;
  }

  /// Parses one canonical YAML manifest with at most two records per trailing section.
  public ManifestResult parseHeader(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    QuotedRange empty = emptyRange();
    if (count < 35) {
      return new ManifestResult.Error(0);
    }

    if (negated(key(source, kinds, starts, lengths, count, 0, 3386979745))) {
      return new ManifestResult.Error(starts[0]);
    }

    long schema = tokenHash(source, starts, lengths, 2);
    if (schema < 49) {
      return new ManifestResult.Error(starts[2]);
    }

    if (49 < schema) {
      return new ManifestResult.Error(starts[2]);
    }

    if (negated(key(source, kinds, starts, lengths, count, 3, 102272152646))) {
      return new ManifestResult.Error(starts[3]);
    }

    if (negated(key(source, kinds, starts, lengths, count, 5, 3373707))) {
      return new ManifestResult.Error(starts[5]);
    }

    if (negated(quoted(kinds, lengths, 7))) {
      return new ManifestResult.Error(starts[7]);
    }

    if (negated(validPackageName(source, starts[7] + 1, lengths[7] - 2))) {
      return new ManifestResult.Error(starts[7]);
    }

    if (negated(key(source, kinds, starts, lengths, count, 8, 107725790424))) {
      return new ManifestResult.Error(starts[8]);
    }

    if (negated(quoted(kinds, lengths, 10))) {
      return new ManifestResult.Error(starts[10]);
    }

    if (negated(validRelease(source, starts[10] + 1, lengths[10] - 2))) {
      return new ManifestResult.Error(starts[10]);
    }

    if (negated(key(source, kinds, starts, lengths, count, 11, 102769789353))) {
      return new ManifestResult.Error(starts[11]);
    }

    if (negated(quoted(kinds, lengths, 13))) {
      return new ManifestResult.Error(starts[13]);
    }

    if (negated(key(source, kinds, starts, lengths, count, 14, 105835905282))) {
      return new ManifestResult.Error(starts[14]);
    }

    long cursor = 16;
    TargetParse firstTarget = parseTarget(source, kinds, starts, lengths, count, cursor);
    if (negated(firstTarget.valid)) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor = firstTarget.next;
    TargetParse secondTarget = new TargetParse(
      false,
      cursor,
      empty,
      empty,
      empty,
      empty,
      empty,
      empty,
      empty,
      0,
      0
    );
    long targetCount = 1;
    if (cursor < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        secondTarget = parseTarget(source, kinds, starts, lengths, count, cursor);
        if (negated(secondTarget.valid)) {
          return new ManifestResult.Error(starts[cursor]);
        }

        cursor = secondTarget.next;
        targetCount = 2;
      }
    }

    if (
      negated(key(source, kinds, starts, lengths, count, cursor, 2626680644436426025))
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    DependencyParse firstDependency = parseDependency(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (negated(firstDependency.valid)) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor = firstDependency.next;
    DependencyParse secondDependency = new DependencyParse(false, cursor, empty, empty);
    long dependencyCount = 1;
    if (cursor < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        secondDependency = parseDependency(source, kinds, starts, lengths, count, cursor);
        if (negated(secondDependency.valid)) {
          return new ManifestResult.Error(starts[cursor]);
        }

        cursor = secondDependency.next;
        dependencyCount = 2;
      }
    }

    if (
      negated(key(source, kinds, starts, lengths, count, cursor, 2597989917310390198))
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    CapabilityParse firstCapability = parseCapability(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (negated(firstCapability.valid)) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor = firstCapability.next;
    CapabilityParse secondCapability = new CapabilityParse(false, cursor, empty, empty);
    long capabilityCount = 1;
    if (cursor < count) {
      secondCapability = parseCapability(source, kinds, starts, lengths, count, cursor);
      if (secondCapability.valid) {
        cursor = secondCapability.next;
        capabilityCount = 2;
      }
    }

    if (cursor < count) {
      return new ManifestResult.Error(starts[cursor]);
    }

    ManifestHeader header = new ManifestHeader(
      range(starts, lengths, 7),
      range(starts, lengths, 10),
      range(starts, lengths, 13),
      firstTarget.name,
      firstTarget.root,
      firstTarget.module,
      firstTarget.firstSource,
      firstTarget.secondSource,
      firstTarget.thirdSource,
      firstTarget.fourthSource,
      firstTarget.sourceCount,
      firstTarget.test,
      secondTarget.name,
      secondTarget.root,
      secondTarget.test,
      targetCount,
      firstDependency.name,
      firstDependency.version,
      secondDependency.name,
      secondDependency.version,
      dependencyCount,
      firstCapability.name,
      firstCapability.path,
      secondCapability.name,
      secondCapability.path,
      capabilityCount
    );
    return new ManifestResult.Value(header);
  }
}
