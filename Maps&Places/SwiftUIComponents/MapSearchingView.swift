//
//  MapSearchingView.swift
//  Maps&Places
//
//  Created by renks on 25.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import SwiftUI
import MapKit

struct MapViewContainer: UIViewRepresentable {
    
    var annotations = [MKPointAnnotation]()
    
    let mapView = MKMapView()
    
    func makeUIView(context: UIViewRepresentableContext<MapViewContainer>) -> MKMapView {
        setupRegionForMap()
        return mapView
    }
    
    fileprivate func setupRegionForMap() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 55.7557, longitude: 37.6298)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapViewContainer>) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
        uiView.showAnnotations(uiView.annotations, animated: true)
    }
    
    typealias UIViewType = MKMapView
    
}

struct MapSearchingView: View {
    
    @State var dummyAnnotation: MKPointAnnotation?
    
    @State var annotations = [MKPointAnnotation]()
    
    var body: some View {
        ZStack(alignment: .top) {
            
            MapViewContainer(annotations: annotations)
                .edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    self.performSearch(query: "Bar")
                }, label: {
                    Text("Search for bars")
                    .padding()
                        .background(Color.white)
                })
                
                Button(action: {
                    self.annotations = []
                }, label: {
                    Text("Clear Annotations")
                    .padding()
                        .background(Color.white)
                })
            }.shadow(radius: 3)
        }
    }
    
    fileprivate func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        
        request.naturalLanguageQuery = query
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (response, error) in
            if let error = error {
                print(error)
                return
            }
            var barsAnnotations = [MKPointAnnotation]()
            
            response?.mapItems.forEach({ (mapItem) in
                print(mapItem.name ?? "")
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.name
                annotation.coordinate = mapItem.placemark.coordinate
                barsAnnotations.append(annotation)
            })
            self.annotations = barsAnnotations
        }
    }
}

struct MapSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchingView()
    }
}
