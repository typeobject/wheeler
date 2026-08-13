package com.typeobject.wheeler.runtime.testing;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Typed failing and event-recording double tests with no ambient interception state. */
final class TypedTestDoubleTest {
  @Test
  void recordsTypedEventsInCallOrderAndReturnsQueuedValues() {
    TypedTestDouble<Request, Reply> boundary = new TypedTestDouble<>(
        2,
        List.of(
            new TypedTestDouble.Value<>(new Reply(11)),
            new TypedTestDouble.Value<>(new Reply(12))));

    assertEquals(new Reply(11), boundary.call(new Request(1)));
    assertEquals(new Reply(12), boundary.call(new Request(2)));
    assertEquals(
        List.of(
            new TypedTestDouble.Event<>(0, new Request(1)),
            new TypedTestDouble.Event<>(1, new Request(2))),
        boundary.events());
    assertThrows(
        IllegalStateException.class,
        () -> boundary.call(new Request(3)));
  }

  @Test
  void failingResponseStillPublishesItsTypedEvent() {
    TypedTestDouble<Request, Reply> boundary = new TypedTestDouble<>(
        1,
        List.of(new TypedTestDouble.Failure<>("TEST_PROVIDER_REJECTED")));

    TypedTestDouble.DoubleFailure failure = assertThrows(
        TypedTestDouble.DoubleFailure.class,
        () -> boundary.call(new Request(7)));

    assertEquals("TEST_PROVIDER_REJECTED", failure.getMessage());
    assertEquals(List.of(new TypedTestDouble.Event<>(0, new Request(7))), boundary.events());
  }

  private record Request(long value) {}

  private record Reply(long value) {}
}
