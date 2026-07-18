module examples.queue.main;
import examples.collections.queue;
classical class WorkQueue {
    state long first = 0;
    state long second = 0;
    state long finalHead = 0;
    state long finalTail = 0;
    state long emptyObserved = 0;
    state long fullObserved = 0;

    long observeEmpty(words values, QueueCursor cursor) {
        Pop result = pop(values, cursor);
        long observed = 0;
        match (result) {
            case Pop.Empty() {
                observed = 1;
            }
            case Pop.Value(long value, QueueCursor next) {
                observed = 0;
            }
        }
        return observed;
    }

    long observeFull(words values, QueueCursor cursor) {
        Push result = push(values, cursor, 25);
        long observed = 0;
        match (result) {
            case Push.Full() {
                observed = 1;
            }
            case Push.Value(QueueCursor next) {
                observed = 0;
            }
        }
        return observed;
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

    entry void main() {
        region arena = new region(32, 1);
        words values = allocate(arena, 4);
        QueueCursor cursor = new QueueCursor(0, 0);
        emptyObserved = observeEmpty(values, cursor);
        cursor = requirePush(values, cursor, 4);
        cursor = requirePush(values, cursor, 9);
        cursor = requirePush(values, cursor, 16);
        cursor = requirePush(values, cursor, 25);
        fullObserved = observeFull(values, cursor);
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
