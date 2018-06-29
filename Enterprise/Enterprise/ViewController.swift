//
//  ViewController.swift
//  Enterprise
//
//  Created by Michael Burks on 6/28/18.
//  Copyright © 2018 Michael Burks. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  var game: GameBoard? = nil
  var boardView: BoardView? = nil
  let resetButton: UIButton

  var gameCount: Int = 0

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.resetButton = UIButton(type: .custom)
    resetButton.setTitle("Reset", for: .normal)

    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    self.resetButton = UIButton(type: .custom)
    resetButton.setTitle("Reset", for: .normal)
    resetButton.setTitleColor(.black, for: .normal)

    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.backgroundColor = .white

    resetButton.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(resetButton)
    resetButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    resetButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -5).isActive = true
    resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @objc func reset() {
    self.boardView?.removeFromSuperview()
    gameCount += 1

    self.game = GameBoard(playerCount: 8, width: 40, height: 60)
    self.boardView = BoardView(board: self.game!)
    self.boardView!.center = self.view.center
    self.view.addSubview(self.boardView!)

    self.runGame()
  }

  func runGame() {
    self.game?.update()
    boardView?.setNeedsDisplay()

    let gid = gameCount
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if gid == self.gameCount {
        self.runGame()
      }
    }
  }
}

