//
//  AddEventView.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/13.
//

import SwiftUI
import EventKit

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var customColor: CustomColor
    private var eventData: EventData = EventData()
    
    @State private var isActiveAdd: Bool = false
    
    var body: some View {
        // ここから
        // NavigationStackとtoolvar ついか
        
        NavigationStack {
            EditEventView(isActiveAdd: $isActiveAdd)
                .environmentObject(eventData)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar() {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            eventData.initializeObj()
                            dismiss()
                        } label: {
                            Text("キャンセル")
                                .foregroundStyle(customColor.cancel)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                            Text("新規イベント")
                            .foregroundStyle(customColor.foreGround)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if isActiveAdd {
                                eventData.ekEvent.isAllDay = eventData.isAllDay
                                eventData.ekEvent.calendar = eventData.currentCalendar
                                let _ = eventData.eventController.addEvent(ekEvent: eventData.ekEvent)
                                eventData.initializeObj()
                                dismiss()
                            }
                        } label: {
                            Text("追加")
                                .foregroundStyle(isActiveAdd ? customColor.complete : customColor.invalid)
                        }
                    }
                }
        }
    }
}


struct AddEventView_Previews: PreviewProvider {
    static var previews: some View {
        AddEventView()
            .environmentObject(CustomColor(foreGround: .black, backGround: .white))
    }
}
