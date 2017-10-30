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

class ViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var tableView: UITableView!

  typealias Param = (name: String, value: String?)
  var params = [[Param]]()

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

    tableView.reloadData()
  }

  func onTick(_ timer: Timer) {
    var newParams = [[Param]]()

    if let accelerometerData = motionManager.accelerometerData {
      let a = accelerometerData.acceleration
      let acceleration = "x: \(a.x), y: \(a.y), z: \(a.z)"
      newParams += [[("Acceleration", acceleration)]]
    }

    if let gyroData = motionManager.gyroData {
      let g = gyroData.rotationRate
      let rotation = "x: \(g.x), y: \(g.y), z: \(g.z)"
      newParams += [[("Gyro", rotation)]]
    }

    if let deviceMotion = motionManager.deviceMotion {
      var deviceMotionParams = [Param]()
      let attitude = deviceMotion.attitude
      deviceMotionParams.append(("Attitude roll", "\(attitude.roll)"))
      deviceMotionParams.append(("Attitude pitch", "\(attitude.pitch)"))
      deviceMotionParams.append(("Attitude yaw", "\(attitude.yaw)"))
      deviceMotionParams.append(("Attitude rotation mat4", "\(attitude.rotationMatrix)"))
      deviceMotionParams.append(("Attitude quaternion", "\(attitude.quaternion)"))

      let r = deviceMotion.rotationRate
      let rotRate = "x: \(r.x), y: \(r.y), z: \(r.z)"
      deviceMotionParams.append(("Rotation rate", rotRate))

      let g = deviceMotion.gravity
      let gravity = "x: \(g.x), y: \(g.y), z: \(g.z)"
      deviceMotionParams.append(("Gravity", gravity))

      let a = deviceMotion.userAcceleration
      let userAcceleration = "x: \(a.x), y: \(a.y), z: \(a.z)"
      deviceMotionParams.append(("User acceleration", userAcceleration))

      let mag = deviceMotion.magneticField
      let f = mag.field
      let magField = "x: \(f.x), y: \(f.y), z: \(f.z)"
      deviceMotionParams.append(("Magnetic field", magField))

      let acc = mag.accuracy
      deviceMotionParams.append(("Magnetic field accuracy", "\(acc)"))

      let heading = deviceMotion.heading
      deviceMotionParams.append(("Heading", "\(heading)"))

      newParams += [deviceMotionParams]
    }

    params = newParams
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "Accelerometer"
    case 1: return "Gyroscope"
    case 2: return "Device Motion"
    default: return nil
    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return params.count > section ? max(1, params[section].count) : 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var _cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
    if _cell == nil {
      _cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
    }
    let cell = _cell!
    let paramGroup = params[indexPath.section]
    if paramGroup.count > indexPath.row {
      let param = paramGroup[indexPath.row]
      cell.textLabel?.text = param.name
      cell.detailTextLabel?.text = param.value
    } else {
      cell.textLabel?.text = "No data"
      cell.detailTextLabel?.text = nil
    }
    return cell
  }

  func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    let camera = MKMapCamera(
      lookingAtCenter: userLocation.coordinate,
      fromDistance: 70,
      pitch: 0,
      heading: 0
    )
    mapView.setCamera(camera, animated: true)
  }
}
