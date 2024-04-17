//
//  MonthCalendar.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/06.
//

import SwiftUI
import UIKit
import EventKit

struct MonthCalendar: View {
    @ObservedObject var eventData: EventData
    @Binding var selectedEventDate: Date?
    
    var startWeek: String
    let NUMWEEK = 7
    let NUMROWMONTH = 6
    let YEAR: Int
    let MONTH: Int
    let infoMonth: getInfoMonth
    let week: [String]
    
    // 日付に所属するイベント一覧有効化
    @Binding private var showEvents: Bool
    
    init(YEAR: Int, MONTH: Int, eventData: EventData, selectedEventDate: Binding<Date?>, showEvents: Binding<Bool>) {
        self.YEAR = YEAR
        self.MONTH = MONTH
        self.infoMonth = getInfoMonth(year: YEAR, month: MONTH)
        self.week = infoMonth.getWeek()
        self.startWeek = self.week[0]
        self.eventData = eventData
        
        self._selectedEventDate = selectedEventDate
        self._showEvents = showEvents
    }
    
    let LINE_COLOR = Color.gray.opacity(0.5)
    
    var body: some View {
        let indexStartWeek = week.firstIndex(of: startWeek)!
        let customWeek: [String] = createCustomWeek(indexStartWeek)
        let CARRYOVER = infoMonth.noWeekFirstDate
        // イベント取得
        
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let HEIGHT_WEEK: CGFloat = 20
            let WIDTH_DATE: CGFloat = width /  CGFloat(NUMWEEK)
            let HEIGHT_DATE: CGFloat = 12
            let HEIGHT_ROW_MONTH: CGFloat = (height - HEIGHT_WEEK - 6) / CGFloat(NUMROWMONTH)
            let HEIGHT_EVENT: CGFloat = 19
            let HEIGHT_EVENT_SPACE = HEIGHT_ROW_MONTH - HEIGHT_DATE
            let ROW_EVENTS: Int = Int((HEIGHT_ROW_MONTH - 10) / HEIGHT_EVENT) - 1
            
            ZStack(alignment: .topLeading) {
                let ekEvents = eventData.eventController.getEvents(year: YEAR, month: MONTH)
                if !ekEvents.isEmpty {
                    ForEach(ekEvents, id: \.self) { ekEvent in
                        EventSeal(ekEvent: ekEvent, showEvents: showEvents,
                                  countEvents: createEventsArray(range: infoMonth.rangeMonth, rowEvents: ROW_EVENTS),
                                  WIDTH_DATE: WIDTH_DATE, HEIGHT_DATE: HEIGHT_DATE,
                                  HEIGHT_EVENT: HEIGHT_EVENT,
                                  HEIGHT_EVENT_SPACE: HEIGHT_EVENT_SPACE,
                                  CARRYOVER: CARRYOVER)
                            .padding(EdgeInsets(top: HEIGHT_WEEK, leading: 0, bottom: 0, trailing: 0))
                        
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    // 週
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(customWeek[index])
                                .foregroundStyle(.black)
                                .frame(width: WIDTH_DATE,height: HEIGHT_WEEK)
                                .font(.system(size: 10))
                        }
                    }
                    
                    //　日付と仕切り線
                    ForEach(0..<NUMROWMONTH, id: \.self) { rowIndex in
                        
                        //仕切りの線
                        Rectangle()
                            .fill(LINE_COLOR)
                            .frame(width: width, height: 1)
                        
                        HStack(spacing: 0) {
                            ForEach(0..<NUMWEEK, id: \.self) { columnIndex in
                                VStack(spacing: 0) {
                                    let day: Int = infoMonth.getDay(rowIndex, columnIndex, CARRYOVER)
                                    let dateComp: DateComponents = DateComponents(year: YEAR, month: MONTH, day: day)
                                    let thisDate: Date = Calendar.current.date(from: dateComp)!
                                    if infoMonth.rangeMonth ~= day {
                                        Button {
                                                selectedEventDate = thisDate
                                                let ekEvents = eventData.eventController.getEvents(date: thisDate)
                                                showEvents = !ekEvents.isEmpty ? true : false
                                            
                                        } label: {
                                            //日付
                                            VStack {
                                                Text(infoMonth.getDay(rowIndex, columnIndex, CARRYOVER).description)
                                                    .foregroundStyle(.black)
                                                    .frame(width: WIDTH_DATE, height: HEIGHT_DATE, alignment: .center)
                                                    .font(.system(size: 10))
                                                    .frame(width: WIDTH_DATE)
                                            }
                                            .frame(height: HEIGHT_ROW_MONTH, alignment: .top)
                                        }
                                        
                                    } else {
                                        Text("")
                                            .frame(width: WIDTH_DATE, height: HEIGHT_DATE)
                                    }
                                }
                            }
                        }
                        .frame(height: HEIGHT_ROW_MONTH, alignment: .top)
                    }
                }
            }
        }
    }
    
    func createCustomWeek(_ indexStartWeek: Int) -> [String] {
        var w = [String]()
        
        for i in 0..<7 {
            w.append(week[(i + indexStartWeek) % 7])
        }
        
        return w
    }
    
    func createEventsArray(range: Range<Int>, rowEvents: Int) -> [[Int]] {
        var row: [Int] = []
        for _ in 0..<rowEvents {
            row.append(0)
        }
        
        var countEvents: [[Int]] = []
        for _ in range {
            countEvents.append(row)
        }
        
        return countEvents
    }

}

