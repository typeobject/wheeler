//! Exercises finite enums as payload-free variants without wire ordinals.
classical class FiniteEnums {
  enum Direction {
    case Left;
    case Right;
  }

  const long LEFT_VALUE = 3;
  const long RIGHT_VALUE = LEFT_VALUE + 4;
  state long selected = 0;

  /// Selects one enum member through an exhaustive match.
  ///
  /// - Effects: Mutates only the declared `selected` state.
  entry void main() {
    Direction direction = new Direction.Right();
    match (direction) {
      case Direction.Left() {
        selected = LEFT_VALUE;
      }
      case Direction.Right() {
        selected = RIGHT_VALUE;
      }
    }

    assert(selected == 7);
  }
}
