//
//  ViewController.swift
//  TestPhotoLibrary
//
//  Created by Miguel Alcântara on 10/03/2022.
//

import UIKit
import Photos
import PhotosUI

class ViewController: UIViewController {

    var button: UIButton!
    var label: UILabel!

    var fetchResult: PHFetchResult<PHAsset>!
    var allowedPhotos: [PHAsset: UIImage] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        // Do any additional setup after loading the view.
        setupPhotoLibrary()
    }

    func addViews() {
        button = UIButton(type: .system)
        button.setTitle("Allow/Refuse Photos", for: .normal)
        button.addTarget(self, action: #selector(openLimitedLibraryPicker), for: .touchUpInside)

        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.safeAreaLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        label = UILabel(frame: .zero)
        label.text = "Count of allowed photos: \(allowedPhotos.count)"

        view.addSubview(label)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.safeAreaLayoutGuide.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 16).isActive = true
        label.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        label.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    }

    func setupPhotoLibrary() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch authStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
                switch status {
                case .authorized: self.getPhotos()
                case .restricted: break
                case .limited: break
                case .notDetermined, .denied: break
                }
            }
        default:
            getPhotos()
        }
        PHPhotoLibrary.shared().register(self)
    }

}

extension ViewController {
    @objc
    func openLimitedLibraryPicker() {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
    }

    func getPhotos() {
        allowedPhotos.removeAll()
        label.text = "Count of allowed photos: Calculating....."
        let manager = PHImageManager.default()
        fetchResult = PHAsset.fetchAssets(with: .image, options: PHFetchOptions())
        fetchResult.enumerateObjects { (asset, index, pointer) in
            print("identifier = \(asset.localIdentifier)")
            print("WxH = \(asset.pixelWidth)x\(asset.pixelHeight)")
            let requestOptions = PHImageRequestOptions()
            requestOptions.isNetworkAccessAllowed = false
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .fastFormat
            manager.requestImageDataAndOrientation(for: asset, options: requestOptions) { (data, imageString, orientation, options) in
                defer {
                    if index == self.fetchResult.count - 1 {
                        self.listAllAvailablePhotos()
                    }
                }
                guard let data = data, let image = UIImage(data: data) else {
                    print("could not read \(imageString ?? "")")
                    return
                }
                print("image for identifier = \(image.description)")
                self.allowedPhotos[asset] = image
            }
        }
    }

    func listAllAvailablePhotos() {
        print("allowedPhotos.count = \(allowedPhotos.count)")
        label.text = "Count of allowed photos: \(allowedPhotos.count)"
    }
}

extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("CHANGE = \(changeInstance)")
        fetchResult = changeInstance.changeDetails(for: fetchResult)?.fetchResultAfterChanges
        DispatchQueue.main.async {
            self.getPhotos()
        }
    }
}
