//
//  DirectionsController.swift
//  Maps&Places
//
//  Created by renks on 05.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import UIKit
import LBTATools
import MapKit
import SwiftUI
import JGProgressHUD

extension DirectionsController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        
        polylineRenderer.strokeColor = #colorLiteral(red: 0.243729949, green: 0.5508802533, blue: 0.9618994594, alpha: 1)
        polylineRenderer.lineWidth = 5
        
        return polylineRenderer
    }
}

class DirectionsController: UIViewController {
    
    let mapView = MKMapView()
    let navBar = UIView(backgroundColor: #colorLiteral(red: 0.2422935634, green: 0.5481504928, blue: 0.961396277, alpha: 1))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        view.addSubview(mapView)
        
        setupRegionForMap()
        
        setupNavBarUI()
        
        mapView.anchor(top: navBar.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        
        mapView.showsUserLocation = true
        
        setupShowRouteButton()
        
        //setupStartEndDummyAnnotations()
        
    }
    
    fileprivate func setupShowRouteButton() {
        let showRouteButton = UIButton(title: "Show Route", titleColor: .black, font: .boldSystemFont(ofSize: 16), backgroundColor: .white, target: self, action: #selector(handleShowRoute))
        
        view.addSubview(showRouteButton)
        showRouteButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .allSides(16), size: .init(width: 0, height: 50))
    }
    
    @objc fileprivate func handleShowRoute() {
        let routesController  = RoutesController()
        routesController.route = currentlyShowingRoute
        
        routesController.items = self.currentlyShowingRoute?.steps.filter({!$0.instructions.isEmpty}) ?? []
        present(routesController, animated: true)
    }
    
    class RouteStepCell: LBTAListCell<MKRoute.Step> {
        
        override var item: MKRoute.Step! {
            didSet {
                nameLabel.text = item.instructions
                
                if item.distance > 1000 {
                    distanceLabel.text = String(format: "%.1f км.", item.distance / 1000)
                } else {
                    distanceLabel.text = String(format: "%.0f м.", item.distance)
                }
            }
        }
        
        let nameLabel = UILabel(text: "Name",font: .systemFont(ofSize: 16), numberOfLines: 0)
        let distanceLabel = UILabel(text: "Distance", font: .italicSystemFont(ofSize: 16), textColor: .lightGray, textAlignment: .right)
        
        override func setupViews() {
            hstack(nameLabel, distanceLabel.withWidth(80)).withMargins(.allSides(16))
            
            addSeparatorView(leadingAnchor: nameLabel.leadingAnchor)
        }
    }
    

    
    class RoutesController: LBTAListHeaderController<RouteStepCell, MKRoute.Step, RouteHeader>, UICollectionViewDelegateFlowLayout {
        
        var route: MKRoute!
        
        override func setupHeader(_ header: RouteHeader) {
            header.nameLabel.attributedText = header.generateAttributedString(title: "Route", description: route.name)
            header.distanceLabel.attributedText = header.generateAttributedString(title: "Distance", description: String(format: "%.1f км.", route.distance / 1000))
            
            var timeString = ""

            if route.expectedTravelTime > 3600 {
                let h = Int(route.expectedTravelTime / 60 / 60)
                let m = Int((route.expectedTravelTime.truncatingRemainder(dividingBy: 60 * 60)) / 60)
                timeString = String(format: "%d hr %d min", h, m)
            } else {
                let time = Int(route.expectedTravelTime / 60)
                timeString = String(format: "%d min", time)
            }

            header.estimatedTimeLabel.attributedText = header.generateAttributedString(title: "Estimated Time", description: timeString)
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            .init(width: view.frame.width, height: 120)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            .init(width: view.frame.width, height: 80)
        }
    }
    
    
    fileprivate func requestForDirections() {
        
        let request = MKDirections.Request()
        request.source = startMapItem
        request.destination = endMapItem
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Routing..."
        hud.show(in: view)
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, err) in
            hud.dismiss()
            
            if let err = err {
                print("Failed to find fouting info:", err)
                return
            }
            // success
            print("Found my directions...")
            
//            response?.routes.forEach({ (route) in
//                self.mapView.addOverlay(route.polyline)
//            })
            
            if let firstRoute = response?.routes.first {
                self.mapView.addOverlay(firstRoute.polyline)
            }
            
            self.currentlyShowingRoute = response?.routes.first
        }
    }
    
    var currentlyShowingRoute: MKRoute?
    
    fileprivate func setupStartEndDummyAnnotations() {
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = .init(latitude: 51.501665, longitude: 0.127270)
        startAnnotation.title = "Ben"
        
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = .init(latitude: 51.491779, longitude: 0.131904)
        endAnnotation.title = "Tate"
        
        mapView.addAnnotations([startAnnotation, endAnnotation])
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    let startTextField = IndentedTextField(padding: 12, cornerRadius: 5)
    let endTextField = IndentedTextField(padding: 12, cornerRadius: 5)
    
    fileprivate func setupNavBarUI() {
        
        navBar.setupShadow(opacity: 0.3, radius: 5)
        view.addSubview(navBar)
        navBar.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: -130, right: 0))
        
        startTextField.attributedPlaceholder = .init(string: "Start", attributes: [.foregroundColor: UIColor.init(white: 1, alpha: 0.7)])
        endTextField.attributedPlaceholder = .init(string: "End", attributes: [.foregroundColor: UIColor.init(white: 1, alpha: 0.7)])
        
        [startTextField, endTextField].forEach { (tf) in
            tf.backgroundColor = .init(white: 1, alpha: 0.3)
            tf.textColor = .white
        }
        
        let containerView = UIView()
        navBar.addSubview(containerView)
        containerView.fillSuperviewSafeAreaLayoutGuide()
        
        let startIcon = UIImageView(image: #imageLiteral(resourceName: "start_location_circles"), contentMode: .scaleAspectFit)
        let endIcon = UIImageView(image: #imageLiteral(resourceName: "annotation_icon").withRenderingMode(.alwaysTemplate), contentMode: .scaleAspectFit)
        
        startIcon.constrainWidth(20)
        endIcon.constrainWidth(20)
        endIcon.tintColor = .white
        
        containerView.stack(
            containerView.hstack(startIcon, startTextField, spacing: 16),
            containerView.hstack(endIcon, endTextField, spacing: 16),
            spacing: 12,
            distribution: .fillEqually)
            .withMargins(.init(top: 8, left: 16, bottom: 12, right: 16))
        
        startTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeStartLocation)))
        endTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleEndChangeLocation)))
        
        navigationController?.navigationBar.isHidden = true
    }
    
    var startMapItem: MKMapItem?
    var endMapItem: MKMapItem?
    
    func refreshMap() {
        // remove everything from map
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        if let mapItem = startMapItem {
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.title = mapItem.name
            mapView.addAnnotation(annotation)
        }
        
        if let mapItem = endMapItem {
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.title = mapItem.name
            mapView.addAnnotation(annotation)
        }
        requestForDirections()
        mapView.showAnnotations(mapView.annotations, animated: false)
    }
    
    @objc fileprivate func handleChangeStartLocation() {
        let vc = LocationSearchController()
        
        vc.selectionHandler = { [weak self] mapItem in
            
            self?.startTextField.text = mapItem.name
            
            // add starting annotation and show it in the map
            self?.startMapItem = mapItem
            self?.refreshMap()
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc fileprivate func handleEndChangeLocation() {
        let vc = LocationSearchController()
        
        vc.selectionHandler = { [weak self] mapItem in
            
            self?.endTextField.text = mapItem.name
            self?.endMapItem = mapItem
            self?.refreshMap()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setupRegionForMap() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 59.935625, longitude: 30.355605)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}




struct DirectionsPreview: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
        //            .environment(\.colorScheme, .light)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<DirectionsPreview.ContainerView>) -> UIViewController {
            
            UINavigationController(rootViewController: DirectionsController())
        }
        
        func updateUIViewController(_ uiViewController: DirectionsPreview.ContainerView.UIViewControllerType, context: UIViewControllerRepresentableContext<DirectionsPreview.ContainerView>) {
            
        }
    }
}
