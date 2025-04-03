//
//  PhotoDetailView.swift
//  visionary
//
//  Created by Ozair Kamran on 4/2/25.
//


import SwiftUI
import Photos

struct PhotoDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var photo: Classification
    @FetchRequest(entity: Album.entity(), sortDescriptors: [])
    var allAlbums: FetchedResults<Album>

    @State private var selectedAlbum: Album?
    @State private var showRenameAlert = false
    @State private var newAlbumName = ""
    @State private var showSaveSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            if let data = photo.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }

            Text("Label: \(photo.label ?? "Unknown")")
            Text("Confidence: \(Int(photo.confidence * 100))%")

            if photo.confidence < 0.5 {
                Label("Low confidence", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }

            if let currentAlbum = photo.album {
                Divider()
                Text("Current Album: \(currentAlbum.name ?? "Unnamed")")

                Picker("Move to Album", selection: $selectedAlbum) {
                    ForEach(allAlbums, id: \.self) { album in
                        Text(album.name ?? "Unnamed").tag(Optional(album))
                    }
                }
                .onAppear {
                    selectedAlbum = currentAlbum
                }
                .onChange(of: selectedAlbum) { newAlbum in
                    if let newAlbum = newAlbum {
                        photo.album = newAlbum
                        try? viewContext.save()
                    }
                }

                Button("Rename Album") {
                    newAlbumName = currentAlbum.name ?? ""
                    showRenameAlert = true
                }

                Button("Save Album to Photos") {
                    saveAlbumToPhotoLibrary(album: currentAlbum)
                }
            }
        }
        .padding()
        .navigationTitle("Photo Detail")
        .alert("Rename Album", isPresented: $showRenameAlert) {
            TextField("New name", text: $newAlbumName)
            Button("Save") {
                photo.album?.name = newAlbumName
                try? viewContext.save()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Album Saved to Photos!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        }
    }

    func saveAlbumToPhotoLibrary(album: Album) {
        guard let photos = album.photos as? Set<Classification> else { return }
        let images = photos.compactMap { classification in
            classification.imageData.flatMap { UIImage(data: $0) }
        }

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album.name ?? "Visionary Album")
            for image in images {
                let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                if let placeholder = assetRequest.placeholderForCreatedAsset {
                    request.addAssets([placeholder] as NSArray)
                }
            }
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                showSaveSuccess = success
            }
        }
    }
}
