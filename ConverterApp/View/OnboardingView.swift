/*
 
 //
 //  OnboardingView.swift
 //  ConverterApp
 //
 //  Created by Murat Menzilci on 19.12.2023.
 //

 import SwiftUI
 import StoreKit

 struct OnboardingView: View {
     @State private var currentScreen = 1
     @Environment(\.presentationMode) var presentationMode

     var body: some View {
         VStack {
             if currentScreen == 1 {
                 firstScreen
             } else if currentScreen == 2 {
                 secondScreen
             } else if currentScreen == 3 {
                 thirdScreen
             }
         }
     }

     var firstScreen: some View {
         VStack {
             Image("firstScreenImage") // Replace with your image name
                 .resizable()
                 .scaledToFit()
             Text("Welcome to Time Zone Converter")
                 .font(.headline)
             Text("Easily convert times across different time zones.")
                 .padding()
             continueButton(action: { currentScreen = 2 })
         }
     }

     var secondScreen: some View {
         VStack {
             Image("secondScreenImage") // Replace with your image name
                 .resizable()
                 .scaledToFit()
             Text("Stay Organized")
                 .font(.headline)
             Text("Manage international meetings and calls with ease.")
                 .padding()
             continueButton(action: {
                 currentScreen = 3
                 if let windowScene = UIApplication.shared.windows.first?.windowScene {
                     SKStoreReviewController.requestReview(in: windowScene)
                 }
             })
         }
     }

     var thirdScreen: some View {
         VStack {
             Image("thirdScreenImage") // Replace with your image name
                 .resizable()
                 .scaledToFit()
             Text("Help us Grow")
                 .font(.headline)
             Text("Support us by giving a 5-star rating!")
                 .padding()
             continueButton(action: {
                 presentationMode.wrappedValue.dismiss()
             })
         }
     }

     private func continueButton(action: @escaping () -> Void) -> some View {
         Button(action: action) {
             Text("Continue")
                 .foregroundColor(.white)
                 .frame(maxWidth: .infinity)
                 .padding()
                 .background(Color.blue)
                 .cornerRadius(8)
         }
         .padding()
     }
 }

 struct OnboardingView_Previews: PreviewProvider {
     static var previews: some View {
         OnboardingView()
     }
 }

 
 */
