//! Parses bounded canonical-YAML workspace manifests.

module wheeler.packages.workspace;

import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.tokens;

classical class Workspace {
  /// Carries scalar ranges and counts for one validated workspace.
  public record WorkspaceModel(
    long nameStart,
    long nameLength,
    long profileStart,
    long profileLength,
    long memberCount
  ) {}

  /// Defines the closed workspace parse result.
  public variant WorkspaceResult {
    case Value(WorkspaceModel workspace);
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

  private boolean memberValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    if (cursor + 6 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3373707)) {
          if (quoted(kinds, lengths, cursor + 3)) {
            boolean validName = validWorkspaceName(
              source,
              starts[cursor + 3] + 1,
              lengths[cursor + 3] - 2
            );
            if (validName) {
              if (key(source, kinds, starts, lengths, count, cursor + 4, 3433509)) {
                if (quoted(kinds, lengths, cursor + 6)) {
                  return validWorkspacePath(
                    source,
                    starts[cursor + 6] + 1,
                    lengths[cursor + 6] - 2
                  );
                }
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean sameRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength == rightLength) {
      long offset = 0;
      while (offset < leftLength) limit 4096 {
        if (
          utf8Scalar(source, leftStart + offset) == utf8Scalar(source, rightStart + offset)
        ) {
          offset += 1;
        } else {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  private boolean nestedRange(
    borrow utf8 source,
    long parentStart,
    long parentLength,
    long childStart,
    long childLength
  ) {
    if (parentLength < childLength) {
      long offset = 0;
      while (offset < parentLength) limit 4096 {
        if (
          utf8Scalar(source, parentStart + offset) == utf8Scalar(source, childStart + offset)
        ) {
          offset += 1;
        } else {
          return false;
        }
      }

      return utf8Scalar(source, childStart + parentLength) == 47;
    }

    return false;
  }

  private boolean capacity(
    borrow mut words memberNameStarts,
    borrow mut words memberNameLengths,
    borrow mut words memberPathStarts,
    borrow mut words memberPathLengths,
    long member
  ) {
    if (member < bufferLength(memberNameStarts)) {
      if (member < bufferLength(memberNameLengths)) {
        if (member < bufferLength(memberPathStarts)) {
          return member < bufferLength(memberPathLengths);
        }
      }
    }

    return false;
  }

  private boolean validHeader(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (count < 20) {
      return false;
    }

    boolean valid = key(source, kinds, starts, lengths, count, 0, 3386979745);
    if (valid) {
      valid = tokenHash(source, starts, lengths, 2) == 49;
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 3, 104652281998485);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 5, 3373707);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 7);
    }

    if (valid) {
      valid = validWorkspaceName(source, starts[7] + 1, lengths[7] - 2);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 8, 102769789353);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 10);
    }

    if (valid) {
      valid = validWorkspaceName(source, starts[10] + 1, lengths[10] - 2);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 11, 99733129497);
    }

    return valid;
  }

  /// Parses every canonical member that fits the caller-provided bounded tables.
  public WorkspaceResult parseWorkspace(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut words memberNameStarts,
    borrow mut words memberNameLengths,
    borrow mut words memberPathStarts,
    borrow mut words memberPathLengths
  ) {
    if (validHeader(source, kinds, starts, lengths, count) == false) {
      return new WorkspaceResult.Error(0);
    }

    long cursor = 13;
    long memberCount = 0;
    long previousNameToken = -1;
    while (cursor < count) limit 512 {
      if (memberValid(source, kinds, starts, lengths, count, cursor) == false) {
        return new WorkspaceResult.Error(starts[cursor]);
      }

      if (
        capacity(
          memberNameStarts,
          memberNameLengths,
          memberPathStarts,
          memberPathLengths,
          memberCount
        ) == false
      ) {
        return new WorkspaceResult.Error(starts[cursor]);
      }

      if (-1 < previousNameToken) {
        long order = compareTokenText(source, starts, lengths, previousNameToken, cursor + 3);
        boolean ordered = order < 0;
        if (ordered == false) {
          return new WorkspaceResult.Error(starts[cursor + 3]);
        }
      }

      long pathStart = starts[cursor + 6] + 1;
      long pathLength = lengths[cursor + 6] - 2;
      long prior = 0;
      while (prior < memberCount) limit 512 {
        boolean same = sameRange(
          source,
          memberPathStarts[prior],
          memberPathLengths[prior],
          pathStart,
          pathLength
        );
        boolean priorContains = nestedRange(
          source,
          memberPathStarts[prior],
          memberPathLengths[prior],
          pathStart,
          pathLength
        );
        boolean currentContains = nestedRange(
          source,
          pathStart,
          pathLength,
          memberPathStarts[prior],
          memberPathLengths[prior]
        );
        if (same) {
          return new WorkspaceResult.Error(starts[cursor + 6]);
        }

        if (priorContains) {
          return new WorkspaceResult.Error(starts[cursor + 6]);
        }

        if (currentContains) {
          return new WorkspaceResult.Error(starts[cursor + 6]);
        }

        prior += 1;
      }

      set(memberNameStarts, memberCount, starts[cursor + 3] + 1);
      set(memberNameLengths, memberCount, lengths[cursor + 3] - 2);
      set(memberPathStarts, memberCount, pathStart);
      set(memberPathLengths, memberCount, pathLength);
      memberCount += 1;
      previousNameToken = cursor + 3;
      cursor += 7;
    }

    if (memberCount == 0) {
      return new WorkspaceResult.Error(0);
    }

    WorkspaceModel workspace = new WorkspaceModel(
      starts[7] + 1,
      lengths[7] - 2,
      starts[10] + 1,
      lengths[10] - 2,
      memberCount
    );
    return new WorkspaceResult.Value(workspace);
  }
}
