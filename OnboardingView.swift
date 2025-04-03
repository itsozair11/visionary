//
//  OnboardingView.swift
//  visionary
//
//  Created by Ozair Kamran on 4/2/25.
//


import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var body: some View {
        TabView {
            VStack {
                Text("Welcome to Visionary")
                    .font(.largeTitle)
                Text("Classify and organize your photos using AI.")
            }

            VStack {
                Text("Smart Albums")
                    .font(.title)
                Text("Your photos will be grouped automatically by content.")
            }

            VStack {
                Text("Let’s get started!")
                    .font(.title)
                Button("Continue") {
                    hasSeenOnboarding = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}
