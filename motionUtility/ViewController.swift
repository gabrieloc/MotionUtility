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
    case config = "Config"
    case location = "Location"
    case accelerometer = "Accelerometer"
    case gyro = "Gyroscope"
    case motion = "Device Motion"

    static let all: [Section] = [.config, .location, .accelerometer, .gyro, .motion]
  }

  let updateInterval: TimeInterval = 1.0/60.0
  let locationManager = CLLocationManager()
  let motionManager = CMMotionManager()

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.showsUserLocation = true

    locationManager.desiredAccuracy = currentOption.accuracy
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

    tableView.reloadData()
  }

  var currentOption: LocationConfigOption = .best {
    didSet {
      tableView.reloadSections([0], with: .none)
      locationManager.stopUpdatingLocation()
      locationManager.desiredAccuracy = currentOption.accuracy
      locationManager.startUpdatingLocation()
    }
  }

  enum LocationConfigOption: String {
    case bestForNavigation, best, tenMeters, hundredMeters, kilometer, threeKilometers
    static let all: [LocationConfigOption] = [.bestForNavigation, .best, .tenMeters, .hundredMeters, .kilometer, .threeKilometers]

    var displayValue: String {
      return rawValue.unicodeScalars.reduce("") {
        if CharacterSet.uppercaseLetters.contains($1), $0.characters.count > 0 {
          return ($0 + " " + String($1))
        }
        return $0 + String($1)
      }.capitalized
    }

    var accuracy: CLLocationAccuracy {
      switch self {
      case .bestForNavigation: return kCLLocationAccuracyBestForNavigation
      case .best: return kCLLocationAccuracyBest
      case .tenMeters: return kCLLocationAccuracyNearestTenMeters
      case .hundredMeters: return kCLLocationAccuracyHundredMeters
      case .kilometer: return kCLLocationAccuracyKilometer
      case .threeKilometers: return kCLLocationAccuracyThreeKilometers
      }
    }
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

  let dateFormatter = DateFormatter()

  func onTick(_ timer: Timer) {
    var newParams = [Section: [Param]]()

    if let lastLocation = locationManager.location {
      logHistory(for: "Altitude", lastLocation.altitude)
      logHistory(for: "Speed", lastLocation.speed)
      logHistory(for: "Course", lastLocation.course)

      newParams[.location] = [
        ("Coordinates", lastLocation.coordinate.description),
        ("Altitude", "\(lastLocation.altitude)"),
        ("Speed", "\(lastLocation.speed)"),
        ("Course", "\(lastLocation.course)"),
        ("Timestamp", "\(lastLocation.timestamp)"),
      ]

      if let floor = lastLocation.floor {
        logHistory(for: "Floor", Double(floor.level))
        newParams[.location]?.append(("Floor", "\(floor.level)"))
      }
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

      logHistory(for: "Attitude roll", attitude.roll)
      logHistory(for: "Attitude pitch", attitude.pitch)
      logHistory(for: "Attitude yaw", attitude.yaw)

      var deviceMotionParams: [Param] = [
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
      ]

      if #available(iOS 11.0, *) {
        let heading = deviceMotion.heading
        deviceMotionParams.append(("Heading", "\(heading)"))
      }

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

  func paramForIndexPath(_ indexPath: IndexPath) -> Param? {
    guard let section = sectionForIndex(indexPath.section),
      let params = self.params[section],
      params.count > indexPath.row else {
        return nil
    }
    return params[indexPath.row]
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionForIndex(section)?.rawValue
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return Section.all.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let section = sectionForIndex(section) else {
      return 0
    }

    if section == .config {
      return LocationConfigOption.all.count
    }

    guard let params = self.params[section] else {
      return 0
    }

    return params.count
  }

  func heightForRow(at indexPath: IndexPath) -> CGFloat {
    if sectionForIndex(indexPath.section) == .config {
      return 44
    }

    guard let param = paramForIndexPath(indexPath),
      historyForParam(param.name) != nil else {
        return 44
    }
    return 120
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return heightForRow(at: indexPath)
  }

  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return heightForRow(at: indexPath)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    if sectionForIndex(indexPath.section) == .config {
      let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigCell")!
      let configOption = LocationConfigOption.all[indexPath.row]
      cell.textLabel?.text = configOption.displayValue
      cell.accessoryType = currentOption == configOption ? .checkmark: .none
      return cell
    }

    let param = paramForIndexPath(indexPath)!
    let cell = tableView.dequeueReusableCell(withIdentifier: "GraphCell") as! GraphCell
    cell.textLabel?.text = param.name
    cell.detailTextLabel?.text = param.value
    cell.history = historyForParam(param.name)

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let section = sectionForIndex(indexPath.section) else {
      return
    }

    if section == .config {
      currentOption = LocationConfigOption.all[indexPath.row]
      return
    }

    guard let param = params[section]?[indexPath.row] else {
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
