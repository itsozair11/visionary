import SwiftUI
import Photos
import CoreData

struct AlbumDetailView: View {
    let albumID: NSManagedObjectID
    @Environment(\.managedObjectContext) private var viewContext

    @State private var album: Album?
    @State private var classifications: [Classification] = []
    @State private var isRenaming = false
    @State private var newAlbumName: String = ""
    @State private var showSaveAlert = false
    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: Classification?
    @State private var showFeatureDisabledAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    if isRenaming {
                        TextField("Album Name", text: $newAlbumName, onCommit: {
                            album?.name = newAlbumName
                            try? viewContext.save()
                            isRenaming = false
                            loadClassifications()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    } else {
                        Text(album?.name ?? "Unnamed Album")
                            .font(.title2.bold())
                            .onTapGesture(count: 2) {
                                newAlbumName = album?.name ?? ""
                                isRenaming = true
                            }
                    }
                }
                .animation(.default, value: isRenaming)

                Button(action: {
                    showFeatureDisabledAlert = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(classifications.isEmpty)

                Text("\(classifications.count) photos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 2)], spacing: 2) {
                    ForEach(classifications, id: \.objectID) { classification in
                        if let data = classification.imageData, let uiImage = UIImage(data: data) {
                            NavigationLink(destination: PhotoDetailView(photo: classification)) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .overlay(
                                        ClassificationBadge(confidence: classification.confidence)
                                            .padding(4),
                                        alignment: .topTrailing
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            photoToDelete = classification
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding()
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadAlbum)
        .alert("Feature Temporarily Unavailable", isPresented: $showFeatureDisabledAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We're working to fix the photo saving feature. Please check back in the next update.")
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showDeleteConfirmation,
            presenting: photoToDelete
        ) { photo in
            Button("Delete", role: .destructive) {
                deletePhoto(photo)
            }
        } message: { _ in
            Text("Are you sure you want to delete this photo?")
        }
    }

    private struct ClassificationBadge: View {
        let confidence: Double

        var body: some View {
            ZStack {
                Circle()
                    .fill(confidence < 0.5 ? Color.orange : Color.green.opacity(0.8))
                if confidence < 0.5 {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 24, height: 24)
        }
    }

    func loadAlbum() {
        do {
            if let fetchedAlbum = try viewContext.existingObject(with: albumID) as? Album {
                album = fetchedAlbum
                loadClassifications()
            }
        } catch {
            print("❌ Failed to load album: \(error)")
        }
    }

    func loadClassifications() {
        guard let album = album else { return }
        let request: NSFetchRequest<Classification> = Classification.fetchRequest()
        request.predicate = NSPredicate(format: "album == %@", album)
        request.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: false)]
        do {
            classifications = try viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch classifications: \(error)")
        }
    }

    func deletePhoto(_ photo: Classification) {
        viewContext.delete(photo)
        do {
            try viewContext.save()
            loadClassifications()
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }
}

    /*struct AlbumDetailView: View {
    let albumID: NSManagedObjectID
    @Environment(\.managedObjectContext) private var viewContext

    @State private var album: Album?
    @State private var classifications: [Classification] = []
    @State private var isRenaming = false
    @State private var newAlbumName: String = ""
    @State private var showSaveAlert = false

    var body: some View {
        VStack {
            if let album = album {
                // Renaming section
                if isRenaming {
                    TextField("Album Name", text: $newAlbumName, onCommit: {
                        album.name = newAlbumName
                        try? viewContext.save()
                        isRenaming = false
                        loadClassifications() // refresh after renaming
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                } else {
                    Text(album.name ?? "Unnamed Album")
                        .font(.largeTitle)
                        .bold()
                        .onTapGesture(count: 2) {
                            newAlbumName = album.name ?? ""
                            isRenaming = true
                        }
                }
                
                // Button to save the album to the Photo Library
                Button("Save Album to Photo Library") {
                    saveAlbumToPhotos()
                }
                .padding(.bottom, 10)
                
                // Show count of classifications
                Text("This album has \(classifications.count) photos")
                    .foregroundColor(.gray)
                
                // List of classifications (photos)
                List {
                    ForEach(classifications, id: \.objectID) { photo in
                        NavigationLink(destination: PhotoDetailView(photo: photo)) {
                            HStack {
                                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                VStack(alignment: .leading) {
                                    Text(photo.label ?? "")
                                    Text("Confidence: \(Int(photo.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                if photo.confidence < 0.5 {
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deletePhoto)
                }
            } else {
                ProgressView("Loading album...")
            }
        }
        .navigationTitle("Album Details")
        .onAppear(perform: loadAlbum)
        .alert("Album Saved to Photos!", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // Load the album using its objectID and then fetch its classifications.
    func loadAlbum() {
        do {
            if let fetchedAlbum = try viewContext.existingObject(with: albumID) as? Album {
                album = fetchedAlbum
                loadClassifications()
            }
        } catch {
            print("❌ Failed to load album: \(error)")
        }
    }
    
    // Fetch the classifications (photos) that belong to this album.
    func loadClassifications() {
        guard let album = album else { return }
        let request: NSFetchRequest<Classification> = Classification.fetchRequest()
        // Filter for classifications that have this album as their parent.
        request.predicate = NSPredicate(format: "album == %@", album)
        // Sort by confidence descending
        request.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: false)]
        do {
            classifications = try viewContext.fetch(request)
            print("✅ Fetched \(classifications.count) photos for album \(album.name ?? "Unnamed")")
        } catch {
            print("❌ Failed to fetch classifications: \(error)")
        }
    }
    
    func deletePhoto(at offsets: IndexSet) {
        for index in offsets {
            let photoToDelete = classifications[index]
            viewContext.delete(photoToDelete)
        }
        try? viewContext.save()
        loadClassifications()
    }
    
    func saveAlbumToPhotos() {
        guard let album = album else { return }
        let images = classifications.compactMap { $0.imageData.flatMap { UIImage(data: $0) } }
        
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
                showSaveAlert = success
            }
        }
    }
     }*/
