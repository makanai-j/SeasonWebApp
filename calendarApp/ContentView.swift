//
//  ContentView.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/02.
//

import SwiftUI
import RealmSwift
import Foundation
import EventKit

struct ContentView: View {
    var body: some View {
        CalendarView()
            .environmentObject(CustomColor(foreGround: .black, backGround: .white))
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EventData())
    }
}
