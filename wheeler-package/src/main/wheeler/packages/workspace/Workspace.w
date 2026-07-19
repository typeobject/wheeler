//! Parses bounded canonical-YAML workspace manifests.

module wheeler.packages.workspace;

import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.tokens;

classical class Workspace {
  /// Carries the bounded two-member recovery workspace.
  public record WorkspaceModel(
    long nameStart,
    long nameLength,
    long profileLength,
    long firstMemberNameLength,
    long firstMemberPathLength,
    long secondMemberNameLength,
    long secondMemberPathLength,
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

  private boolean nestedPath(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long parent,
    long child
  ) {
    long parentLength = lengths[parent] - 2;
    long childLength = lengths[child] - 2;
    if (parentLength < childLength) {
      long offset = 0;
      while (offset < parentLength) limit 256 {
        if (
          utf8Scalar(source, starts[parent] + 1 + offset) == utf8Scalar(
            source,
            starts[child] + 1 + offset
          )
        ) {
          offset += 1;
        } else {
          return false;
        }
      }

      return utf8Scalar(source, starts[child] + 1 + parentLength) == 47;
    }

    return false;
  }

  private boolean workspaceShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
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
      valid = key(source, kinds, starts, lengths, count, 8, 102769789353);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 10);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 11, 99733129497);
    }

    if (valid) {
      valid = memberValid(source, kinds, starts, lengths, count, 13);
    }

    if (valid) {
      valid = memberValid(source, kinds, starts, lengths, count, 20);
    }

    return valid;
  }

  /// Parses the canonical two-member YAML shape used by the native recovery fixture.
  public WorkspaceResult parseWorkspace(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (count == 27) {
      boolean validName = validWorkspaceName(source, starts[7] + 1, lengths[7] - 2);
      boolean validProfile = validWorkspaceName(source, starts[10] + 1, lengths[10] - 2);
      boolean shape = workspaceShape(source, kinds, starts, lengths, count);
      if (validName) {
        if (validProfile) {
          if (shape) {
            long order = compareTokenText(source, starts, lengths, 16, 23);
            boolean samePath = sameTokenText(source, starts, lengths, 19, 26);
            boolean firstContains = nestedPath(source, starts, lengths, 19, 26);
            boolean secondContains = nestedPath(source, starts, lengths, 26, 19);
            if (order < 0) {
              if (samePath) {
                return new WorkspaceResult.Error(starts[26]);
              }

              if (firstContains) {
                return new WorkspaceResult.Error(starts[26]);
              }

              if (secondContains) {
                return new WorkspaceResult.Error(starts[26]);
              }

              WorkspaceModel workspace = new WorkspaceModel(
                starts[7] + 1,
                lengths[7] - 2,
                lengths[10] - 2,
                lengths[16] - 2,
                lengths[19] - 2,
                lengths[23] - 2,
                lengths[26] - 2,
                2
              );
              return new WorkspaceResult.Value(workspace);
            }
          }
        }
      }
    }

    return new WorkspaceResult.Error(0);
  }

}
