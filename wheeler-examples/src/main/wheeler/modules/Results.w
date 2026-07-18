//! Defines and consumes a payload-carrying result variant.

module examples.results;
classical class Results {
    /// Defines the closed `Outcome` cases exported by this module.
    public variant Outcome {
        case Error(long offset);
        case Value(long value);
    }

    /// Classifies a signed value as an explicit result variant.
    public Outcome classify(long value) {
        if (value < 0) {
            return new Outcome.Error(0);
        }
        return new Outcome.Value(value);
    }

    /// Returns a successful result payload or its explicit error offset.
    public long unwrap(Outcome outcome) {
        long selected = 0;
        match (outcome) {
            case Outcome.Error(long offset) {
                selected = 0 - offset;
            }
            case Outcome.Value(long value) {
                selected = value;
            }
        }
        return selected;
    }
}
