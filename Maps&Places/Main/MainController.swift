//
//  MainController.swift
//  Maps&Places
//
//  Created by renks on 04.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import UIKit
import MapKit
import LBTATools
import Combine

extension MainController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKPointAnnotation) {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            annotationView.canShowCallout = true
            return annotationView
        }
        return nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Recieved authorization of user location")
            // request for user's location
            locationManager.startUpdatingLocation()
        default:
            print("Failed to authorize")
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }
        mapView.setRegion(.init(center: firstLocation.coordinate, span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        
        //        locationManager.stopUpdatingLocation()
    }
}

class MainController: UIViewController {
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestUserLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        mapView.fillSuperview()
        
        setupRegionForMap()
        
        //setupAnnotationsForMap()
        
        //performLocalSearch()
        
        setupSearchUI()
        setupLocationsCarousel()
        locationsController.mainController = self
        
        setupKeyboardListener()
//        setupTapGesture()
    }
    
    fileprivate func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
    }
    
    
    fileprivate func setupTapGesture() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
    
    @objc fileprivate func handleTapDismiss() {
        self.view.endEditing(true) // dismisses keyboard
    }
    
    fileprivate func setupKeyboardListener() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (notification) in
            
            guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardFrame = value.cgRectValue
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.anchoredConstraints.bottom?.constant = -keyboardFrame.size.height
            })
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (notification) in
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.anchoredConstraints.bottom?.constant = -16
            })
            
        }
    }
    
    let locationsController = LocationsCarouselController(scrollDirection: .horizontal)
    var anchoredConstraints: AnchoredConstraints!
    
    fileprivate func setupLocationsCarousel() {
        let locationsView = locationsController.view!
        view.addSubview(locationsView)
        
        anchoredConstraints = locationsView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 16, right: 0), size: .init(width: 0, height: 100))
    }
    
    let searchTextField = UITextField(placeholder: "Search query")
    
    fileprivate func setupSearchUI() {
        
        let whiteContainer = UIView(backgroundColor: .white)
        whiteContainer.alpha = 0.9
        view.addSubview(whiteContainer)
        whiteContainer.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))
        
        whiteContainer.stack(searchTextField).withMargins(.allSides(16))
        
        // listen for text changes and perform new search
        // OLD SCHOOL
        //searchTextField.addTarget(self, action: #selector(handleSearchChanges), for: .editingChanged)
        
        // NEW SCHOOL Search Throttling
        
        listener = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: searchTextField)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { (_) in
                if self.searchTextField.text?.count == 0 {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.locationsController.items.removeAll()
                } else {
                    self.performLocalSearch()
            }
        }
    }
    
    var listener: AnyCancellable!
    
    @objc fileprivate func handleSearchChanges() {
        performLocalSearch()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let customAnnotation = view.annotation as? CustomMapItemAnnotation else { return }
        
        
        guard let index = self.locationsController.items.firstIndex(where: { $0.name == customAnnotation.mapItem?.name}) else { return }
        
        self.locationsController.collectionView.scrollToItem(at: [0, index], at: .centeredHorizontally, animated: true)
    }
    
    fileprivate func performLocalSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTextField.text
        request.region = mapView.region
        
        mapView.annotations.forEach { (annotation) in
            if annotation.title == "TEST" {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (resp, err) in
            if let err = err {
                print("Failed local search:", err)
                return
            }
            
            // Success
            // remove old annotations
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.locationsController.items.removeAll()
            
            resp?.mapItems.forEach({ (mapItem) in
                print(mapItem.address())
                
                let annotation = CustomMapItemAnnotation()
                annotation.mapItem = mapItem
                annotation.coordinate = mapItem.placemark.coordinate
                
                
                annotation.title = "Location: " + (mapItem.name ?? "")
                
                self.mapView.addAnnotation(annotation)
                
                // tell my locationsCarouselController
                self.locationsController.items.append(mapItem)
            })
            
            if resp?.mapItems.count != 0 { self.locationsController.collectionView.scrollToItem(at: [0, 0], at: .centeredHorizontally, animated: true)
            }
            
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    class CustomMapItemAnnotation: MKPointAnnotation {
        var mapItem: MKMapItem?
    }
    
        fileprivate func setupAnnotationsForMap() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: 37.7666, longitude: -122.42790)
            annotation.title = "Moscow"
            annotation.subtitle = "RU"
            mapView.addAnnotation(annotation)
    
            let appleCampusAnnotation = MKPointAnnotation()
            appleCampusAnnotation.coordinate = .init(latitude: 37.3326, longitude: -122.030024)
            appleCampusAnnotation.title = "Apple Campus"
            appleCampusAnnotation.subtitle = "Coopertino CA"
            mapView.addAnnotation(appleCampusAnnotation)
    
            mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    
    fileprivate func setupRegionForMap() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 55.7557, longitude: 37.6298)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}


// SwiftUI Preview
import SwiftUI

struct MainPreview: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<MainPreview.ContainerView>) -> MainController {
            return MainController()
        }
        
        func updateUIViewController(_ uiViewController: MainController, context: UIViewControllerRepresentableContext<MainPreview.ContainerView>) {
        }
        
        typealias UIViewControllerType = MainController
    }
}


