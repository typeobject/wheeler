// Basic counter example demonstrating reversibility
classical class Counter {
    rev int count = 0;

    rev void increment() {
        count++;
    }

    rev void decrement() {
        count--;
    }

    pure int get() {
        return count;
    }

    rev static void main(String[] args) {
        Counter c = new Counter();

        // Forward execution
        c.increment();
        c.increment();
        System.out.println(c.get()); // 2

        // Reverse execution
        reverse {
            c.increment();
            c.increment();
        }
        System.out.println(c.get()); // 0
    }
}