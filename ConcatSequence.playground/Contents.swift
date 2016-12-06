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

typealias ConcatSequence<S: Sequence, T: Sequence> = 
    UnfoldSequence<S.Iterator.Element, (S.Iterator, T.Iterator)>

func concat<S: Sequence, T: Sequence where S.Iterator.Element==T.Iterator.Element>(_ lhs: S, _ rhs: T) -> ConcatSequence<S, T>
{
    typealias Element = S.Iterator.Element
    let nextElement = {
        (state: inout (S.Iterator, T.Iterator)) -> Element? in
        return state.0.next() ?? state.1.next()
    }
    return sequence(state: (lhs.makeIterator(), rhs.makeIterator()), next: nextElement)
}

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
    
    return concat([0, 1], sequence(state: (0, 1), next: nextFibonacciNumber))
}

infix operator <+>: AdditionPrecedence
func <+><S: Sequence, T: Sequence where S.Iterator.Element==T.Iterator.Element>(lhs: S, rhs: T) -> ConcatSequence<S, T> {
    return concat(lhs, rhs)
}

let a = [20, 19, 18] <+> [-1] <+> fibonacci()
print(a)
print(Array(a))
