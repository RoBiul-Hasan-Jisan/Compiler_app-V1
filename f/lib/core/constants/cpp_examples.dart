/// Ready-to-run demo programs shown in the "Learn by examples" screen.
///
/// Every program here was run against the mcpp backend and produces the
/// output described. They use mcpp syntax: `print(...)` instead of `cout`,
/// no `#include`, no `cin`, no STL containers.
class CppExample {
  final String title;
  final String description;
  final String level;
  final String code;

  const CppExample({
    required this.title,
    required this.description,
    required this.level,
    required this.code,
  });
}

class CppExamples {
  CppExamples._();

  static const List<CppExample> all = [
    CppExample(
      title: 'Hello, World!',
      description: 'Your first program: main() and print().',
      level: 'Beginner',
      code: r'''
// Welcome to C++ IDE!
// Every program starts at main().
// Use print(...) to show text. \n means "new line".

int main() {
    print("Hello, World!\n");
    print("I am writing my first program.\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Variables & math',
      description: 'int, float, string, char, bool and basic arithmetic.',
      level: 'Beginner',
      code: r'''
// Variables store values. Declare them with a type first.
//   int    -> whole numbers      float -> decimals
//   string -> text               char  -> one letter
//   bool   -> true or false

int main() {
    int age = 20;
    float height = 5.9;
    string name = "Sara";
    char grade = 'A';
    bool isStudent = true;

    print("Name: ", name, "\n");
    print("Age: ", age, "\n");
    print("Height: ", height, "\n");
    print("Grade: ", grade, "\n");
    print("Student: ", isStudent, "\n");   // true prints as 1

    // Math with variables
    int a = 12;
    int b = 5;
    print("a + b = ", a + b, "\n");
    print("a - b = ", a - b, "\n");
    print("a * b = ", a * b, "\n");
    print("a / b = ", a / b, "\n");         // whole-number division
    print("a % b = ", a % b, "\n");         // remainder
    return 0;
}
''',
    ),
    CppExample(
      title: 'If / else decisions',
      description: 'Make choices with if, else if, else, && and ||.',
      level: 'Beginner',
      code: r'''
// if / else if / else lets your program make decisions.

int main() {
    int marks = 76;

    if (marks >= 90) {
        print("Grade A+\n");
    } else if (marks >= 80) {
        print("Grade A\n");
    } else if (marks >= 70) {
        print("Grade B\n");
    } else if (marks >= 60) {
        print("Grade C\n");
    } else {
        print("Fail\n");
    }

    // Combine conditions with && (and) and || (or)
    int age = 25;
    bool hasTicket = true;
    if (age >= 18 && hasTicket) {
        print("You can enter.\n");
    }

    // Even or odd using % (remainder)
    int n = 14;
    if (n % 2 == 0) {
        print(n, " is even\n");
    } else {
        print(n, " is odd\n");
    }
    return 0;
}
''',
    ),
    CppExample(
      title: 'Loops',
      description: 'for, while, do-while, break and continue.',
      level: 'Beginner',
      code: r'''
// Loops repeat code.

int main() {
    // for loop: start; condition; step
    print("Counting: ");
    for (int i = 1; i <= 5; i++) {
        print(i, " ");
    }
    print("\n");

    // while loop: repeats while the condition is true
    int n = 10;
    while (n > 0) {
        print(n, " ");
        n = n - 3;
    }
    print("\n");

    // do-while: always runs at least once
    int x = 1;
    do {
        print("x = ", x, "\n");
        x++;
    } while (x <= 3);

    // break stops a loop, continue skips to the next round
    for (int i = 1; i <= 10; i++) {
        if (i == 3) {
            continue;   // skip 3
        }
        if (i == 7) {
            break;      // stop at 7
        }
        print(i, " ");
    }
    print("\n");

    // Sum of 1 to 100
    int sum = 0;
    for (int i = 1; i <= 100; i++) {
        sum = sum + i;
    }
    print("Sum 1..100 = ", sum, "\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Functions',
      description: 'Write reusable code, return values, and use recursion.',
      level: 'Beginner',
      code: r'''
// Functions are reusable blocks of code.
// Format: returnType name(parameters) { ... }

int add(int a, int b) {
    return a + b;
}

int biggest(int a, int b) {
    if (a > b) {
        return a;
    }
    return b;
}

// void means "returns nothing"
void greet(string name) {
    print("Hello, ", name, "!\n");
}

// A function can call itself (recursion)
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int main() {
    greet("Sara");
    print("add(4, 7) = ", add(4, 7), "\n");
    print("biggest(9, 3) = ", biggest(9, 3), "\n");
    print("5! = ", factorial(5), "\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Arrays',
      description: 'Store many values; sum, average, highest, reverse.',
      level: 'Beginner',
      code: r'''
// An array holds many values of the same type.
// Indexes start at 0. int scores[5] has indexes 0 to 4.

int main() {
    int scores[5];
    scores[0] = 70;
    scores[1] = 85;
    scores[2] = 60;
    scores[3] = 95;
    scores[4] = 80;

    // Print all values
    print("Scores: ");
    for (int i = 0; i < 5; i++) {
        print(scores[i], " ");
    }
    print("\n");

    // Sum, average and biggest
    int sum = 0;
    int max = scores[0];
    for (int i = 0; i < 5; i++) {
        sum = sum + scores[i];
        if (scores[i] > max) {
            max = scores[i];
        }
    }
    print("Sum = ", sum, "\n");
    print("Average = ", sum / 5.0, "\n");
    print("Highest = ", max, "\n");

    // Print in reverse
    print("Reversed: ");
    for (int i = 4; i >= 0; i--) {
        print(scores[i], " ");
    }
    print("\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Switch & calculator',
      description: 'Pick a branch with switch / case / break.',
      level: 'Beginner',
      code: r'''
// switch picks one branch based on a value.
// Always end each case with break!

int main() {
    int day = 3;

    switch (day) {
        case 1:
            print("Monday\n");
            break;
        case 2:
            print("Tuesday\n");
            break;
        case 3:
            print("Wednesday\n");
            break;
        case 4:
            print("Thursday\n");
            break;
        default:
            print("Some other day\n");
    }

    // A tiny calculator
    int a = 12;
    int b = 4;
    int op = 3;   // 1 = add, 2 = subtract, 3 = multiply, 4 = divide
    switch (op) {
        case 1:
            print(a, " + ", b, " = ", a + b, "\n");
            break;
        case 2:
            print(a, " - ", b, " = ", a - b, "\n");
            break;
        case 3:
            print(a, " * ", b, " = ", a * b, "\n");
            break;
        case 4:
            print(a, " / ", b, " = ", a / b, "\n");
            break;
        default:
            print("Unknown operation\n");
    }
    return 0;
}
''',
    ),
    CppExample(
      title: 'Tables & patterns',
      description: 'Nested loops: multiplication table, stars, pyramid.',
      level: 'Easy',
      code: r'''
// Nested loops: a loop inside a loop.
// Great for tables and patterns.

int main() {
    // Multiplication table of 7
    for (int i = 1; i <= 10; i++) {
        print("7 x ", i, " = ", 7 * i, "\n");
    }
    print("\n");

    // Star triangle
    for (int row = 1; row <= 5; row++) {
        for (int col = 1; col <= row; col++) {
            print("* ");
        }
        print("\n");
    }
    print("\n");

    // Number pyramid
    for (int row = 1; row <= 4; row++) {
        for (int space = 1; space <= 4 - row; space++) {
            print(" ");
        }
        for (int k = 1; k <= row; k++) {
            print(row, " ");
        }
        print("\n");
    }
    return 0;
}
''',
    ),
    CppExample(
      title: 'Prime numbers',
      description: 'Combine a bool function with loops to find primes.',
      level: 'Easy',
      code: r'''
// Find prime numbers. A prime can only be divided by 1 and itself.
// This shows how functions and loops work together.

bool isPrime(int n) {
    if (n < 2) {
        return false;
    }
    for (int i = 2; i * i <= n; i++) {
        if (n % i == 0) {
            return false;
        }
    }
    return true;
}

int main() {
    print("Prime numbers up to 50:\n");
    int count = 0;
    for (int n = 2; n <= 50; n++) {
        if (isPrime(n)) {
            print(n, " ");
            count++;
        }
    }
    print("\nTotal: ", count, "\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Fibonacci, GCD, digits',
      description: 'Classic practice problems using functions and loops.',
      level: 'Easy',
      code: r'''
// Classic problems: Fibonacci, GCD and digit sum.

int fib(int n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

// Greatest common divisor (Euclid's algorithm)
int gcd(int a, int b) {
    while (b != 0) {
        int t = b;
        b = a % b;
        a = t;
    }
    return a;
}

int digitSum(int n) {
    int sum = 0;
    while (n > 0) {
        sum = sum + n % 10;
        n = n / 10;
    }
    return sum;
}

int main() {
    print("Fibonacci: ");
    for (int i = 0; i < 10; i++) {
        print(fib(i), " ");
    }
    print("\n");
    print("gcd(48, 18) = ", gcd(48, 18), "\n");
    print("digitSum(12345) = ", digitSum(12345), "\n");
    return 0;
}
''',
    ),
    CppExample(
      title: 'Bubble sort',
      description: 'Sort an array with nested loops and swapping.',
      level: 'Intermediate',
      code: r'''
// Bubble sort. Arrays can't be passed to functions here,
// so the array is declared outside main (a global array).

int data[6];

void fillData() {
    data[0] = 64;
    data[1] = 25;
    data[2] = 12;
    data[3] = 22;
    data[4] = 11;
    data[5] = 90;
}

void printData() {
    for (int i = 0; i < 6; i++) {
        print(data[i], " ");
    }
    print("\n");
}

void bubbleSort() {
    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5 - i; j++) {
            if (data[j] > data[j + 1]) {
                int temp = data[j];
                data[j] = data[j + 1];
                data[j + 1] = temp;
            }
        }
    }
}

int main() {
    fillData();
    print("Before: ");
    printData();
    bubbleSort();
    print("After:  ");
    printData();
    return 0;
}
''',
    ),
    CppExample(
      title: 'Temperature table',
      description: 'float numbers and a Celsius to Fahrenheit table.',
      level: 'Easy',
      code: r'''
// Decimal numbers (float) and a conversion table.

float toFahrenheit(float celsius) {
    return celsius * 9 / 5 + 32;
}

int main() {
    for (int c = 0; c <= 100; c = c + 20) {
        print(c, " C = ", toFahrenheit(c), " F\n");
    }
    return 0;
}
''',
    ),
  ];
}
