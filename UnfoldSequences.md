# Swift's UnfoldSequence
In this article I want to show some examples which benefits from the use of `UnfoldSequence`.

## Printing all digits of an integer
Suppose we want to sum up all digits of a non-negative integer value. The algorithm of getting all digits is easy. It can be expressed by a loop, a module operation and a division.

```Swift
    func printAllDigitsOf(_ n: Int) {
       var m = abs(n)
       repeat {
           let digit = m % 10
           m = m / 10
           print(digit)
       } while m != 0
    }
```

`m%10` is the right most digit of `m`. `m/10` removes the right most digit from `m`. If `m` becomes `0`, the algorithm is done. This function can be extended easily to sum up all digits (Cross sum). 


```Swift
    func crossSum(_ n: Int) -> Int {
        var m = abs(n)
        var sum = 0
        repeat {
            let digit = m % 10
            m = m / 10
            sum += digit
        } while m != 0
        return sum
    }
```

## Separation of concerns
In both cases we mix up two different operations:
1. Extracting the digits of an integer
2. Doing something with the digits

It would be much better to separate the different concerns from each other. A sort improvement would be if we create a function which does only the extraction of digits:

```Swift
    func digitsOf(_ n: Int) -> [Int] {
        var digits: [Int] = []
        var m = abs(n)
        repeat {
            let digit = m % 10
            m = m / 10
            digits.append(digit)
        } while m != 0
        return digits
    }
```

The digits are stored in an array. By using `digitsOf` the functions for the cross sum and printing digits become more easy:

```Swift
    func printAllDigitsOf(_ n: Int) {
        for digit in digitsOf(n) {
            print(n)
        }
    }
```

```Swift
    func crossSum(_ n: Int) -> Int 
        return digitsOf(n).reduce(0, +)
    }
```

## Being lazy with UnfoldSequence
So far so good. However, there is one point which is still not quite nice. We are creating an array to store the digits. Why should we want this? We just want to iterate through them. So we need to consider the digits of an integer as a sequence of digits. Actually, that is what we already doing by building an array of digits.

In Swift custom sequences need to conform to the Sequence protocol. To implement a Swift sequence from scratch, one need to implement a sequence and corresponding iterator class. However, there are already some helpers which simplifies this process.

One helper is `UnfoldSequence<T, S>` which describes a sequence of values with type `T` by a closure. The closure function needs have the signature `next(state: inout S)->T?`. The function does two things:
1. It returns the "next" (optional) value of the sequence
2. It modifies some kind of state
If `next` returns `nil`, then the sequence ends.

To compute the digits of an integer we define the state as a tuple consisting of an integer and a boolean:

```Swift
typealias State = (Int, Bool)
```

The first component of the state represents the number for which the digits needs to be computed and the boolean says if the algorithm is done. State `(n, b)` means that we need to generate the digits of number `n` if `b`is false. If `b` is true, no digits are left to be generated. In fact the final state will be `(0, true)`. 

Let be `(123, false)` the initial state. The following state transitions needs to be performed by the next-function:

```Swift
(123, false) --> (12, false) --> (1, false) --> (0, true)
```

With each state transition the function needs to return the removed digit. If the final state is reached, it will return `nil`:

```Swift
    func nextDigit(_ state: inout (Int, Bool)) -> Int? {
        let (n, done) = state
        guard !done else { return nil }
        let digit = n % 10
        let tail = n / 10
        state = (tail, tail == 0)
    }
```

`digitsOf` can be written by creating an `UnfoldSequence` with next function `nextDigit`:

```Swift
    func digitsOf(n: Int) -> UnfoldSequence<Int, (Int, Bool)> {
        return sequence(state: (n, false), next: nextDigit)
    }
```

As function `nextDigit` does not make much sense by its own, we might hide it within function `digitsOf`:

```Swift
    func digitsOf(_ n: Int) -> UnfoldSequence<Int, (Int, Bool)> {
        let nextDigit = {
            (state: inout (Int, Bool)) -> Int? in
    
            let (n, done) = state
            guard !done else { return nil }
            let digit = n % 10
            let tail = n / 10
            state = (tail, tail == 0)
 
            return digit
        }
 
        return sequence(state: (n, false), next: nextDigit)
    }
```

Function `digitsOf` does not compute the digits of n. It just creates a sequence. The digits themselves are computed lazy along with the iteration.

## Fibonacci numbers
Now that we know how `UnfoldSequence` works, we could try something else. The Fibonacci numbers is a famous number sequence. It starts with 0 and 1. The next numbers of the sequence are computed as the sum of the two previous Fibonacci numbers: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...

To compute the Fibonacci numbers with a next-function, we could use the tuple consisting of the two previous Fibonacci numbers as state. The initial state is then `(0, 1)`.

```Swift
    func fibonacci() -> UnfoldSequence<Int, (Int, Int)> {
        let nextFibonacciNumber = {
            (state: inout (Int, Int)) -> Int? in
            let (n, m) = state
            let sum = n + m
            state = (m, sum)
            return n
       }
 
       return sequence(state: (0, 1), next: nextFibonacciNumber)
    }
```

The interesting thing about the Fibonacci numbers is that it is infinite. However, Int is not infinite and the function will crash if the overflow occurs. To prevent that we can use the function `addWithOverflow` and add a guard statement:

```Swift
    func fibonacci() -> UnfoldSequence<Int, (Int, Int)> {
        let nextFibonacciNumber = {
            (state: inout (Int, Int)) -> Int? in
            let (n, m) = state
            let (sum, overflow) = Int.addWithOverflow(n, m)
            guard !overflow else { return nil }
            state = (m, sum)
            return n
        }
 
        return sequence(state: (0, 1), next: nextFibonacciNumber)
    }
```

How many Fibonacci numbers can we calculate with this sequence? Let's count all elements:

```Swift
    let count = fibonacci().reduce(0) { sum, n in sum + 1 } // == 91
```

Only 91 numbers are possible until the maximum integer is exceeded. The overflow occurs a bit early. Actually two more numbers were already computed but not returned yet. But the benefit to have two more numbers compared to the effort to modify the next-function is too small. So we keep the function as is.
 
## Summary
`UnfoldSequence` allows to break up closed algorithms by removing the outer loop. Instead of using stored sequences, lazy sequences can be potential infinite.