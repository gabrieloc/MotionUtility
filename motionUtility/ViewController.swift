//
//  ViewController.swift
//  motionUtility
//
//  Created by Gabriel O'Flaherty-Chan on 2017-10-30.
//  Copyright © 2017 gabrieloc. All rights reserved.
//

import UIKit
import MapKit
import CoreMotion

protocol Vector3 {
  var x: Double { get }
  var y: Double { get }
  var z: Double { get }
}
extension Vector3 {
  var description: String {
    return String(format: "x: %.2f y: %.2f z: %.2f", x, y, z)
  }
}

extension CMAcceleration: Vector3 { }
extension CMRotationRate: Vector3 { }
extension CMMagneticField: Vector3 { }
extension CMQuaternion {
  var description: String {
    return String(format: "x: %.2f y: %.2f z: %.2f w: %.2f", x, y, z, w)
  }
}
extension CLLocationCoordinate2D {
  var description: String {
    return String(format: "lat: %.4f lng: %.4f", latitude, longitude)
  }
}

class ViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var tableView: UITableView!

  typealias Param = (name: String, value: String?)
  var params = [Section: [Param]]()

  enum Section: String {
    case location = "Location"
    case accelerometer = "Accelerometer"
    case gyro = "Gyroscope"
    case motion = "Device Motion"

    static let all: [Section] = [.location, .accelerometer, .gyro, .motion]
  }

  let updateInterval: TimeInterval = 1.0/10.0
  let locationManager = CLLocationManager()
  let motionManager = CMMotionManager()

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.showsUserLocation = true

    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()

    let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: onTick)
    timer.fire()
    motionManager.accelerometerUpdateInterval = updateInterval
    motionManager.startAccelerometerUpdates()
    motionManager.startGyroUpdates()
    motionManager.startDeviceMotionUpdates()
    motionManager.startMagnetometerUpdates()

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.reloadData()
  }

  var history = [String: [Double]]()

  func logHistory(for param: String, _ value: Double) {
    if history[param] == nil {
      history[param] = [Double]()
    }
    history[param]!.append(value)
  }

  func historyForParam(_ name: String) -> [Double]? {
    return history[name]
  }

  func onTick(_ timer: Timer) {
    var newParams = [Section: [Param]]()

    if let lastLocation = locationManager.location {
      logHistory(for: "Altitude", lastLocation.altitude)
      newParams[.location] = [
        ("Coordinates", lastLocation.coordinate.description),
        ("Altitude", "\(lastLocation.altitude)")
      ]
    }

    if let accelerometerData = motionManager.accelerometerData {
      let a = accelerometerData.acceleration
      newParams[.accelerometer] = [
        ("Acceleration", a.description)
      ]
    }

    if let gyroData = motionManager.gyroData {
      newParams[.gyro] = [
        ("Gyro", gyroData.rotationRate.description)
      ]
    }

    if let deviceMotion = motionManager.deviceMotion {
      let attitude = deviceMotion.attitude
      let mag = deviceMotion.magneticField
      let heading = deviceMotion.heading

      logHistory(for: "Attitude roll", attitude.roll)
      logHistory(for: "Attitude pitch", attitude.pitch)
      logHistory(for: "Attitude yaw", attitude.yaw)

      let deviceMotionParams: [Param] = [
        ("Attitude roll", "\(attitude.roll)"),
        ("Attitude pitch", "\(attitude.pitch)"),
        ("Attitude yaw", "\(attitude.yaw)"),
//        ("Attitude rotation mat4", "\(attitude.rotationMatrix)"),
        ("Attitude quaternion", "\(attitude.quaternion.description)"),

        ("Rotation rate", deviceMotion.rotationRate.description),
        ("Gravity", deviceMotion.gravity.description),
        ("User acceleration", deviceMotion.userAcceleration.description),

        ("Mag field", mag.field.description),
//        ("Mag accuracy", "\(mag.accuracy.rawValue)"),

        ("Heading", "\(heading)")
      ]

      newParams[.motion] = deviceMotionParams
    }

    params = newParams
    tableView.reloadData()
  }

  func indexForSection(_ section: Section) -> Int {
    let sections = Section.all
    return sections.index(of: section)!
  }

  func sectionForIndex(_ section: Int) -> Section? {
    let sections = Section.all
    guard sections.count > section else {
      return nil
    }
    return sections[section]
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionForIndex(section)?.rawValue
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return Section.all.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard
      let section = sectionForIndex(section),
      let params = self.params[section] else {
        return 0
    }
    return params.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! GraphCell

    if let section = sectionForIndex(indexPath.section),
      let paramGroup = params[section],
      paramGroup.count > indexPath.row {

      let param = paramGroup[indexPath.row]
      cell.textLabel?.text = param.name
      cell.detailTextLabel?.text = param.value
      cell.history = historyForParam(param.name)
    } else {
      cell.textLabel?.text = "No data"
      cell.detailTextLabel?.text = nil
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let section = sectionForIndex(indexPath.section), let param = params[section]?[indexPath.row] else {
      return
    }
    let alert = UIAlertController(title: param.name, message: param.value, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
    present(alert, animated: true, completion: nil)
  }

  func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    let camera = MKMapCamera(
      lookingAtCenter: userLocation.coordinate,
      fromDistance: 200,
      pitch: 15,
      heading: 0
    )
    mapView.setCamera(camera, animated: true)
  }
}
