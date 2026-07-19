//! Provides a bounded queue over caller-owned word storage.

module wheeler.core.collections.queue;

classical class LongQueue {
  /// Defines immutable `QueueCursor` values for this module.
  public record QueueCursor(long head, long tail) {}

  /// Defines the closed `Push` cases exported by this module.
  public variant Push {
    case Full();
    case Value(QueueCursor next);
  }

  /// Defines the closed `Pop` cases exported by this module.
  public variant Pop {
    case Empty();
    case Value(long value, QueueCursor next);
  }

  /// Pushes one value into caller-owned bounded queue storage.
  public Push push(borrow mut words values, QueueCursor cursor, long value) {
    if (cursor.tail < bufferLength(values)) {
      set(values, cursor.tail, value);
      QueueCursor next = new QueueCursor(cursor.head, cursor.tail + 1);
      return new Push.Value(next);
    }

    return new Push.Full();
  }

  /// Pops one value from caller-owned bounded queue storage.
  public Pop pop(borrow mut words values, QueueCursor cursor) {
    if (cursor.head < cursor.tail) {
      long value = values[cursor.head];
      QueueCursor next = new QueueCursor(cursor.head + 1, cursor.tail);
      return new Pop.Value(value, next);
    }

    return new Pop.Empty();
  }
}
