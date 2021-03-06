#!/usr/bin/swift
import Foundation

// MARK: Random Helpers

extension Int {
  static func rand(_ upperBound: Int) -> Int {
    return Int(arc4random_uniform(UInt32(upperBound)))
  }
}

extension Array {
  var rand: Element {
    get {
      let i = Int.rand(self.count)
      return self[i]
    }
  }
}

// MARK: Function Definition

protocol Function {
  func eval(_ input: Double) -> (Double)

  var length: Int { get }

  func prettyPrint() -> String

  func mutate() -> Function
  func mutableChildren() -> [Int]
  func mutateChild(_ index: Int) -> Function
}

protocol Deletable: Function {
  func delete() -> Function
}

extension Function {
  func mutate() -> Function {
    if let deletableSelf = self as? Deletable {
      if arc4random_uniform(3) == 0 {
        return deletableSelf.delete()
      }
    }
    
    let children = mutableChildren()
    let childWeight = 4
    let i = Int.rand(3 + children.count * childWeight)

    switch i {
      case 0:
        return UnaryOp.rand(self)
      case 1:
        return BinaryOp.rand(self, newLeaf())
      case 2:
        return BinaryOp.rand(newLeaf(), self)
      default:
        return mutateChild(children[(i - 3) / childWeight])
    }
  }

  func mutableChildren() -> [Int] {
    return []
  }

  func mutateChild(_ index: Int) -> Function {
    return self
  }

  func newLeaf() -> Function {
    if (arc4random_uniform(3) == 0) {
      return Input()
    } else {
      return Constant.rand
    }
  }
}

// MARK: Input Definition

class Input: Function {
  func eval(_ input: Double) -> (Double) {
    return input
  }

  var length: Int {
    get {
      return 1
    }
  }

  func prettyPrint() -> String {
    return "x"
  }
}

// MARK: Constant Definition

class Constant: Function {
  let c: Double

  init(_ initc: Double) {
    self.c = initc
  }

  func eval(_ input: Double) -> (Double) {
    return c
  }

  var length: Int {
    get {
      return 1
    }
  }

  func prettyPrint() -> String {
    return String(c)
  }

  func mutate() -> Function {
    return [Constant(c-1), Constant(c+1), Constant(c * 0.9), Constant(c * 1.1)].rand
  }

  class var rand: Constant {
    get {
      let z = Double(arc4random_uniform(21))
      return Constant(z-10)
    }
  }
}

// MARK: Unary Operation Definition

class UnaryOp: Function {
  let val: Function
  let op: (Double) -> Double
  let name: String

  init(_ initval: Function, _ initop: @escaping (Double) -> Double, _ initname: String) {
    self.val = initval
    self.op = initop
    self.name = initname
  }

  func eval(_ input: Double) -> (Double) {
    return op(val.eval(input))
  }

  var length: Int {
    get {
      return 1 + val.length
    }
  }

  func prettyPrint() -> String {
    return name + "(" + val.prettyPrint() + ")"
  }

  func mutableChildren() -> [Int] {
    return [0]
  }

  func mutateChild(_ index: Int) -> Function {
    return UnaryOp(val.mutate(), op, name)
  }
}

extension UnaryOp: Deletable {
  func delete() -> Function {
    return val
  }
}

// MARK: Binary Operation Definition

class BinaryOp: Function {
  let vals: [Function]
  let op: (Double, Double) -> Double
  let name: String

  init(_ initval1: Function, _ initval2: Function,
       _ initop: @escaping (Double, Double) -> Double, _ initname: String) {
    self.vals = [initval1, initval2]
    self.op = initop
    self.name = initname
  }

  func eval(_ input: Double) -> (Double) {
    return op(vals[0].eval(input), vals[1].eval(input))
  }

  var length: Int {
    get {
      return 1 + vals.reduce(0) {
        sum, val in sum + val.length
      }
    }
  }

  func prettyPrint() -> String {
    return "(" + vals[0].prettyPrint() + " " + name + " " + vals[1].prettyPrint() + ")"
  }

  func mutableChildren() -> [Int] {
    return [0,1]
  }

  func mutateChild(_ index: Int) -> Function {
    var newvals = vals
    newvals[index] = vals[index].mutate()

    return BinaryOp(newvals[0], newvals[1], op, name)
  }
}

extension BinaryOp: Deletable {
  func delete() -> Function {
    return vals.rand
  }
}

// MARK: Operations

extension UnaryOp {
  static func negate(_ val: Function) -> Self {
    return self.init(val, (-), "-")
  }

  static func square(_ val: Function) -> Self {
    let sq = { (x: Double) -> Double in return x * x }
    return self.init(val, sq, "square")
  }

