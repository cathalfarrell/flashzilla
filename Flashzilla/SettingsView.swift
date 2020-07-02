//
//  SettingsView.swift
//  Flashzilla
//
//  Created by Cathal Farrell on 01/07/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//
/*
 // Challenge 2:
 Add a settings screen that has a single option: when you get an answer one wrong that card
 goes back into the array so the user can try it again.
*/

import SwiftUI

class UserSettings: ObservableObject {
    @Published var retainWrongCards = false
}

struct SettingsView: View {
    //Using environment object to share settings in other screens
    @EnvironmentObject var settings: UserSettings
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Toggle(isOn: $settings.retainWrongCards) {
                    Text("Retain wrong answers in deck")
                }
                .padding()

                Spacer()
            }
            .navigationBarTitle("Edit Settings")
            .navigationBarItems(trailing: Button("Done", action: dismiss))
        }
        .navigationViewStyle(StackNavigationViewStyle()) //stops default blank screen landscape
    }

    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
