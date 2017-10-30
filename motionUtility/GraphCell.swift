//
//  GraphCell.swift
//  motionUtility
//
//  Created by Gabriel O'Flaherty-Chan on 2017-10-30.
//  Copyright © 2017 gabrieloc. All rights reserved.
//

import UIKit

class Graph: UIView {
  private var history = [Double]()
  let columnWidth: CGFloat = 2.0

  func drawHistory(_ history: [Double]) {
    self.history = history
    setNeedsDisplay()
  }

  func pointAtIndex(_ index: Int, rect: CGRect) -> CGPoint {
    let (min, max) = (history.min()!, history.max()!)
    let safeRect = rect.insetBy(dx: 0, dy: 4)
    let value = history[index]
    let maxVisible = Int(rect.width / columnWidth)
    let x = CGFloat(index) * columnWidth
    let offsetX = x - Swift.max(0, CGFloat(history.count - maxVisible) * columnWidth)
    return CGPoint(
      x: offsetX,
      y: safeRect.height * CGFloat(value - min) / CGFloat(max - min)
    )
  }

  override func draw(_ rect: CGRect) {
    tintColor.set()
    let context = UIGraphicsGetCurrentContext()!
    let points = (0..<history.count).map { pointAtIndex($0, rect: rect) }
    let maxVisible = Int(rect.width / columnWidth)
    var visiblePoints = points
    if points.count > maxVisible {
      let startIndex = points.count - maxVisible
      visiblePoints = Array(points[startIndex ..< points.endIndex])
    }
    context.addLines(between: visiblePoints)
    context.strokePath()
  }
}

class GraphCell: UITableViewCell {

  @IBOutlet weak var _textLabel: UILabel!
  @IBOutlet weak var _detailLabel: UILabel!
  @IBOutlet weak var graph: Graph!

  var history: [Double]? {
    didSet {
      if let history = history {
        graph.drawHistory(history)
      }
      graph.isHidden = history == nil
    }
  }

  override var textLabel: UILabel? { get { return _textLabel }}
  override var detailTextLabel: UILabel? { get { return _detailLabel }}

  override func prepareForReuse() {
    super.prepareForReuse()

    textLabel?.text = nil
    detailTextLabel?.text = nil
    history = nil
  }
}
