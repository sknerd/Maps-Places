//
//  LocationSearchController.swift
//  Maps&Places
//
//  Created by renks on 05.12.2019.
//  Copyright © 2019 Renald Renks. All rights reserved.
//

import SwiftUI
import UIKit
import LBTATools
import MapKit
import Combine

class LocationSearchCell: LBTAListCell<MKMapItem> {
    
    override var item: MKMapItem! {
        didSet {
            nameLabel.text = item.name
            addressLabel.text = item.address()
        }
    }
    
    let nameLabel = UILabel(text: "Name", font: .boldSystemFont(ofSize: 16))
    let addressLabel = UILabel(text: "Address", font: .systemFont(ofSize: 14), numberOfLines: 2)
    
    override func setupViews() {
        stack(nameLabel,
              addressLabel).withMargins(.allSides(16))
        
        addSeparatorView(leftPadding: 16)
    }
}

class LocationSearchController: LBTAListController<LocationSearchCell, MKMapItem> {
    
    var selectionHandler: ((MKMapItem) -> ())?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        navigationController?.popViewController(animated: true)
        let mapItem = self.items[indexPath.item]
        selectionHandler?(mapItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.becomeFirstResponder()
        
//        performLocalSearch()
        
        setupSearchBar()
    }
    
    let searchTextField = IndentedTextField(padding: 16, cornerRadius: 5, backgroundColor: .white)
    let backButton = UIButton(image: UIImage(systemName: "arrow.left")!, tintColor: .black, target: self, action: #selector(handleBack)).withWidth(32)
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    let navBarHeight: CGFloat = 66
    
    fileprivate func setupSearchBar() {
        let navBar = UIView(backgroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        view.addSubview(navBar)
        navBar.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: -navBarHeight, right: 0))
        
        collectionView.verticalScrollIndicatorInsets.top = navBarHeight
    
        let containerView = UIView()
        navBar.addSubview(containerView)
        containerView.fillSuperviewSafeAreaLayoutGuide()
        containerView.hstack(backButton, searchTextField, spacing: 12).withMargins(.init(top: 8, left: 16, bottom: 16, right: 16))
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = UIColor.lightGray.cgColor
        searchTextField.layer.cornerRadius = 5
        
        setupSearchListener()
    }
    
    var listener: AnyCancellable!
    
    fileprivate func setupSearchListener() {
        // search throttling
        listener = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: searchTextField).debounce(for: .milliseconds(500), scheduler: RunLoop.main).sink { [weak self] (_) in
            self?.performLocalSearch()
        }
        // if we want to stop listening to text changes in the searchfield in the future
//        listener.cancel()
    }
    
    fileprivate func performLocalSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTextField.text
        
        let search = MKLocalSearch(request: request)
        search.start { (response, err) in
            if let err = err {
                print("Failed to search locations:", err)
            }
            // success
            self.items = response?.mapItems ?? []
        }
    }
}

extension LocationSearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width, height: 80)
    }
}






struct LocationSearchController_Previews: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<LocationSearchController_Previews.ContainerView>) -> UIViewController {
            LocationSearchController()
        }
        
        func updateUIViewController(_ uiViewController: LocationSearchController_Previews.ContainerView.UIViewControllerType, context: UIViewControllerRepresentableContext<LocationSearchController_Previews.ContainerView>) {
            
        }
    }
}
