//
//  BoardView.swift
//  Enterprise
//
//  Created by Michael Burks on 6/28/18.
//  Copyright © 2018 Michael Burks. All rights reserved.
//

import UIKit

extension CGRect {
  init(center: CGPoint, radius: CGFloat) {
    self.init(x: center.x - radius,
              y: center.y - radius,
              width: 2 * radius,
              height: 2 * radius)
  }
}


class BoardView: UIView {
  let nodeRadius: CGFloat = 1.0
  let spacing: CGFloat = 8.0
  let margin: CGFloat = 4.0
  let ownerRadius: CGFloat = 2.5

  unowned let board: GameBoard

  init(board: GameBoard) {
    self.board = board

    let w = CGFloat(board.width + 1) * spacing
    let h = CGFloat(board.height + 1) * spacing
    super.init(frame: CGRect(x: 0, y: 0, width: w, height: h))

    self.backgroundColor = .white
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    for (x, col) in board.nodes.enumerated() {
      for (y, node) in col.enumerated() {
        let center = CGPoint(x: margin + CGFloat(x) * spacing,
                             y: margin + CGFloat(y) * spacing)
        let boundRect = CGRect(center: center, radius: nodeRadius)
        let nodePath = UIBezierPath(ovalIn:boundRect)

        UIColor.black.setFill()
        nodePath.fill()

        if let p = node.owner {
          let ownerRect = CGRect(center: center, radius: ownerRadius)
          let ownerPath = UIBezierPath(ovalIn: ownerRect)

          playerColor(id: p.id, count: board.players.count).setStroke()
          ownerPath.lineWidth = 2.0
          ownerPath.stroke()
        }
      }
    }
  }

  func playerColor(id: Int, count: Int) -> UIColor {
    let hue: CGFloat = (2.0 * CGFloat(id) + 1.0) / (2.0 * CGFloat(count))
    return UIColor.init(hue: hue, saturation: 0.3, brightness: 0.8, alpha: 1.0)
  }
}
