module examples.collections.queue;
classical class LongQueue {
    public record QueueCursor(long head, long tail) {}

    public variant Push {
        case Full();
        case Value(QueueCursor next);
    }

    public variant Pop {
        case Empty();
        case Value(long value, QueueCursor next);
    }

    public Push push(words values, QueueCursor cursor, long value) {
        if (cursor.tail < bufferLength(values)) {
            set(values, cursor.tail, value);
            QueueCursor next = new QueueCursor(cursor.head, cursor.tail + 1);
            return new Push.Value(next);
        }
        return new Push.Full();
    }

    public Pop pop(words values, QueueCursor cursor) {
        if (cursor.head < cursor.tail) {
            long value = values[cursor.head];
            QueueCursor next = new QueueCursor(cursor.head + 1, cursor.tail);
            return new Pop.Value(value, next);
        }
        return new Pop.Empty();
    }
}
