//! Assigns bounded imported helper groups to canonical module-name ranges.

module wheeler.compiler.helper_owners;

import wheeler.compiler.ir;

classical class HelperOwnersTable {
  /// Caps executable dependency owners at the framed native graph bound.
  public const long MAX_IMPORTED_HELPER_OWNERS = 7;

  /// Associates one contiguous imported helper group with its canonical module.
  public record HelperOwner(SourceRange module, long helperCount) {}

  /// Carries up to seven imported helper groups in canonical root-import order.
  public record HelperOwners(
    long ownerCount,
    HelperOwner first,
    HelperOwner second,
    HelperOwner third,
    HelperOwner fourth,
    HelperOwner fifth,
    HelperOwner sixth,
    HelperOwner seventh
  ) {}

  /// Returns one absent owner used only beyond the active owner count.
  public HelperOwner noHelperOwner() {
    return new HelperOwner(new SourceRange(0, 0), 0);
  }

  /// Constructs one present imported helper owner.
  public HelperOwner importedHelperOwner(long start, long length, long helperCount) {
    return new HelperOwner(new SourceRange(start, length), helperCount);
  }

  /// Returns an empty imported-owner table.
  public HelperOwners noHelperOwners() {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(0, absent, absent, absent, absent, absent, absent, absent);
  }

  /// Returns a one-owner table.
  public HelperOwners oneHelperOwner(HelperOwner first) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(1, first, absent, absent, absent, absent, absent, absent);
  }

  /// Returns a two-owner table.
  public HelperOwners twoHelperOwners(HelperOwner first, HelperOwner second) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(2, first, second, absent, absent, absent, absent, absent);
  }

  /// Returns a three-owner table.
  public HelperOwners threeHelperOwners(HelperOwner first, HelperOwner second, HelperOwner third) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(3, first, second, third, absent, absent, absent, absent);
  }

  /// Returns a four-owner table.
  public HelperOwners fourHelperOwners(
    HelperOwner first,
    HelperOwner second,
    HelperOwner third,
    HelperOwner fourth
  ) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(4, first, second, third, fourth, absent, absent, absent);
  }

  /// Returns a five-owner table.
  public HelperOwners fiveHelperOwners(
    HelperOwner first,
    HelperOwner second,
    HelperOwner third,
    HelperOwner fourth,
    HelperOwner fifth
  ) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(5, first, second, third, fourth, fifth, absent, absent);
  }

  /// Returns a six-owner table.
  public HelperOwners sixHelperOwners(
    HelperOwner first,
    HelperOwner second,
    HelperOwner third,
    HelperOwner fourth,
    HelperOwner fifth,
    HelperOwner sixth
  ) {
    HelperOwner absent = noHelperOwner();
    return new HelperOwners(6, first, second, third, fourth, fifth, sixth, absent);
  }

  /// Returns a seven-owner table.
  public HelperOwners sevenHelperOwners(
    HelperOwner first,
    HelperOwner second,
    HelperOwner third,
    HelperOwner fourth,
    HelperOwner fifth,
    HelperOwner sixth,
    HelperOwner seventh
  ) {
    return new HelperOwners(7, first, second, third, fourth, fifth, sixth, seventh);
  }

  /// Selects one bounded owner slot.
  public HelperOwner helperOwnerAt(HelperOwners owners, long index) {
    if (index == 0) {
      return owners.first;
    }

    if (index == 1) {
      return owners.second;
    }

    if (index == 2) {
      return owners.third;
    }

    if (index == 3) {
      return owners.fourth;
    }

    if (index == 4) {
      return owners.fifth;
    }

    if (index == 5) {
      return owners.sixth;
    }

    return owners.seventh;
  }

  /// Counts imported helpers across all active owner groups.
  public long importedHelperCount(HelperOwners owners) {
    long count = 0;
    long owner = 0;
    while (owner < owners.ownerCount) limit MAX_IMPORTED_HELPER_OWNERS {
      count += helperOwnerAt(owners, owner).helperCount;
      owner += 1;
    }

    return count;
  }

  /// Returns the imported module for one helper, or an absent range for a root helper.
  public SourceRange importedHelperModule(HelperOwners owners, long helper) {
    long owner = 0;
    long remaining = helper;
    while (owner < owners.ownerCount) limit MAX_IMPORTED_HELPER_OWNERS {
      HelperOwner selected = helperOwnerAt(owners, owner);
      if (remaining < selected.helperCount) {
        return selected.module;
      }

      remaining -= selected.helperCount;
      owner += 1;
    }

    return new SourceRange(0, 0);
  }

  /// Validates active ranges, positive group widths, and canonical absent tail slots.
  public boolean helperOwnerRangesValid(HelperOwners owners, long sourceLength) {
    if (-1 < owners.ownerCount) {} else {
      return false;
    }

    if (owners.ownerCount < MAX_IMPORTED_HELPER_OWNERS + 1) {} else {
      return false;
    }

    long owner = 0;
    while (owner < MAX_IMPORTED_HELPER_OWNERS) limit MAX_IMPORTED_HELPER_OWNERS {
      HelperOwner selected = helperOwnerAt(owners, owner);
      if (owner < owners.ownerCount) {
        if (0 < selected.module.length) {} else {
          return false;
        }

        if (selected.module.start + selected.module.length < sourceLength + 1) {} else {
          return false;
        }

        if (0 < selected.helperCount) {} else {
          return false;
        }
      } else {
        if (selected.module.start == 0) {} else {
          return false;
        }

        if (selected.module.length == 0) {} else {
          return false;
        }

        if (selected.helperCount == 0) {} else {
          return false;
        }
      }

      owner += 1;
    }

    return true;
  }
}
