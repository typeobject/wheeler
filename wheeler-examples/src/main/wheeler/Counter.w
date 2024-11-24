// Example Wheeler program demonstrating reversibility
class Counter {
    rev int<64> count = 0;

    rev void increment() {
        count++;
    }

    rev void decrement() {
        count--;
    }

    pure int<64> get() {
        return count;
    }

    rev static void main() {
        Counter c = new Counter();

        // Forward execution
        c.increment();
        c.increment();
        print(c.get()); // Output: 2

        // Reverse execution
        reverse {
            c.increment();
            c.increment();
        }
        print(c.get()); // Output: 0
    }
}