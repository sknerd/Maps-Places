//
//  MKMapItem+Adress.swift
//  Maps&Places
//
//  Created by renks on 04.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import UIKit
import MapKit

extension MKMapItem {
    func address() -> String {
        var addressString = ""
        if placemark.subThoroughfare != nil {
            addressString = placemark.subThoroughfare! + " "
        }
        if placemark.thoroughfare != nil {
            addressString += placemark.thoroughfare! + ", "
        }
        if placemark.postalCode != nil {
            addressString += placemark.postalCode! + " "
        }
        if placemark.locality != nil {
            addressString += placemark.locality! + ", "
        }

        if placemark.country != nil {
            addressString += placemark.country!
        }
        return addressString
    }
}
