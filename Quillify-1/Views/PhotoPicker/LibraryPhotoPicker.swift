//
//  LibraryPhotoPicker.swift
//  Quillify-1
//
//  Created by mi11ion on 19/3/24.
//

import Combine
import SwiftUI
import PhotosUI

class LibraryPhotoPicker: UIViewController, PHPickerViewControllerDelegate {
    let state: WindowState
    var cancellable: AnyCancellable? = nil
    var imagePicker: PHPickerViewController? = nil
    
    init(state: WindowState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        let filter = PHPickerFilter.any(of: [.images])
        configuration.filter = filter
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        self.imagePicker = picker
        picker.delegate = self
        
        self.cancellable = state.$photoMode.sink(receiveValue: { [weak self] mode in
            guard let self = self, let picker = self.imagePicker else { return }
            if mode == .library {
                self.present(picker, animated: true)
            } else {
                picker.dismiss(animated: true)
            }
        })
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // dismiss picker
        self.state.photoMode = .none
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] photo, error in
            guard let self = self, let image = photo as? UIImage else { return }
        }
    }
}

struct LibraryPhotoPickerView: UIViewControllerRepresentable {
    @ObservedObject var windowState: WindowState
    
    func makeUIViewController(context: Context) -> UIViewController {
        LibraryPhotoPicker(state: windowState)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // ignore
    }
}
