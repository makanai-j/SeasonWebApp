//
//  EventSeal.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/06.
//

import SwiftUI
import UIKit
import EventKit

struct EventSeal: View {
    let ekEvent: EKEvent
    var showEvents: Bool
    var countEvents: [[Int]]
    let weekCount: Int = 7
    let WIDTH_DATE: CGFloat
    let HEIGHT_DATE: CGFloat
    let HEIGHT_EVENT: CGFloat
    let HEIGHT_EVENT_SPACE: CGFloat
    let WIDTH_TITLE: CGFloat
    let WIDTH_EVENT: CGFloat
    let CARRYOVER: Int
    let title: String
    let color: CGColor
    
    init(ekEvent: EKEvent, showEvents: Bool, countEvents: [[Int]], WIDTH_DATE: CGFloat, HEIGHT_DATE: CGFloat, HEIGHT_EVENT: CGFloat, HEIGHT_EVENT_SPACE: CGFloat, CARRYOVER: Int) {
        self.ekEvent = ekEvent
        self.showEvents = showEvents
        self.countEvents = countEvents
        self.WIDTH_DATE = WIDTH_DATE
        self.HEIGHT_DATE = HEIGHT_DATE
        self.HEIGHT_EVENT = HEIGHT_EVENT
        self.HEIGHT_EVENT_SPACE = HEIGHT_EVENT_SPACE
        self.WIDTH_TITLE = WIDTH_DATE - 8
        self.WIDTH_EVENT = WIDTH_DATE - 2
        self.CARRYOVER = CARRYOVER
        self.title = ekEvent.title == nil ? "no title" : ekEvent.title!
        self.color = ekEvent.calendar.cgColor == nil ? CGColor(gray: 1, alpha: 1) : ekEvent.calendar.cgColor!
    }
    
    var body: some View {
        let padding_top_leading: (top: CGFloat, leading: CGFloat) = getPaddingTopLeading(ekEvent: ekEvent, countEvents: countEvents)
        VStack(spacing: 0) {
            if !showEvents {
                Text(title)
                    .kerning(0)
                    .font(.system(size: 9,weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: WIDTH_TITLE, height: 9, alignment: .top)
                    .clipped()
            }
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(color))
                .frame(height: 3)
        }
        .frame(width: WIDTH_EVENT, height: HEIGHT_EVENT / (showEvents ? 2 : 1))
        .padding(EdgeInsets(top: padding_top_leading.top, leading: padding_top_leading.leading, bottom: 0, trailing: 0))
    }
    
    func getPaddingTopLeading(ekEvent: EKEvent, countEvents: [[Int]]) -> (top: CGFloat, leading: CGFloat) {
        let startDay = Calendar.current.component(.day, from: ekEvent.startDate)
        let rowIndex = Int((startDay + CARRYOVER - 1) / weekCount)
        let columnIndex = Int((startDay + CARRYOVER - 1) % weekCount)
        let topPadding = CGFloat(rowIndex) * (HEIGHT_DATE + HEIGHT_EVENT_SPACE) + CGFloat(rowIndex) + HEIGHT_DATE
        let leadingPadding = CGFloat(columnIndex) * (WIDTH_DATE) + ((WIDTH_DATE - WIDTH_EVENT) / 2)
        
        return (top: topPadding, leading: leadingPadding)
    }
}

struct EventSeal_Previews: PreviewProvider {
    @State static var countEvents = [[0]]
    static func createEvent() -> EKEvent {
        let eventStore = EKEventStore()
        let ekEvent = EKEvent(eventStore: eventStore)
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "test"
        calendar.cgColor = CGColor(red: 0.3, green: 0.7, blue: 0.2, alpha: 1)
        ekEvent.calendar = calendar
        ekEvent.title = "titleTest "
        ekEvent.startDate = Date()
        ekEvent.endDate = Date()
        ekEvent.isAllDay = false
        
        return ekEvent
    }
    
    static var previews: some View {
        EventSeal(ekEvent: createEvent(), showEvents: false, countEvents: countEvents, WIDTH_DATE: 50, HEIGHT_DATE: 10, HEIGHT_EVENT: 19, HEIGHT_EVENT_SPACE: 100, CARRYOVER: 5)
    }
}
