/*
 MIT License

 Copyright (c) 2016 Patrick Sturm

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation

// This function creates a lazy sequence of digits for integer n
func digitsOf(_ n: Int) -> UnfoldSequence<Int, Int?> {
    let nextDigit = {
        (state: inout Int?) -> Int? in
        
        guard let n = state else { return nil }
        state = (n < 10) ? nil : n / 10
        return n % 10
    }
    return sequence(state: n, next: nextDigit)
}

// Functions sums up all digits for integer n
func crossSum(_ n: Int) -> Int {
    return digitsOf(n).reduce(0, +)
}

// Functions prints all digits for integer n
func printAllDigits(_ n: Int) {
    digitsOf(n).forEach { n in print(n) }
}

// Fibonacci Sequence
typealias FibonacciSequence = UnfoldSequence<Int, (Int, Int)>
func fibonacci() -> FibonacciSequence {
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

typealias LeibnizSequence = UnfoldSequence<Double, (Double, Double)>

func leibnizSequence() -> LeibnizSequence {
    let leibnizStep = {
        (state: inout (Double, Double)) -> Double? in
        let (k, sum) = state
        state = (k + 1.0, sum + pow(-1.0, k) / (2 * k + 1))
        return 4.0 * state.1
    }
    
    return sequence(state: (0.0, 0.0), next: leibnizStep)
}

print(Array(digitsOf(1234)))
print(Array(digitsOf(4)))
print(Array(digitsOf(0)))

