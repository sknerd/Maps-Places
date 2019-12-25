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

class MapSearchingViewModel: ObservableObject {
    
    @Published var annotations = [MKPointAnnotation]()
    @Published var isSearching = false
    
    fileprivate func performSearch(query: String) {
        isSearching = true // also can use isSearching.toggle()
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
            self.isSearching = false
            self.annotations = barsAnnotations
        }
    }
}

struct MapSearchingView: View {
    
    @ObservedObject var vm = MapSearchingViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            
            MapViewContainer(annotations: vm.annotations)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        self.vm.performSearch(query: "Bar")
                    }, label: {
                        Text("Search for bars")
                            .padding()
                            .background(Color.white)
                    })
                    
                    Button(action: {
                        self.vm.annotations = []
                    }, label: {
                        Text("Clear Annotations")
                            .padding()
                            .background(Color.white)
                    })
                }.shadow(radius: 3)
                if vm.isSearching {
                   Text("Searching...")
                }
            }
        }
    }
}

struct MapSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchingView()
    }
}
