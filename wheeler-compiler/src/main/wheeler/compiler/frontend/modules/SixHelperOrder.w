//! Orders six scalar-helper sources by their validated root-import ranges.

module wheeler.compiler.six_helper_order;

import wheeler.compiler.module_linker;

classical class SixHelperOrderPlanner {
  /// Identifies six source frames in canonical root-import order.
  public record SixHelperOrder(
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    long sixth
  ) {}

  private long helperRank(
    long source,
    long firstStart,
    long secondStart,
    long thirdStart,
    long fourthStart,
    long fifthStart,
    long sixthStart
  ) {
    long selected = firstStart;
    if (source == 1) {
      selected = secondStart;
    }

    if (source == 2) {
      selected = thirdStart;
    }

    if (source == 3) {
      selected = fourthStart;
    }

    if (source == 4) {
      selected = fifthStart;
    }

    if (source == 5) {
      selected = sixthStart;
    }

    long rank = 0;
    if (firstStart < selected) {
      rank += 1;
    }

    if (secondStart < selected) {
      rank += 1;
    }

    if (thirdStart < selected) {
      rank += 1;
    }

    if (fourthStart < selected) {
      rank += 1;
    }

    if (fifthStart < selected) {
      rank += 1;
    }

    if (sixthStart < selected) {
      rank += 1;
    }

    return rank;
  }

  private long sourceAtRank(
    long rank,
    long firstRank,
    long secondRank,
    long thirdRank,
    long fourthRank,
    long fifthRank
  ) {
    if (firstRank == rank) {
      return 0;
    }

    if (secondRank == rank) {
      return 1;
    }

    if (thirdRank == rank) {
      return 2;
    }

    if (fourthRank == rank) {
      return 3;
    }

    if (fifthRank == rank) {
      return 4;
    }

    return 5;
  }

  /// Orders six validated helper plans without trusting source-frame arrival.
  public SixHelperOrder orderSixHelperPlans(
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan,
    LinkPlan fourthPlan,
    LinkPlan fifthPlan,
    LinkPlan sixthPlan
  ) {
    long firstRank = helperRank(
      0,
      firstPlan.linkedOwnerStart,
      secondPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerStart,
      fifthPlan.linkedOwnerStart,
      sixthPlan.linkedOwnerStart
    );
    long secondRank = helperRank(
      1,
      firstPlan.linkedOwnerStart,
      secondPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerStart,
      fifthPlan.linkedOwnerStart,
      sixthPlan.linkedOwnerStart
    );
    long thirdRank = helperRank(
      2,
      firstPlan.linkedOwnerStart,
      secondPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerStart,
      fifthPlan.linkedOwnerStart,
      sixthPlan.linkedOwnerStart
    );
    long fourthRank = helperRank(
      3,
      firstPlan.linkedOwnerStart,
      secondPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerStart,
      fifthPlan.linkedOwnerStart,
      sixthPlan.linkedOwnerStart
    );
    long fifthRank = helperRank(
      4,
      firstPlan.linkedOwnerStart,
      secondPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerStart,
      fifthPlan.linkedOwnerStart,
      sixthPlan.linkedOwnerStart
    );
    return new SixHelperOrder(
      sourceAtRank(0, firstRank, secondRank, thirdRank, fourthRank, fifthRank),
      sourceAtRank(1, firstRank, secondRank, thirdRank, fourthRank, fifthRank),
      sourceAtRank(2, firstRank, secondRank, thirdRank, fourthRank, fifthRank),
      sourceAtRank(3, firstRank, secondRank, thirdRank, fourthRank, fifthRank),
      sourceAtRank(4, firstRank, secondRank, thirdRank, fourthRank, fifthRank),
      sourceAtRank(5, firstRank, secondRank, thirdRank, fourthRank, fifthRank)
    );
  }
}
