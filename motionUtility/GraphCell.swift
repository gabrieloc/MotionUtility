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

  func visiblePoints(in rect: CGRect) -> [CGPoint] {
    let range = visibleRange(in: rect)
    return (range.startIndex..<range.endIndex).map { pointAtIndex($0, rect: rect) }
  }

  func visibleHistory(in rect: CGRect) -> [Double] {
    let range = visibleRange(in: rect)
    return Array(history[range.startIndex..<range.endIndex])
  }

  func visibleRange(in rect: CGRect) -> (startIndex: Int, endIndex: Int) {
    let maxVisible = Int(rect.width / columnWidth)
    let startIndex = max(0, history.count - maxVisible)
    return (startIndex, (min(startIndex + maxVisible, history.endIndex)))
  }

  func pointAtIndex(_ index: Int, rect: CGRect) -> CGPoint {
    let visible = visibleHistory(in: rect)

    let (min, max) = (visible.min()!, visible.max()!)
    let value = history[index]
    let maxVisible = Int(rect.width / columnWidth)
    let xOffset = CGFloat(history.count - maxVisible) * columnWidth
    let x = CGFloat(index) * columnWidth - Swift.max(0, xOffset)
    let y = rect.height - (rect.height * CGFloat(value - min) / CGFloat(max - min))

    let yInset: CGFloat = 2

    return CGPoint(
      x: x,
      y: Swift.max(yInset, Swift.min(rect.height - yInset, y))
    )
  }

  override func draw(_ rect: CGRect) {
    tintColor.set()
    let context = UIGraphicsGetCurrentContext()!
    let points = visiblePoints(in: rect)
    context.addLines(between: points)
    context.strokePath()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIViewNoIntrinsicMetric, height: 80)
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
