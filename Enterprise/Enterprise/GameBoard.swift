//
//  GameBoard.swift
//  Enterprise
//
//  Created by Michael Burks on 6/28/18.
//  Copyright © 2018 Michael Burks. All rights reserved.
//

import Foundation

class Constants {
  static let baseNodeCost: Int = 100
  static let leaseLength: Int = 5
  static let tileValue: Int = 100

  static let startingWealth = 500
}

protocol PlayerManager: class {
  func wealth(for player: Player) -> Int
  func realEstate(for player: Player) -> [RealEstate]
}

protocol RealEstate: class {
  var owner: Player? { get }
  var leaseRemaining: Int { get }
}

class Player {
  let id: Int
  unowned let manager: PlayerManager

  init(id: Int, manager: PlayerManager) {
    self.id = id
    self.manager = manager
  }

  func makeBids(area: [RealEstate], availableWealth: Int) -> [(RealEstate, Int)] {
    var spending = 0
    var areaIndex = 0
    var bids = [(RealEstate, Int)]()

    while spending <= availableWealth - Constants.tileValue && areaIndex < area.count {
      let r = area[areaIndex]
      if r.owner == nil {
        let bidAmount = Constants.tileValue
        spending += bidAmount
        bids.append((r, bidAmount))
      }

      areaIndex += 1
    }
    return bids
  }
}

extension Player: Hashable {
  public static func == (lhs: Player, rhs: Player) -> Bool {
    return lhs.id == rhs.id
  }

  var hashValue: Int {
    get {
      return self.id
    }
  }
}

class Node: RealEstate {
  let x: Int
  let y: Int

  weak var owner: Player? = nil
  var leaseRemaining: Int = 0

  init(x: Int, y: Int) {
    self.x = x
    self.y = y
  }

  var isOwned: Bool {
    get {
      return self.owner != nil
    }
  }

  func purchase(_ p: Player) {
    self.owner = p
    self.leaseRemaining = Constants.leaseLength
  }

  func age() {
    if self.leaseRemaining > 0 {
      self.leaseRemaining -= 1
      if self.leaseRemaining == 0 {
        self.owner = nil
      }
    }
  }
}

extension Node: Hashable {
  static func == (lhs: Node, rhs: Node) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  var hashValue: Int {
    get {
      return x * 1000 + y
    }
  }
}

class Tile {
  unowned let ul: Node  // upper left
  unowned let ur: Node  // upper right
  unowned let bl: Node  // bottom left
  unowned let br: Node  // bottom right

  var nodes: [Node] {
    get {
      return [ul, ur, bl, br]
    }
  }

  init(nodes: (Node, Node, Node, Node)) {
    self.ul = nodes.0
    self.ur = nodes.1
    self.bl = nodes.2
    self.br = nodes.3
  }

  func score() -> (Player, Int)? {
    var counts = [Player: Int]()

    for node in nodes {
      if let p = node.owner {
        if let count = counts[p] {
          counts[p] = count + 1
        } else {
          counts[p] = 1
        }
      }
    }

    for (p, c) in counts {
      if c == 4 {
        return (p, Constants.tileValue)
      } else if c == 3 {
        return (p, Constants.tileValue / 2)
      }
    }

    return nil
  }
}

class GameBoard {
  let width: Int
  let height: Int

  let nodes: [[Node]]
  let tiles: [Tile]

  let players: [Player]

  var bank: [Player: Int]
  var realEstate: [Player: Set<Node>]

  let manager = GameManager()

  init(playerCount: Int = 5, width: Int = 100, height: Int = 100) {
    self.width = width
    self.height = height

    var makeNodes = [[Node]]()
    for x in 0...width {
      var column = [Node]()
      for y in 0...height {
        column.append(Node(x: x, y: y))
      }
      makeNodes.append(column)
    }

    self.nodes = makeNodes

    var makeTiles = [Tile]()
    for x in 0..<width {
      for y in 0..<height {
        makeTiles.append(Tile(nodes: (nodes[x][y],
                                      nodes[x+1][y],
                                      nodes[x][y+1],
                                      nodes[x+1][y+1])))
      }
    }
    self.tiles = makeTiles

    var makePlayers = [Player]()
    var makeBank = [Player: Int]()
    var makeRealEstate = [Player:Set<Node>]()

    for i in 0..<playerCount {
      let p = Player(id: i, manager: self.manager)
      makePlayers.append(p)
      makeBank[p] = Constants.startingWealth
      makeRealEstate[p] = Set<Node>()
    }

    self.players = makePlayers
    self.bank = makeBank
    self.realEstate = makeRealEstate

    manager.game = self
    self.startPlayers()
  }
}

