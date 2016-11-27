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

// Functions sums up all digits for integer n
func crossSum(_ n: Int) -> Int {
    return digitsOf(n).reduce(0, +)
}

// Functions prints all digits for integer n
func printAllDigits(_ n: Int) {
    for digit in digitsOf(n) {
        print(digit)
    }
}

// Fibonacci Sequence
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