  static func squareRoot(_ val: Function) -> Self {
    return self.init(val, sqrt, "sqrt")
  }

  static func naturalLog(_ val: Function) -> Self {
    return self.init(val, log, "ln")
  }

  static func exponential(_ val: Function) -> Self {
    return self.init(val, exp, "exp")
  }

  static func sine(_ val: Function) -> Self {
    return self.init(val, sin, "sin")
  }

  static func cosine(_ val: Function) -> Self {
    return self.init(val, cos, "cos")
  }

  static func tangent(_ val: Function) -> Self {
    return self.init(val, tan, "tan")
  }

  class var rand: (_ val: Function) -> UnaryOp {
    get {
      return [self.negate, self.square, self.squareRoot, self.naturalLog, self.exponential, self.sine, self.cosine, self.tangent].rand
    }
  }
}

extension BinaryOp {
  class func add(_ val1: Function, _ val2: Function) -> Self {
    return self.init(val1, val2, (+), "+")
  }

  class func subtract(_ val1: Function, _ val2: Function) -> Self {
    return self.init(val1, val2, (-), "-")
  }

  class func multiply(_ val1: Function, _ val2: Function) -> Self {
    return self.init(val1, val2, (*), "*")
  }

  class func divide(_ val1: Function, _ val2: Function) -> Self {
    return self.init(val1, val2, (/), "/")
  }

  class func power(_ val1: Function, _ val2: Function) -> Self {
    return self.init(val1, val2, pow, "^")
  }

  class var rand:(_ val1: Function, _ val2: Function) -> BinaryOp {
    get {
      return [self.add, self.subtract, self.multiply, self.divide, self.power].rand
    }
  }
}

// MARK: Training

typealias Heuristic = (Double) -> Double

func train(_ h: Heuristic) -> [Function] {
  let batchSize = 100
  let depth = 6
  let topCount = 60
  let siblingMax = 2

  // Prevent evolution from running to the point where all survivors might have a common ancestor.
  let maxGenerations = Int(log(Double(topCount)) / log(Double(siblingMax)))

  var best: [Function] = Array(repeating: Input(), count: topCount)

  var gen = 0
  var bestScore = Double.greatestFiniteMagnitude

  while gen < maxGenerations && bestScore > 0.0 {
    print("Generation", gen)

    // TODO: Sex

    // Store child functions with index of parent.
    var pool = [(Function, Int)]()

    for _ in 0..<batchSize {
      for (idx, j) in best.enumerated() {
        pool.append((j, idx))
        var z = j
        for _ in 0..<depth {
          // Add mutant children.
          z = z.mutate()
          pool.append((z, idx))
        }
      }
    }

    best = bestPerformers(in: pool, h, count: topCount, siblingMax: siblingMax)
    bestScore = score(best[0], h)
    print("Best score:", bestScore)
    gen += 1
  }
  print("Finished training after", gen, "generations.")

  return best
}

// Select most viable children from pool.
func bestPerformers(in pool:[(Function, Int)], _ h: Heuristic, count: Int, siblingMax: Int) -> [Function] {

  // [(Function, Parent Index, Score)]
  var scores = [(Function, Int, Double)]()

  for (f, i) in pool {
    let sc = score(f, h)
    scores.append((f, i, sc))
  }

  scores.sort { (s1:(Function, Int, Double), s2:(Function, Int, Double)) -> Bool in
    // If same score, order by function length.
    if s1.2 == s2.2 {
      return s1.0.length < s2.0.length
    }
    return s1.2 < s2.2
  }

  var best = [Function]()
  var bestScores = [Double]()
  var bestParents = [Int]()

  var idx = 0
  while best.count < count && idx < scores.count {
    let (f, p, s) = scores[idx]
    let survivingSiblings = bestParents.filter { $0 == p }.count

    // Limit number of survivors from a single parent to promote function diversity.
    if !bestScores.contains(s) && survivingSiblings < siblingMax {
      bestScores.append(s)
      bestParents.append(p)
      best.append(f)
    }
    idx += 1
  }

  return best
}

// Score function againt the heuristic.
func score(_ f: Function, _ h: Heuristic) -> Double {
  var sc = 0.0

  // Compute the sum of square of differences for inputs 0 to 99.
  for x in 0..<100 {
    let y = f.eval(Double(x))
    let z = h(Double(x))

    let diff = z - y
    sc += diff * diff
  }

  // Weight the score by the length of the function to encourage simplicity.
  return sc * log(Double(f.length) + 4.0)
}

// This is the function to learn.
func goal(_ x: Double) -> Double {
  return x * x * x + 4 * sin(x)
}

let top = train(goal)
for (i, f) in top.enumerated() {
  print(f.prettyPrint() + ":", score(f, goal))
  if i >= 5 {
    break
  }
}
