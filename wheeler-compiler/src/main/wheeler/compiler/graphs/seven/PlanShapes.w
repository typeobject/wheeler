//! Assigns exact roles for admitted seven-module constant graph shapes.

module wheeler.compiler.graphs.seven.plan_shapes;

import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenGraphPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_DIRECT = 1;
  private const long SINGLE_EDGE = 1;
  private const long TWO_DIRECTS = 2;
  private const long TWO_EDGES = 2;
  private const long THREE_DIRECTS = 3;
  private const long THREE_EDGES = 3;
  private const long FOUR_EDGES = 4;
  private const long FIVE_EDGES = 5;

  /// Carries one validated topology and its leaf-to-root source order.
  public record SevenGraphPlan(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    long sixth,
    long seventh,
    boolean valid
  ) {}

  private SevenGraphPlan invalidPlan() {
    return new SevenGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  /// Assigns one chain edge and five direct root imports.
  public SevenGraphPlan chainAndDirectsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long leaf = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long fourthDirect = -1;
    long fifthDirect = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      long candidate = 0;
      while (candidate < MODULE_COUNT) limit MODULE_COUNT {
        if (graph[source * MODULE_COUNT + candidate] == 1) {
          leaf = source;
          dependent = candidate;
        }

        candidate += 1;
      }

      source += 1;
    }

    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = source;
          } else {
            if (secondDirect < 0) {
              secondDirect = source;
            } else {
              if (thirdDirect < 0) {
                thirdDirect = source;
              } else {
                if (fourthDirect < 0) {
                  fourthDirect = source;
                } else {
                  fifthDirect = source;
                }
              }
            }
          }
        }
      }

      source += 1;
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_CHAIN_AND_DIRECTS,
      leaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      fourthDirect,
      fifthDirect,
      true
    );
  }

  private long incomingCount(borrow mut words graph, long dependent) {
    long count = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[source * MODULE_COUNT + dependent];
      source += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long source) {
    long count = 0;
    long dependent = 0;
    while (dependent < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[source * MODULE_COUNT + dependent];
      dependent += 1;
    }

    return count;
  }

  /// Assigns one two-leaf fork and four direct root imports.
  public SevenGraphPlan forkAndDirectsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long dependent = -1;
    long firstLeaf = -1;
    long secondLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long fourthDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        dependent = candidate;
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = source;
        } else {
          secondLeaf = source;
        }
      }

      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = source;
          } else {
            if (secondDirect < 0) {
              secondDirect = source;
            } else {
              if (thirdDirect < 0) {
                thirdDirect = source;
              } else {
                fourthDirect = source;
              }
            }
          }
        }
      }

      source += 1;
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      fourthDirect,
      true
    );
  }

  /// Assigns one three-module chain and four direct root imports.
  public SevenGraphPlan longChainAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long middle = -1;
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        leaf = source;
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (rootDirect[leaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long fourthDirect = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = source;
          } else {
            if (secondDirect < 0) {
              secondDirect = source;
            } else {
              if (thirdDirect < 0) {
                thirdDirect = source;
              } else {
                fourthDirect = source;
              }
            }
          }
        }
      }

      source += 1;
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_LONG_CHAIN_AND_DIRECTS,
      leaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      fourthDirect,
      true
    );
  }

  /// Assigns two independent chains and three direct root imports.
  public SevenGraphPlan pairsAndDirectsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      long candidate = 0;
      while (candidate < MODULE_COUNT) limit MODULE_COUNT {
        if (graph[source * MODULE_COUNT + candidate] == 1) {
          if (firstLeaf < 0) {
            firstLeaf = source;
            firstDependent = candidate;
          } else {
            secondLeaf = source;
            secondDependent = candidate;
          }
        }

        candidate += 1;
      }

      source += 1;
    }

    if (secondLeaf < 0) {
      return invalidPlan();
    }

    if (firstDependent == secondLeaf) {
      return invalidPlan();
    }

    if (secondDependent == firstLeaf) {
      return invalidPlan();
    }

    if (rootDirect[firstDependent] == 1) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondDependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == firstDependent) {} else {
          if (source == secondDependent) {} else {
            if (firstDirect < 0) {
              firstDirect = source;
            } else {
              if (secondDirect < 0) {
                secondDirect = source;
              } else {
                thirdDirect = source;
              }
            }
          }
        }
      }

      source += 1;
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_PAIRS_AND_DIRECTS,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns three independent chains and one direct root import.
  public SevenGraphPlan threeChainsAndDirectPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long thirdLeaf = -1;
    long thirdDependent = -1;
    long direct = -1;
    long leafCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, source);
      long outgoing = outgoingCount(graph, source);
      if (outgoing == SINGLE_EDGE) {
        if (incoming == 0) {} else {
          return invalidPlan();
        }

        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        long dependent = 0;
        while (dependent < MODULE_COUNT) limit MODULE_COUNT {
          if (graph[source * MODULE_COUNT + dependent] == 1) {
            if (rootDirect[dependent] == 1) {} else {
              return invalidPlan();
            }

            if (leafCount == 0) {
              firstLeaf = source;
              firstDependent = dependent;
            }

            if (leafCount == 1) {
              secondLeaf = source;
              secondDependent = dependent;
            }

            if (leafCount == 2) {
              thirdLeaf = source;
              thirdDependent = dependent;
            }
          }

          dependent += 1;
        }

        leafCount += 1;
      } else {
        if (incoming == 0) {
          if (rootDirect[source] == 1) {
            direct = source;
          } else {
            return invalidPlan();
          }
        } else {
          if (incoming == SINGLE_EDGE) {} else {
            return invalidPlan();
          }
        }
      }

      source += 1;
    }

    if (leafCount == THREE_EDGES) {} else {
      return invalidPlan();
    }

    if (direct < 0) {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_THREE_CHAINS_AND_DIRECT,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      thirdLeaf,
      thirdDependent,
      direct,
      true
    );
  }

  /// Assigns one three-leaf fork and three direct root imports.
  public SevenGraphPlan threeLeafForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == THREE_EDGES) {
        dependent = candidate;
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (leafCount == 0) {
          firstLeaf = source;
        }

        if (leafCount == 1) {
          secondLeaf = source;
        }

        if (leafCount == 2) {
          thirdLeaf = source;
        }

        leafCount += 1;
      } else {
        if (rootDirect[source] == 1) {
          if (source == dependent) {} else {
            if (directCount == 0) {
              firstDirect = source;
            }

            if (directCount == 1) {
              secondDirect = source;
            }

            if (directCount == 2) {
              thirdDirect = source;
            }

            directCount += 1;
          }
        }
      }

      source += 1;
    }

    if (leafCount == THREE_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == THREE_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_THREE_LEAF_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns one five-leaf fork and one direct root import.
  public SevenGraphPlan fiveLeafForkAndDirectPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == FIVE_EDGES) {
        dependent = candidate;
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long fourthLeaf = -1;
    long fifthLeaf = -1;
    long direct = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (leafCount == 0) {
          firstLeaf = source;
        }

        if (leafCount == 1) {
          secondLeaf = source;
        }

        if (leafCount == 2) {
          thirdLeaf = source;
        }

        if (leafCount == 3) {
          fourthLeaf = source;
        }

        if (leafCount == 4) {
          fifthLeaf = source;
        }

        leafCount += 1;
      } else {
        if (rootDirect[source] == 1) {
          if (source == dependent) {} else {
            direct = source;
            directCount += 1;
          }
        }
      }

      source += 1;
    }

    if (leafCount == FIVE_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == SINGLE_DIRECT) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_FIVE_LEAF_FORK_AND_DIRECT,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      fourthLeaf,
      fifthLeaf,
      dependent,
      direct,
      true
    );
  }

  /// Assigns one four-leaf fork and two direct root imports.
  public SevenGraphPlan wideForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == FOUR_EDGES) {
        dependent = candidate;
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long fourthLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (leafCount == 0) {
          firstLeaf = source;
        }

        if (leafCount == 1) {
          secondLeaf = source;
        }

        if (leafCount == 2) {
          thirdLeaf = source;
        }

        if (leafCount == 3) {
          fourthLeaf = source;
        }

        leafCount += 1;
      } else {
        if (rootDirect[source] == 1) {
          if (source == dependent) {} else {
            if (directCount == 0) {
              firstDirect = source;
            } else {
              secondDirect = source;
            }

            directCount += 1;
          }
        }
      }

      source += 1;
    }

    if (leafCount == FOUR_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_WIDE_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      fourthLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

}
