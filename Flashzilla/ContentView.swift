//
//  ContentView.swift
//  Flashzilla
//
//  Created by Cathal Farrell on 26/06/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import CoreHaptics
import SwiftUI

struct ContentView: View {

    @EnvironmentObject var settings: UserSettings

    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityEnabled) var accessibilityEnabled

    @State private var cards = [Card]()
    @State private var timeRemaining = 100
    @State private var isActive = true
    @State private var showingEditScreen = false
    @State private var showingSettingsScreen = false
    @State private var isGameOver = false
    @State private var timer = Timer.publish (every: 1, on: .current, in: .common).autoconnect()
    // Custom Haptics Engine
    @State private var engine: CHHapticEngine?

    var body: some View {

        ZStack {
            Image(decorative: "background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text(isGameOver ? "Game Over" : "Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black)
                            .opacity(0.75)
                    )
                ZStack {
                    ForEach(0..<cards.count, id: \.self) { index in

                        // This card view struct has a trailing closure
                        // That asks for the card to be removed when set
                        // It gets set in the card view struct - when card is removed

                        CardView(card: self.cards[index]) { remove in
                            withAnimation{
                                if remove {
                                    self.removeCard(at: index)
                                } else {
                                    self.retainCard(at: index)
                                }
                            }
                        }
                        .stacked(at: index, in: self.cards.count)
                        //Ensures only top card accessible
                        //.allowsHitTesting(index == self.cards.count - 1)
                        .accessibility(hidden: index < self.cards.count - 1)
                        .environmentObject(self.settings)
                    }
                }
                // Turns off interactions on card stack when timer is 0
                .allowsHitTesting(timeRemaining > 0)

                if cards.isEmpty {
                    Button("Start Again", action: resetCards)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }

            /*
                // Challenge 2:
                Add a settings screen that has a single option: when you get an answer one wrong that card goes back
                into the array so the user can try it again.
             */

            //Top Left Settings Button
            VStack {
                HStack {
                    Button(action: {
                        // Open Settings View
                        print("Open settings View")
                        self.showingSettingsScreen = true
                    }) {
                       Image(systemName: "gear")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                    }
                    .accessibility(label: Text("Settings"))
                    .accessibility(hint: Text("Change the settings"))
                    Spacer()
                }
                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            .sheet(isPresented: $showingSettingsScreen) {
                SettingsView().environmentObject(self.settings)
            }

            //Edit Button - top right corner

            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        self.showingEditScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }

                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            .sheet(isPresented: $showingEditScreen, onDismiss: resetCards) {
                EditCards()
            }

            // MARK: - Accessibility - shows buttons with voice overs

            if differentiateWithoutColor || accessibilityEnabled {
                VStack {
                    Spacer()

                    HStack {

                        //INCORRECT button for Accessibility
                        Button(action: {
                            self.removeCard(at: self.cards.count - 1)
                        }) {
                            Image(systemName: "xmark.circle")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                        }
                        .accessibility(label: Text("Wrong"))
                        .accessibility(hint: Text("Mark your answer as being incorrect."))

                        Spacer()

                        //CORRECT button for Accessibility
                        Button(action:{
                            self.removeCard(at: self.cards.count - 1)
                        }) {
                            Image(systemName: "checkmark.circle")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                        }
                        .accessibility(label: Text("Correct"))
                        .accessibility(hint: Text("Mark your answer as being correct."))
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                }
            }
        }
        .onReceive(timer) { time in
            guard self.isActive else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1

                self.handleGameOver()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.isActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if self.cards.isEmpty == false {
                self.isActive = true
            }
        }
        .onAppear(perform: resetCards)
    }

    func retainCard(at index: Int) {
        //stops removal if no cards
        print("retain: \(index)")
        guard index >= 0 else { return }
        let card = cards[index]
        
        cards.remove(at: index)
        cards.insert(card, at: 0)

        if cards.isEmpty {
            isActive = false
        }

        saveData()
    }

    func removeCard(at index: Int) {
        print("remove: \(index)")
        //stops removal if no cards
        guard index >= 0 else { return }

        cards.remove(at: index)

        if cards.isEmpty {
            isActive = false
        }

        saveData()
    }

    func resetCards() {
        self.timer = Timer.publish (every: 1, on: .current, in:
        .common).autoconnect()
        timeRemaining = 100
        isActive = true
        isGameOver = false
        loadData()
    }

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "Cards") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                self.cards = decoded
            }
        }
    }

    func saveData() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: "Cards")
        }
    }

    fileprivate func handleGameOver() {
        // Handle Game Over

        if self.timeRemaining == 1 {
            self.prepareHaptics()
        }

        if self.timeRemaining == 0 {
            print("🛑 Game Over")
            self.timer.upstream.connect().cancel()
            self.isGameOver = true

            self.playComplexHaptic()

            print("User Settings Value: \(settings.retainWrongCards)")
        }
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            self.engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    fileprivate func createComplexHaptic(_ events: inout [CHHapticEvent]) {
        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            print("1. Intensity: \(intensity.value), sharpness: \(sharpness.value) time: \(i)")
            events.append(event)
        }

        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1 - i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(1 - i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 1 + i)
            print("2. Intensity: \(intensity.value), sharpness: \(sharpness.value) time: \(i)")
            events.append(event)
        }
    }

    func playComplexHaptic() {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        createComplexHaptic(&events)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

// MARK: - Extension for creating a stack of views
extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: 0, height: offset * 10))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
