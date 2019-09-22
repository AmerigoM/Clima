//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON


class WeatherViewController: UIViewController, CLLocationManagerDelegate,  ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "985a96abb23a0395be86d99635ac1e4f"
    

    //TODO: Declare instance variables here
    var locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    @IBOutlet weak var changeTempFormat: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setting the switch: at the beginning weather is in Degrees
        changeTempFormat.setOn(true, animated: true)
        // bind the switch with the function switchTarget
        changeTempFormat.addTarget(self, action: #selector(switchTarget(sender:)), for: .valueChanged)
        
        // set up the location manager here.
        locationManager.delegate = self
        // accuracy of the GPS
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // request authorization to the user to use GPS
        locationManager.requestWhenInUseAuthorization()
        // the location manager starts looking at the GPS coordinate of the iPhone
        locationManager.startUpdatingLocation()
        
        
    }
    
    
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(url: String, parameters: [String : String]) {
        
        // http request to the server
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON() {
            response in
            if response.result.isSuccess {
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            }
            else {
                self.cityLabel.text = "Connection issues"
            }
        }
        
    }

    
    
    
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    func updateWeatherData(json : JSON) {
        
        if let tempResult = json["main"]["temp"].double {
            //weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.temperature = Int(tempResult)
            
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
        }
        else {
            cityLabel.text = "Weather unavailable"
        }
    }

    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    func updateUIWithWeatherData() {
        cityLabel.text = weatherDataModel.city
        
        if changeTempFormat.isOn {
            temperatureLabel.text = String(Int(Double(weatherDataModel.temperature) - 273.15)) + "°"
        }
        else {
            temperatureLabel.text = String(weatherDataModel.temperature) + " K"
        }

        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        
    }
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // it gets activated when the locationMangaer has found a location
        
        /**
         * locations is an array containing all the locations found and every time a new location is retrieved,
         * it is added to the array of locations: the most accurate one will be then the last one and the oldest
         * one the fist one
         */
        let location = locations[locations.count - 1]
        
        // make sure that the value we get back is not invalid: the horizontal accuracy is the circle accuracy
        // of the GPS where the position of the user was located
        if location.horizontalAccuracy > 0 {
            // as soon as we got the location we stop updating the location through the GPS because it is a
            // high cost feature to keep it up and we don't need it for a weather app
            locationManager.stopUpdatingLocation()
            
            print("longitude: \(location.coordinate.longitude)",
            "latitude: \(location.coordinate.latitude)")
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            // build a dictionary where the String is the key and the String is the value
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // unable to get the coordinates: iPhone in airplane mode, no wifi, ecc
        print(error)
        cityLabel.text = "Location unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredANewCityName(city: String) {
        let params : [String : String] = ["q" : city, "appid" : APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }

    
    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
    
    
    //MARK: - Switch
    /***************************************************************/
    
    @objc func switchTarget(sender: UISwitch) {
        updateUIWithWeatherData()
    }
    
    
    
}


