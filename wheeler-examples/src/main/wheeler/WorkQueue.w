//! Exercises bounded queue push, pop, empty, and full transitions.

module examples.queue.main;
import wheeler.core.collections.queue;
classical class WorkQueue {
    state long first = 0;
    state long second = 0;
    state long finalHead = 0;
    state long finalTail = 0;
    state long emptyObserved = 0;
    state long fullObserved = 0;

    void observeEmpty(words values, QueueCursor cursor) {
        Pop result = pop(values, cursor);
        match (result) {
            case Pop.Empty() {
                emptyObserved = 1;
            }
            case Pop.Value(long value, QueueCursor next) {
                emptyObserved = 0;
            }
        }
    }

    void observeFull(words values, QueueCursor cursor) {
        Push result = push(values, cursor, 25);
        match (result) {
            case Push.Full() {
                fullObserved = 1;
            }
            case Push.Value(QueueCursor next) {
                fullObserved = 0;
            }
        }
    }

    QueueCursor requirePush(words values, QueueCursor cursor, long value) {
        Push result = push(values, cursor, value);
        match (result) {
            case Push.Full() {
                return cursor;
            }
            case Push.Value(QueueCursor next) {
                return next;
            }
        }
    }

    QueueCursor takeFirst(words values, QueueCursor cursor) {
        Pop result = pop(values, cursor);
        match (result) {
            case Pop.Empty() {
                return cursor;
            }
            case Pop.Value(long value, QueueCursor next) {
                first = value;
                return next;
            }
        }
    }

    QueueCursor takeSecond(words values, QueueCursor cursor) {
        Pop result = pop(values, cursor);
        match (result) {
            case Pop.Empty() {
                return cursor;
            }
            case Pop.Value(long value, QueueCursor next) {
                second = value;
                return next;
            }
        }
    }

    /// Runs the bounded `WorkQueue` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        region arena = new region(32, 1);
        words values = allocate(arena, 4);
        QueueCursor cursor = new QueueCursor(0, 0);
        observeEmpty(values, cursor);
        cursor = requirePush(values, cursor, 4);
        cursor = requirePush(values, cursor, 9);
        cursor = requirePush(values, cursor, 16);
        cursor = requirePush(values, cursor, 25);
        observeFull(values, cursor);
        cursor = takeFirst(values, cursor);
        cursor = takeSecond(values, cursor);
        finalHead = cursor.head;
        finalTail = cursor.tail;
        drop(values);
        drop(arena);
        assert first == 4;
        assert second == 9;
        assert finalHead == 2;
        assert finalTail == 4;
        assert emptyObserved == 1;
        assert fullObserved == 1;
    }
}