func createEvent(day: Int) -> EKEvent {
    let eventStore = EKEventStore()
    let ekEvent = EKEvent(eventStore: eventStore)
    let calendar = EKCalendar(for: .event, eventStore: eventStore)
    calendar.title = "test"
    let r: Int = Array(1...30).randomElement()!
    let g: Int = Array(1...30).randomElement()!
    let b: Int = Array(1...30).randomElement()!
    calendar.cgColor = CGColor(red: CGFloat(r) / CGFloat(30), green: CGFloat(g) /  CGFloat(30), blue: CGFloat(b) / CGFloat(30), alpha: 1)
    ekEvent.calendar = calendar
    ekEvent.title = "titleTest \(day)"
    ekEvent.location = "山口県"
    let year = DateObject().getYear(Date())
    let month = DateObject().getMonth(Date())
    ekEvent.startDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: r % 24))
    ekEvent.endDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: r % 24 + 10))
    ekEvent.isAllDay = false
    
    return ekEvent
}

class getInfoMonth {
    init(year: Int, month: Int) {
        let calendar = Calendar.current
        let dateComp = DateComponents(calendar: calendar, timeZone: TimeZone(identifier: "Asia/Tokyo"),year: year, month: month, day: 1)
        let date = calendar.date(from: dateComp)!
        let rangeMonth = calendar.range(of: .day, in: .month, for: date)!
        let noWeekFirstDate = calendar.component(.weekday, from: date)
        
        self.noWeekFirstDate = noWeekFirstDate - 1
        self.rangeMonth = rangeMonth
    }
    
    init(date: Date) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let dateComp = DateComponents(calendar: calendar, timeZone: TimeZone(identifier: "Asia/Tokyo"),year: year, month: month, day: 1)
        let date = calendar.date(from: dateComp)!
        let rangeMonth = calendar.range(of: .day, in: .month, for: date)!
        let noWeekFirstDate = calendar.component(.weekday, from: date)
        
        self.noWeekFirstDate = noWeekFirstDate - 1
        self.rangeMonth = rangeMonth
    }
    
    func getDay(_ row: Int, _ column: Int, _ carryover: Int) -> Int {
        return (row * 7 + column + 1) - carryover
    }
    
    func getWeek(calendar: Calendar = Calendar.current) -> [String] {
        var calendar = calendar
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar.shortWeekdaySymbols
    }
    
    var noWeekFirstDate: Int
    var rangeMonth: Range<Int>
}

struct MonthCalendar_Previews: PreviewProvider {
    static var previews: some View {
        MonthCalendar(YEAR: 2023, MONTH: 11, eventData: EventData(), selectedEventDate: Binding.constant(Date()), showEvents: Binding.constant(false))
    }
}
