module examples.results;
classical class Results {
    public variant Outcome {
        case Error(long offset);
        case Value(long value);
    }

    public Outcome classify(long value) {
        if (value < 0) {
            return new Outcome.Error(0);
        }
        return new Outcome.Value(value);
    }

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
