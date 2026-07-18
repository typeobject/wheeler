// Exhaustive tagged selection with typed payload bindings and structural equality.
classical class Variants {
    variant Option {
        case None();
        case Some(long value);
    }

    state long selected = 0;
    state long equal = 0;

    Option choose(boolean present, long value) {
        if (present) {
            return new Option.Some(value);
        }
        return new Option.None();
    }

    entry void main() {
        Option first = choose(true, 9);
        Option second = new Option.Some(9);
        if (first == second) {
            equal = 1;
        }
        match (first) {
            case Option.None() {
                selected = 1;
            }
            case Option.Some(long value) {
                selected = value;
            }
        }
        assert selected == 9;
        assert equal == 1;
    }
}
