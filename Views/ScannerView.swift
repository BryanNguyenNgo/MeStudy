//
//  ScannerView.swift
//  MeStudy
//
//  Created by Bryan Nguyen on 20/2/25.
//

import SwiftUI
import Vision
import PhotosUI

struct ScannerView: View {
    @Binding var selectedGrade: String?  // Bind to the selected grade
    @Binding var selectedSubject: String?  // Bind to the selected subject
    @Binding var selectedTopic: String?  // Bind to the selected topic
    
    @State private var selectedImage: UIImage?
  
    @State private var showImagePicker = false
    @State private var studyPlanSuggested = false

    @StateObject private var viewModel = StudyPlanViewModel()
    
    var body: some View {
        ScrollView{
            VStack {
                Text("Upload a Textbook Page")
                    .font(.title)
                    .padding()
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                } else {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Label("Choose an Image", systemImage: "photo.on.rectangle")
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                if !viewModel.recognizedText.isEmpty {
                    Text("Extracted Text:")
                        .font(.headline)
                        .padding(.top)
                    
                    ScrollView {
                        Text(viewModel.recognizedText)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .frame(height: 100)
                    
                    Button("Guide Me to Find the Answer") {
                        analyzeText()
                        print("\(viewModel.recognizedText)")
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                   
                        Button("Create Study Plan for This Topic") {
                            Task {
                                await createStudyPlan()
                            }
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                
            }
            .padding()
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, onImagePicked: extractTextFromImage)
                
            }
        }
    }
        // Process image with Vision
        private func extractTextFromImage(image: UIImage) {
            selectedImage = image
            viewModel.recognizedText = "" // Reset text
            
            guard let cgImage = image.cgImage else { return }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let results = request.results as? [VNRecognizedTextObservation] else { return }
                let extractedText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                DispatchQueue.main.async {
                    viewModel.recognizedText = extractedText
                }
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
        
        // Guide the student based on extracted text
        private func analyzeText() {
            if viewModel.recognizedText.contains("chapter") || viewModel.recognizedText.contains("exercise") {
                viewModel.recognizedText += "\n\nHint: Look at the chapter summary and key points to find the answer."
            } else {
                viewModel.recognizedText += "\n\nHint: Try searching for keywords in the text to understand the main idea."
            }
            studyPlanSuggested = true
        }
        
        // Suggest creating a study plan
        private func createStudyPlan() async {
            print("Study plan created for topic: \(viewModel.recognizedText)")
            
            // Extract study plan
            let result = await viewModel.extractStudyPlan(recognizedText: viewModel.recognizedText)
            
            switch result {
            case .success(let studyPlanExtracted):
                DispatchQueue.main.async {
                    // Update the bound values
                    selectedGrade = studyPlanExtracted?.grade
                    selectedSubject = studyPlanExtracted?.subject
                    selectedTopic = studyPlanExtracted?.topic
                }

            case .failure(let error):
                print("Error extracting study plan: \(error.localizedDescription)")
            }
            
        }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.image = image
                            self.parent.onImagePicked(image)
                        }
                    }
                }
            }
        }
    }
}