// MARK: manager

class GameManager: PlayerManager {
  weak var game: GameBoard?

  init() {
    self.game = nil
  }

  func wealth(for player: Player) -> Int {
    guard let g = game else { return 0 }
    return g.bank[player]!
  }

  func realEstate(for player: Player) -> [RealEstate] {
    guard let g = game else { return [] }
    return Array(g.realEstate[player]!)
  }
}

// MARK: setup

extension GameBoard {
  func startPlayers() {
    for p in players {
      var placed = false

      while !placed {
        let x = Int(arc4random_uniform(UInt32(width-1))) + 1
        let y = Int(arc4random_uniform(UInt32(height-1))) + 1

        let startNodes = [nodes[x][y-1],
          nodes[x-1][y],  nodes[x][y],   nodes[x+1][y],
                          nodes[x][y+1]]

        placed = startNodes.reduce(true) { (acc, n) -> Bool in
          return acc && !n.isOwned
        }

        if (!placed) { continue }

        for node in startNodes {
          _ = purchase(node, player: p, value: Constants.tileValue)
        }
      }
    }
  }
}

// MARK: game play

extension GameBoard {

  func update() {
    // harvest and add to bank
    let gains = harvest()

    for p in players {
      let currentWealth = bank[p]!
      bank[p] = currentWealth + gains[p]!
    }

    // increment time on each node
    for nodeCol in nodes {
      for node in nodeCol {
        if let owner = node.owner {
          if node.leaseRemaining <= 1 {
            realEstate[owner]?.remove(node)
          }
        }
        node.age()
      }
    }

    // collect bids
    let bids = players.reduce([Node: [(Player, Int)]](), { (result, player) -> [Node: [(Player, Int)]] in
      var r = result
      let playerBids = player.makeBids(area: visibleRealEstate(for: player), availableWealth: bank[player]!)
      for (re, bid) in playerBids {
        let node = re as! Node
        var nodeBids = [(player, bid)]
        if let existingBids = result[node] {
          nodeBids.append(contentsOf: existingBids)
        }

        r[node] = nodeBids
      }

      return r
    })

    // process bids and award property to highest bidder
    for (node, nodeBids) in bids {
      let maxBid = nodeBids.reduce(nodeBids[0]) { (prevBest, bid) -> (Player, Int) in
        if bid.1 > prevBest.1 {
          return bid
        } else {
          return prevBest
        }
      }
      _ = purchase(node, player: maxBid.0, value: maxBid.1)
    }
  }

  func purchase(_ node: Node, player: Player, value: Int) -> Bool {
    if node.isOwned {
      return false
    }

    let availableWealth = bank[player]!
    if availableWealth < value {
      return false
    }

    bank[player] = availableWealth - value
    realEstate[player]?.insert(node)
    node.purchase(player)

    return true
  }

  func harvest() -> [Player: Int] {
    // collect score for each player
    var scores = [Player: Int]()
    for p in players {
      scores[p] = 0
    }

    for tile in tiles {
      if let (p, s) = tile.score() {
        scores[p] = s + scores[p]!
      }
    }

    return scores
  }

  func visibleRealEstate(for player: Player) -> [RealEstate] {
    // return properties and neighbors of player
    var areaSet = Set<Node>()
    for node in realEstate[player]! {
      let xMin = max(node.x - 1, 0)
      let xMax = min(node.x + 1, width)
      let yMin = max(node.y - 1, 0)
      let yMax = min(node.y + 1, height)

      for x in xMin...xMax {
        for y in yMin...yMax {
          areaSet.insert(nodes[x][y])
        }
      }
    }

    return Array(areaSet)
  }
}
