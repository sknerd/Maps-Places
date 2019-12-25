//
//  PlacesController.swift
//  Maps&Places
//
//  Created by renks on 06.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import SwiftUI
import LBTATools
import MapKit
import GooglePlaces
import JGProgressHUD

class PlacesController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mapView)
        mapView.fillSuperview()
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        
        requestForLocationAuthorization()
        
        setupSelectedAnnotationHUD()
    }
    
    let hudNameLabel = UILabel(text: "Name", font: .boldSystemFont(ofSize: 16))
    let hudAddressLabel = UILabel(text: "Address", font: .systemFont(ofSize: 16))
    let hudTypesLabel = UILabel(text: "Types", textColor: .gray)
    lazy var infoButton = UIButton(type: .infoLight)
    let hudContainer = UIView(backgroundColor: .white)
    
    fileprivate func setupSelectedAnnotationHUD() {
        
        infoButton.addTarget(self, action: #selector(handleInformation), for: .touchUpInside)
        
        view.addSubview(hudContainer)
        hudContainer.layer.cornerRadius = 5
        hudContainer.setupShadow(opacity: 0.2, radius: 5, offset: .zero, color: .darkGray)
        hudContainer.anchor(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .allSides(16), size: .init(width: 0, height: 125))
        
        let topRow = UIView()
        topRow.hstack(hudNameLabel, infoButton.withWidth(44))
        hudContainer.hstack(hudContainer.stack(topRow,
                                               hudAddressLabel,
                                               hudTypesLabel, spacing: 8),
                            alignment: .center).withMargins(.allSides(16))
    }
    
    @objc fileprivate func handleInformation() {
        guard let placeAnnotation = mapView.selectedAnnotations.first as? PlaceAnnotation else { return }
        
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Loading Photos..."
        hud.show(in: view)
        
        //look up for photos
        
        guard let placeId = placeAnnotation.place.placeID else { return }
        
        client.lookUpPhotos(forPlaceID: placeId) { [weak self] (list, err) in
            if let err = err {
                print("Failed to fetch photos fo ID:", err)
                hud.dismiss()
                return
            }
            let dispatchGroup = DispatchGroup()
            
            var images = [UIImage]()
            
            list?.results.forEach({ (photoMetadata) in
                dispatchGroup.enter()
                self?.client.loadPlacePhoto(photoMetadata) { (image, err) in
                    if let err = err {
                        print("Failed to fetch photo from metadata:", err)
                        hud.dismiss()
                        return
                    }
                    dispatchGroup.leave()
                    guard let image = image else { return }
                    images.append(image)
                }
            })
            
            dispatchGroup.notify(queue: .main) {
                hud.dismiss()
                let controller = PlacePhotosController()
                controller.items = images
                self?.present(UINavigationController(rootViewController: controller), animated: true)
            }
        }
    }
    
    class PhotoCell: LBTAListCell<UIImage> {
        
        override var item: UIImage! {
            didSet {
                imageView.image = item
            }
        }
        
        let imageView = UIImageView(image: nil, contentMode: .scaleAspectFill)
        
        override func setupViews() {
            backgroundColor = .red
            
            addSubview(imageView)
            imageView.fillSuperview()
        }
    }
    
    class PlacePhotosController: LBTAListController<PhotoCell, UIImage>, UICollectionViewDelegateFlowLayout {
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            .init(width: view.frame.width, height: 300)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            navigationItem.title = "Photos"
        }
    }
    
    let client = GMSPlacesClient()
    
    fileprivate func finNearbyPlaces() {
        client.currentPlace { [weak self] (likelihoodlist, err) in
            if let err = err {
                print("Failed to find current place:", err)
                return
            }
            
            likelihoodlist?.likelihoods.forEach({ (likelihood) in
                
                let place = likelihood.place
                
                let annotation = PlaceAnnotation(place: place)
                annotation.title = place.name
                annotation.coordinate = place.coordinate
                
                self?.mapView.addAnnotation(annotation)
            })
            
            self?.mapView.showAnnotations(self?.mapView.annotations ?? [], animated: true)
        }
    }
    
    class PlaceAnnotation: MKPointAnnotation {
        let place: GMSPlace
        init(place: GMSPlace) {
            self.place = place
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is PlaceAnnotation) { return nil }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
        //        annotationView.canShowCallout = true
        
        if let placeAnnotation = annotation as? PlaceAnnotation {
            
            let types = placeAnnotation.place.types
            
            if let firstType = types?.first {
                if firstType == "bar" {
                    annotationView.image = #imageLiteral(resourceName: "bar")
                } else if firstType == "restaurant" {
                    annotationView.image = #imageLiteral(resourceName: "restaurant")
                } else {
                    annotationView.image = #imageLiteral(resourceName: "tourist")
                }
            }
        }
        
        return annotationView
    }
    
    var currentCustomCallout: UIView?
    
    fileprivate func setupHUD(view: MKAnnotationView) {
        
        guard let annotation = view.annotation as? PlaceAnnotation else { return }
        let place = annotation.place
        hudNameLabel.text = place.name
        hudAddressLabel.text = place.formattedAddress
        hudTypesLabel.text = place.types?.joined(separator: ", ")
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        setupHUD(view: view)
        
        currentCustomCallout?.removeFromSuperview()
        
        let customCalloutContainer = ColloutContainer()
        
        view.addSubview(customCalloutContainer)
        
        
        let widthAnchor = customCalloutContainer.widthAnchor.constraint(equalToConstant: 100)
        widthAnchor.isActive = true
        let heightAnchor = customCalloutContainer.heightAnchor.constraint(equalToConstant: 100)
        heightAnchor.isActive = true
        customCalloutContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        customCalloutContainer.bottomAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        currentCustomCallout = customCalloutContainer
        
        // look up for photo on Google Places
        guard let firstPhotMetadata = (view.annotation as? PlaceAnnotation)?.place.photos?.first else { return }
        
        self.client.loadPlacePhoto(firstPhotMetadata) { [weak self] (image, err) in
            if let err = err {
                print("Failed to load photo for place:", err)
            }
            
            guard let image = image else { return }
            
            guard let bestSize = self?.bestCalloutImageSize(image: image) else { return }
            widthAnchor.constant = bestSize.width
            heightAnchor.constant = bestSize.height
            
            customCalloutContainer.imageView.image = image
            customCalloutContainer.nameLabel.text = (view.annotation as? PlaceAnnotation)?.place.name
        }
    }
    
    fileprivate func bestCalloutImageSize(image: UIImage) -> CGSize {
        if image.size.width > image.size.height {
            // w1/h1 = w2/h2
            let newWidth: CGFloat = 200
            let newHeight = newWidth / image.size.width * image.size.height
            return .init(width: newWidth, height: newHeight)
        } else {
            let newHeight: CGFloat = 200
            let newWidth = newHeight / image.size.height * image.size.width
            return .init(width: newWidth, height: newHeight)
        }
    }
    
    fileprivate func requestForLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: first.coordinate, span: span)
        mapView.setRegion(region, animated: false)
        
        finNearbyPlaces()
    }
}

struct PlacesController_Previews: PreviewProvider {
    static var previews: some View {
        Container().edgesIgnoringSafeArea(.all)
    }
    
    struct Container: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<PlacesController_Previews.Container>) -> UIViewController {
            PlacesController()
        }
        
        func updateUIViewController(_ uiViewController: PlacesController_Previews.Container.UIViewControllerType, context: UIViewControllerRepresentableContext<PlacesController_Previews.Container>) {
            
        }
    }
}
