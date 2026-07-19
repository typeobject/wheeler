//! Parses bounded canonical workspace manifests.

module wheeler.packages.workspace;

import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.tokens;

classical class Workspace {
  /// Defines immutable `WorkspaceModel` values for this module.
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

  /// Defines the closed `WorkspaceResult` cases exported by this module.
  public variant WorkspaceResult {
    case Value(WorkspaceModel workspace);
    case Error(long offset);
  }

  private boolean memberValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    boolean validName = validWorkspaceName(
      source,
      starts[recordStart + 1] + 1,
      lengths[recordStart + 1] - 2
    );
    boolean validPath = validWorkspacePath(
      source,
      starts[recordStart + 3] + 1,
      lengths[recordStart + 3] - 2
    );
    if (keywordAt(source, starts, lengths, recordStart, 3217197722)) {
      if (quoted(kinds, lengths, recordStart + 1)) {
        if (validName) {
          if (keywordAt(source, starts, lengths, recordStart + 2, 3433509)) {
            if (quoted(kinds, lengths, recordStart + 3)) {
              if (validPath) {
                return semicolonAt(source, kinds, starts, recordStart + 4);
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

  /// Parses and validates one canonical workspace manifest.
  public WorkspaceResult parseWorkspace(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    boolean validName = validWorkspaceName(source, starts[1] + 1, lengths[1] - 2);
    boolean validProfile = validWorkspaceName(source, starts[3] + 1, lengths[3] - 2);
    if (keywordAt(source, starts, lengths, 0, 104652281998485)) {
      if (quoted(kinds, lengths, 1)) {
        if (validName) {
          if (keywordAt(source, starts, lengths, 2, 102769789353)) {
            if (quoted(kinds, lengths, 3)) {
              if (validProfile) {
                if (semicolonAt(source, kinds, starts, 4)) {
                  if (memberValid(source, kinds, starts, lengths, 5)) {
                    if (count == 10) {
                      WorkspaceModel one = new WorkspaceModel(
                        starts[1] + 1,
                        lengths[1] - 2,
                        lengths[3] - 2,
                        lengths[6] - 2,
                        lengths[8] - 2,
                        0,
                        0,
                        1
                      );
                      return new WorkspaceResult.Value(one);
                    }

                    if (memberValid(source, kinds, starts, lengths, 10)) {
                      long memberOrder = compareTokenText(source, starts, lengths, 6, 11);
                      boolean samePath = sameTokenText(source, starts, lengths, 8, 13);
                      boolean firstContainsSecond = nestedPath(source, starts, lengths, 8, 13);
                      boolean secondContainsFirst = nestedPath(source, starts, lengths, 13, 8);
                      if (memberOrder < 0) {
                        if (samePath) {
                          return new WorkspaceResult.Error(starts[13]);
                        }

                        if (firstContainsSecond) {
                          return new WorkspaceResult.Error(starts[13]);
                        }

                        if (secondContainsFirst) {
                          return new WorkspaceResult.Error(starts[13]);
                        }

                        if (count == 15) {
                          WorkspaceModel two = new WorkspaceModel(
                            starts[1] + 1,
                            lengths[1] - 2,
                            lengths[3] - 2,
                            lengths[6] - 2,
                            lengths[8] - 2,
                            lengths[11] - 2,
                            lengths[13] - 2,
                            2
                          );
                          return new WorkspaceResult.Value(two);
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

    return new WorkspaceResult.Error(0);
  }
}
