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

One helper is `UnfoldSequence<T, S>` which describes a sequence of values by a closure. All values of the sequence are of type `T`. The closure function needs have the signature `next(state: inout S)->T?`. The function does two things:

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
`UnfoldSequence` allows to break up closed algorithms by removing the outer loop. Instead of using stored sequences, lazy sequences can be potential infinite. Checkout `UnfoldSequence.playground` for the code examples.

# Concatenating sequences lazily
In the previous chapter I described how you can create lazy sequences by `UnfoldSequence`. Sequences were generated by functions which returned the sequence values and had a mutable state.
In this chapter I want to show how `UnfoldSequence` can be used to concat two sequences lazily.

## Concat Operation
The concatenation of two sequences S and T is only possible if their elements are of the same type. The signature of the `concat` function looks therefore like this:

```Swift
func concat<S: Sequence, T: Sequence where
            S.Iterator.Element==T.Iterator.Element>(_ lhs: S, _ rhs: T) -> Result
``` 

The function concats two sequences `lhs` and `rhs`. Both can be of different sequence type but they contain elements of the same type. The concatenation can be defined by using the  `UnfoldSequence`. The state of the next-function will be a pair of Iterators. One iterator is iterating over `lhs` and the other one is iterating over  `rhs`.

The next-function can be defined as follows:

```Swift
func nextElement(state: inout (S.Iterator, T.iterator)) -> Element? {
    return state.0.next() ?? state.1.next()
}
```

As a reminder `state.0.next() ?? state.1.next()` is a short-form of the following piece of code:

```Swift
if let next = state.0.next() {
    return next
}
else {
    return state.1.next()
}
```

With each call this function increments the iterator of the first sequence until the sequence ends. Then it iterates over the second sequence.

In total the concat function looks like this:

```Swift
typealias ConcatSequence<S: Sequence, T: Sequence> = 
            UnfoldSequence<S.Iterator.Element, (S.Iterator, T.Iterator)>

func concat<
        S: Sequence, T: Sequence where 
        S.Iterator.Element==T.Iterator.Element>(_ lhs: S, _ rhs: T)
        -> ConcatSequence<S, T>
{
      typealias Element = S.Iterator.Element
      let nextElement = {
          (state: inout (S.Iterator, T.Iterator)) -> Element? in
          return state.0.next() ?? state.1.next()
      }
      return sequence(state: (lhs.makeIterator(), rhs.makeIterator()), next: nextElement)
}
```

## Fibonacci
In last chapter I wrote that the Fibonacci sequence could be two number longer for int. This is due to the fact that the sequence end was signaled a bit to early. With concat this can be changed easily.

I changed the `nextFibonacciNumber` a bit. It now returns sum instead of state.0.

```Swift
typealias FibonacciSequence = UnfoldSequence<Int, (Int, Int)>

func fibonacci() -> FibonacciSequence
{
      let nextFibonacciNumber = {
          (state: inout (Int, Int)) -> Int? in

          let (sum, overflow) = Int.addWithOverflow(state.0, state.1)
          guard !overflow else { return nil }
          state = (state.1, sum)

          return sum
      }

      return sequence(state: (0, 1), next: nextFibonacciNumber)
}
```

If you print the sequence, it does not start with `0,1,1,2,...`. The first two elements are missing `1,2,3,5,...`. However, these two missing numbers can be easily added with `concat`:

```Swift
concat([0, 1], sequence(state: (0, 1), next: nextFibonacciNumber))
```

Now the sequence has 93 elements. So two more elements than before. And the `nextFibonacciNumber` function is still as simple as possible. There was no need to make it more difficult. Here is the code for the fibonacci sequence in total:

```Swift
typealias FibonacciSequenceTail = UnfoldSequence<Int, (Int, Int)>
typealias FibonacciSequence = ConcatSequence<Array<Int>, FibonacciSequenceTail>

func fibonacci() -> FibonacciSequence
{
    let nextFibonacciNumber = {
        (state: inout (Int, Int)) -> Int? in

        let (sum, overflow) = Int.addWithOverflow(state.0, state.1)
        guard !overflow else { return nil }
        state = (state.1, sum)

        return sum
    }

    concat([0, 1], sequence(state: (0, 1), next: nextFibonacciNumber))
}
```


## Lazy concat operator
Function `concat` is quite powerful. It is also able to concat three sequences lazily:

```Swift
let result = concat(concat(\[1, 2, 3], \[4, 5, 6]), [7, 8, 9])
```

However, the nested concat constructs is a bit hard to read. And will get worse with each sequence. How can this be improved? Well the definition of a "lazy concat"-operator would help. The following code defines the operator `<+>` which just calls concat and will have the same precedence as the standard `+`-operation.

```Swift
infix operator <+>: AdditionPrecedence
func <+><S: Sequence, T: Sequence where S.Iterator.Element==T.Iterator.Element>(lhs: S, rhs: T) -> ConcatSequence<S, T> {
    return concat(lhs, rhs)
}
```

It will be left associative. This means if you concat three sequences then the first two sequence (from left) will be concatenated first. 

```Swift
let result = [1, 2, 3] <+> [4, 5, 6] <+> [7, 8, 9]
```

The nested call disappeared. Remember, the `<+>`-operation does not really concatenate the sequences. It just creates another sequence that is able to iterate over the given sequences as if they were concatenated.
