import SwiftUI
import PhotosUI
import CoreML
import CoreData
import Vision

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showResultAlert = false
    @State private var resultLabel = ""
    @State private var confidence: VNConfidence = 0.0
    @State private var showComingSoon = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Tap to select an image")
                    .onTapGesture { showImagePicker = true }
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                    Text("Prediction: \(resultLabel)")
                    Text("Confidence: \(Int(confidence * 100))%")
                    if confidence < 0.5 {
                        Label("Low confidence", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                Spacer()
            }
            .navigationTitle("Home")
            .padding()
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -50 {
                        showComingSoon = true
                    }
                }
        )
        .alert("Coming Soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoPicker(image: $selectedImage, onImagePicked: classifyImage)
        }
    }

    func classifyImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }

        do {
            let model = try VNCoreMLModel(for: MobileNetV2().model)
            let request = VNCoreMLRequest(model: model) { req, _ in
                if let result = req.results?.first as? VNClassificationObservation {
                    resultLabel = result.identifier
                    confidence = result.confidence
                    saveToCoreData(image: image, label: resultLabel, confidence: result.confidence)
                }
            }
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try handler.perform([request])
        } catch {
            print("Classification error: \(error)")
        }
    }

    func saveToCoreData(image: UIImage, label: String, confidence: VNConfidence) {
        let classification = Classification(context: viewContext)
        classification.label = label
        classification.confidence = Double(confidence)
        classification.timestamp = Date()

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            classification.imageData = imageData
            print("✅ Image data assigned")
        } else {
            print("❌ Failed to convert image to data")
        }

        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", label)

        if let results = try? viewContext.fetch(fetchRequest), let existingAlbum = results.first {
            classification.album = existingAlbum
            print("📁 Added to existing album: \(existingAlbum.name ?? "Unnamed")")
        } else {
            let newAlbum = Album(context: viewContext)
            newAlbum.name = label
            classification.album = newAlbum
            print("🆕 Created new album: \(label)")
        }

        do {
            try viewContext.save()
            print("💾 Saved classification successfully")
        } catch {
            print("❌ Core Data save failed: \(error)")
        }
    }
}
