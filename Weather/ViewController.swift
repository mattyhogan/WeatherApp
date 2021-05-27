//
//  ViewController.swift
//  Weather
//
//  Created by Matthew Volpe Hogan on 5/27/21.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet var table: UITableView!
    
    var models = [Daily]()
    var hourlyModels = [Hourly]()
    
    var API_KEY = "9d6294f0c654f07c314fa2075d57b24b"
    
    let locationManager = CLLocationManager()
    
    let appColor = UIColor(red: 128/255, green: 232/255, blue: 255/255, alpha: 1.0)
    
    var currentLocation: CLLocation?
    
    var current: CurrentWeather?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register 2 cells
        table.register(HourlyTableViewCell.nib(), forCellReuseIdentifier: HourlyTableViewCell.identifier)
        table.register(WeatherTableViewCell.nib(), forCellReuseIdentifier: WeatherTableViewCell.identifier)
        
        
        table.delegate = self
        table.dataSource = self
        
        table.backgroundColor = appColor
        view.backgroundColor = appColor
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLocation()
    }
    
    // Location

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currentLocation == nil {
            currentLocation = locations.first
            locationManager.stopUpdatingLocation()
            requestWeatherForLocation()
        }
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestWeatherForLocation() {
        guard let currentLocation = currentLocation else {
            return
        }
        let long = currentLocation.coordinate.longitude
        let lat = currentLocation.coordinate.latitude
        let endpoint = "https://api.openweathermap.org/data/2.5/onecall?lat=\(lat)&lon=\(long)&exclude=alerts,minutely&units=imperial&appid=\(API_KEY)"
        
        URLSession.shared.dataTask(with: URL(string: endpoint)!, completionHandler: { data, response, error in
            
            // Validation
            guard let data = data, error == nil else {
                print("Something went wrong")
                return
            }

            // Convert data to models
            var json: WeatherResponse?
            
            do {
                json = try JSONDecoder().decode(WeatherResponse.self, from: data)
                print("Successfully decoded json")
            } catch {
                print("Failed to decode: \(error)")
            }
            
            guard let result = json else {
                return
            }
            
            let entries = result.daily
            self.models.append(contentsOf: entries)
            
            let current = result.current
            self.current = current
            self.hourlyModels = result.hourly
            
            // Update user interface
            DispatchQueue.main.async {
                self.table.reloadData()
                
                self.table.tableHeaderView = self.createTableHeader()
            }
            
        }).resume()
    }
    
    func createTableHeader() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width-(view.frame.size.width/3)))
        view.backgroundColor = appColor
        
        let locationLabel = UILabel(frame: CGRect(x: 10, y: 10, width: view.frame.size.width-20, height: view.frame.size.height/5))
        let summaryLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height, width: view.frame.size.width-20, height: view.frame.size.height/5))
        let tempLabel = UILabel(frame: CGRect(x: 10, y: 20+summaryLabel.frame.size.height, width: view.frame.size.width-20, height: view.frame.size.height/2))
        
        view.addSubview(locationLabel)
        view.addSubview(summaryLabel)
        view.addSubview(tempLabel)
        
        tempLabel.textAlignment = .center
        locationLabel.textAlignment = .center
        summaryLabel.textAlignment = .center
        
        guard let current = self.current else {
            return UIView()
        }
        
        locationLabel.text = "Current Location"
        tempLabel.text = "\(Int(current.temp))"
        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        summaryLabel.text = current.weather[0].description.uppercased()
        
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return models.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: HourlyTableViewCell.identifier, for: indexPath) as! HourlyTableViewCell
            cell.configure(with: hourlyModels)
            cell.backgroundColor = appColor
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: WeatherTableViewCell.identifier, for: indexPath) as! WeatherTableViewCell
        cell.configure(with: models[indexPath.row])
        cell.backgroundColor = appColor
        return cell
    }

}

struct WeatherResponse: Codable {
    let lat: Float
    let lon: Float
    let timezone: String
    let timezone_offset: Int
    let current: CurrentWeather
    let hourly: [Hourly]
    let daily: [Daily]
}

struct CurrentWeather: Codable {
    let dt: Int
    let sunrise: Int
    let sunset: Int
    let temp: Double
    let feels_like: Double
    let pressure: Int
    let humidity: Int
    let dew_point: Double
    let clouds: Int
    let uvi: Float
    let visibility: Int
    let wind_speed: Float
    let wind_deg: Int
    let weather: [Weather]
//    let rain: Rain
//    let snow: Snow
}

struct Rain: Codable {
    let h: Double
}

struct Snow: Codable {
    let h: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Hourly: Codable {
    let dt: Int
    let temp: Double
    let feels_like: Double
    let pressure: Int
    let humidity: Int
    let dew_point: Double
    let uvi: Float
    let clouds: Int
    let visibility: Int
    let wind_speed: Double
    let wind_deg: Int
    let wind_gust: Double
    let weather: [Weather]
    let pop: Float
}

struct Daily: Codable {
    let dt: Int
    let sunrise: Int
    let moonrise: Int
    let moonset: Int
    let moon_phase: Double
    let temp: Temp
    let feels_like: FeelsLike
    let pressure: Int
    let humidity: Int
    let dew_point: Float
    let wind_speed: Float
    let wind_deg: Int
    let weather: [Weather]
    let clouds: Int
    let pop: Float
//    let rain: Float
    let uvi: Float
}

struct Temp: Codable {
    let day: Float
    let min: Float
    let max: Float
    let night: Float
    let eve: Float
    let morn: Float
}

struct FeelsLike: Codable {
    let day: Float
    let night: Float
    let eve: Float
    let morn: Float
}
