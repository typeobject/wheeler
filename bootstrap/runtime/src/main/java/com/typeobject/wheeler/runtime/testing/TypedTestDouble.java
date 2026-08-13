package com.typeobject.wheeler.runtime.testing;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/** Explicit bounded typed test boundary with queued responses and an owned event log. */
public final class TypedTestDouble<Request, Result> {
  public record Event<Request>(long sequence, Request request) {}

  public sealed interface Outcome<Result> permits Value, Failure {}

  public record Value<Result>(Result value) implements Outcome<Result> {
    public Value {
      Objects.requireNonNull(value, "value");
    }
  }

  public record Failure<Result>(String code) implements Outcome<Result> {
    public Failure {
      if (code == null || code.isBlank() || code.length() > 160) {
        throw new IllegalArgumentException("Typed test-double failure code is invalid");
      }
    }
  }

  public static final class DoubleFailure extends RuntimeException {
    private static final long serialVersionUID = 1L;

    DoubleFailure(String code) {
      super(code);
    }
  }

  private final int maxEvents;
  private final List<Outcome<Result>> responses;
  private final List<Event<Request>> events = new ArrayList<>();
  private int nextResponse;

  public TypedTestDouble(int maxEvents, List<Outcome<Result>> responses) {
    if (maxEvents < 1 || maxEvents > 4_096) {
      throw new IllegalArgumentException("Typed test-double event limit must be 1..4096");
    }
    this.maxEvents = maxEvents;
    this.responses = List.copyOf(responses);
    if (this.responses.isEmpty() || this.responses.size() > maxEvents) {
      throw new IllegalArgumentException("Typed test-double responses exceed event capacity");
    }
  }

  /** Records one typed request before consuming its exact queued response. */
  public Result call(Request request) {
    Objects.requireNonNull(request, "request");
    if (events.size() >= maxEvents || nextResponse >= responses.size()) {
      throw new IllegalStateException("Typed test-double capacity exhausted");
    }
    events.add(new Event<>(events.size(), request));
    Outcome<Result> response = responses.get(nextResponse++);
    if (response instanceof Failure<?> failure) {
      throw new DoubleFailure(failure.code());
    }
    return ((Value<Result>) response).value();
  }

  public List<Event<Request>> events() {
    return List.copyOf(events);
  }
}
