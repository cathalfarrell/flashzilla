//
//  CardView.swift
//  Flashzilla
//
//  Created by Cathal Farrell on 30/06/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import SwiftUI

struct CardView: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityEnabled) var accessibilityEnabled //tells if voice over running

    @EnvironmentObject var settings: UserSettings
    
    let card: Card
    var removal: ((Bool) -> Void)? = nil

    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    @State private var feedback = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
            .fill(
                differentiateWithoutColor
                    ? Color.white
                    : Color.white
                        .opacity(1 - Double(abs(offset.width / 50)))

            )
            .background(
                differentiateWithoutColor
                    ? nil
                    : RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(offset.width > 0 ? Color.green : Color.red)
            )
            .shadow(radius: 10)

            VStack {
                if accessibilityEnabled {
                    Text(isShowingAnswer ? card.answer : card.prompt)
                        .font(.largeTitle)
                        .foregroundColor(.black)
                } else {
                    Text(card.prompt)
                        .font(.largeTitle)
                        .foregroundColor(.black)

                    if isShowingAnswer {
                        Text(card.answer)
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        //480 is the landscape size on smallest iphones
        .frame(width: 450, height: 250)

        // MARK: - Drag Gesture
        //Drag effects modifiers & drag gesture
        .rotationEffect(.degrees(Double(offset.width / 5)))
        .offset(x: offset.width * 5, y: 0)
        .opacity(2 - Double(abs(offset.width / 50)))
        .accessibility(addTraits: .isButton) //lets users know its a button
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.offset = gesture.translation
                    self.feedback.prepare()
                }

                .onEnded { _ in
                    if abs(self.offset.width) > 100 {
                        // MARK: - Haptics
                        if self.offset.width > 0 {
                            self.feedback.notificationOccurred(.success)
                        } else {
                            self.feedback.notificationOccurred(.error)
                        }

                        // Now that we detected that user wants to delete call
                        // We call the closure defined when CardView struct was constructed
                        // i.e. remove the card

                        // Or if setting enabled retain wrong cards

                        if self.settings.retainWrongCards && self.offset.width < 0 {
                            self.offset = .zero
                            self.removal?(false)
                        } else {
                            self.removal?(true)
                        }
                        
                    } else {
                        self.offset = .zero
                    }
                }
        )

        // MARK: - Tap Gesture
        .onTapGesture {
            self.isShowingAnswer.toggle()
        }

        .animation(.spring()) //springs card back if let go
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: Card.example)
    }
}
