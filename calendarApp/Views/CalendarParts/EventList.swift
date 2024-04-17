//
//  EventList.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/11/05.
//

import SwiftUI
import EventKit

struct EventList: View {
    let ekEvents: [EKEvent]
    let startDate: Date
    let endDate: Date
    let targetDate: Date?
    
    let isOverMonth: Bool
    
    init(_ ekEvents: [EKEvent], start: Date, end: Date) {
        self.startDate = start
        self.endDate = end
        self.targetDate = nil
        
        let dateObj: DateObject = DateObject()
        if dateObj.getMonth(start) != dateObj.getMonth(end) {
            isOverMonth = true
        } else {
            isOverMonth = false
        }
        self.ekEvents = ekEvents
            .filter({!(start > $0.endDate || $0.startDate > end)})
            .sorted(by: {$0.startDate < $1.startDate})
    }
    
    init(_ ekEvents: [EKEvent], target: Date) {
        self.targetDate = target
        let dateObj: DateObject = DateObject()
        
        let startDateComp = DateComponents(calendar: dateObj.calendar, timeZone: TimeZone(identifier: "Asia/Tokyo"), year: dateObj.getYear(target), month: dateObj.getMonth(target), day: dateObj.getDay(target), hour: 0, minute: 0, second: 0)
        let start = dateObj.calendar.date(from: startDateComp)!
        self.startDate = start
        
        let endDateComp = DateComponents(calendar: dateObj.calendar, timeZone: TimeZone(identifier: "Asia/Tokyo"), year: dateObj.getYear(target), month: dateObj.getMonth(target), day: dateObj.getDay(target), hour: 23, minute: 59, second: 59)
        let end = dateObj.calendar.date(from: endDateComp)!
        self.endDate = end
        
        self.ekEvents = ekEvents
            .filter({!(start > $0.endDate || $0.startDate > end)})
            .sorted(by: {$0.startDate < $1.startDate})
        
        isOverMonth = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ScrollView {
                LazyVStack(alignment: .center) {
                    ForEach(ekEvents, id: \.self) { ekEvent in
                        if let date = targetDate {
                            EventSealLong(ekEvent, date: date, period: .day)
                                .frame(width: width * 0.9, height: 50)
                        } else {
                            if isOverMonth {
                                EventSealLong(ekEvent, period: .year)
                                    .frame(width: width * 0.9, height: 50)
                            } else {
                                EventSealLong(ekEvent, period: .month)
                                    .frame(width: width * 0.9, height: 50)
                            }
                        }
                    }
                }
                .frame(width: width, alignment: .center)
            }
        }
    }
}

struct EventSealLong: View {
    let ekEvent: EKEvent
    var isAllDayStart: Bool = false
    var isAllDayend:   Bool = false
    var startTime: String
    var endTime:   String
    
    let period: dateElements
    
    @State private var infoSelection: infoElements?
    @State private var showEventSheet: Bool = false
    
    init(_ ekEvent: EKEvent, date: Date? = Date(), period: dateElements = .day) {
        self.ekEvent = ekEvent
        
        self.period = period
        
        let dateObj: DateObject = DateObject()
        
        switch period {
        case .year:
            self.startTime = "\(dateObj.getMonth(ekEvent.startDate)) / \(dateObj.getDay(ekEvent.startDate))"
            self.endTime   = "\(dateObj.getMonth(ekEvent.endDate)) / \(dateObj.getDay(ekEvent.endDate))"
        case .month:
            self.startTime = "\(dateObj.getDay(ekEvent.startDate))"
            self.endTime   = "\(dateObj.getDay(ekEvent.endDate))"
        default:
            // 終日チェック
            let day: Int = dateObj.getDay(date!)
            let startDate: Int = dateObj.getDay(ekEvent.startDate)
            let endDate: Int = dateObj.getDay(ekEvent.endDate)
            
            if startDate == day {
                startTime = "\(dateObj.getHour(ekEvent.startDate)):\(String(format: "%02d", (dateObj.getMinute(ekEvent.startDate))))"
                
                if 0 == dateObj.getHour(ekEvent.startDate)
                    && 0 == dateObj.getMinute(ekEvent.startDate) {
                    isAllDayStart = true
                } else {
                    isAllDayStart = false
                }
            } else {
                startTime = ""
                isAllDayStart = true
            }
            
            if endDate == day {
                endTime = "\(dateObj.getHour(ekEvent.endDate)):\(String(format: "%02d", (dateObj.getMinute(ekEvent.endDate))))"
                
                if 23 == dateObj.getHour(ekEvent.endDate)
                    && 59 == dateObj.getMinute(ekEvent.endDate) {
                    isAllDayend = true
                } else {
                    isAllDayend = false
                }
            } else {
                endTime = ""
                isAllDayend = true
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width
            let height: CGFloat = geometry.size.height
            let padding: CGFloat = 10
            let rectangleWidth: CGFloat = 15
            let triangleSize: CGFloat = 8
            let timeWidth: CGFloat = 60
            let locationSize: CGFloat = 10
            let infoCircleSize: CGFloat = 20
            let titleWidth: CGFloat = width - rectangleWidth - timeWidth - infoCircleSize - (padding * 2)
            let titleHeight: CGFloat = height - padding
            let centerSpace: CGFloat = height * 0.05
            HStack(spacing: 0) {
                // カレンダー色の図形
                RoundedRectangle(cornerRadius: width, style: .circular)
                    .fill(Color(ekEvent.calendar.cgColor))
                    .frame(width: rectangleWidth)
                HStack {
                    // 日付
                    VStack( alignment: .trailing, spacing: 0) {
                        switch period {
                        case .year:
                            if startTime == endTime {
                                Text("\(startTime)")
                            } else {
                                Text("\(startTime)")
                                Text("\(endTime)")
                            }
                        case .month:
                            if startTime == endTime {
                                Text("\(startTime)")
                            } else {
                                HStack {
                                    Text("\(startTime)")
                                    Image(systemName: "triangle.fill")
                                        .resizable()
                                        .frame(width: triangleSize, height: triangleSize)
                                        .rotationEffect(Angle(degrees: 90))
                                        .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                                    Text("\(endTime)")
                                }
                            }
                        default:
                            if isAllDayStart && isAllDayend {
                                Text("終日")
                            } else {
                                Spacer()
                                Text(startTime)
                                Text(endTime)
                                Spacer()
                            }
                        }
                    }
                    .font(.system(size: 15))
                    .frame(width: timeWidth)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        // 場所
                        if let location = ekEvent.location {
                            HStack {
                                Image("location_on")
                                    .resizable()
                                    .frame(width: locationSize * 0.8, height: locationSize)
                                    .foregroundColor(.blue)
                                Text("\(location)")
                                    .font(.system(size: 13))
                            }
                        } else {
                            Text(" ")
                                .font(.system(size: 13))
                        }
                        Spacer()
                            .frame(height: centerSpace)
                        // タイトル
                        Text("\(ekEvent.title)")
                            .font(.system(size: 17, weight: .bold))
                        Spacer()
                    }
                    .frame(width: titleWidth, height: titleHeight, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showEventSheet.toggle()
                    }
                }
                
                Menu {
                    Button {
                        infoSelection = .copy
                    } label: {
                        Text("イベントを複製").tag(infoElements.copy)
                    }
                    Divider()
                    if ekEvent.location != nil {
                        Button {
                            infoSelection = .location
                        } label: {
                            Text("マップを表示").tag(infoElements.location)
                        }
                    }
                    if ekEvent.url != nil {
                        Button {
                            infoSelection = .url
                        } label: {
                            Text("ブラウザを表示").tag(infoElements.url)
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        infoSelection = .delete
                    } label: {
                        Label("消去", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .resizable()
                        .frame(width: infoCircleSize, height: infoCircleSize)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(padding)
                }
                .menuOrder(.fixed)
            }
            .lineLimit(1)
            .sheet(isPresented: $showEventSheet) {
                Text("\(ekEvent)")
            }
        }
    }
    
    enum infoElements: String, CaseIterable {
        case copy = "イベントを複製"
        case location = "マップを表示"
        case url = "ブラウザを表示"
        case delete = "消去"
    }
}
/*
struct EventSealLong: View {
    let ekEvent: EKEvent
    let isAllDayStart: Bool
    let isAllDayend:   Bool
    var startTime: String
    var endTime:   String
    let dateElement: dateElements
    
    @State private var infoSelection: infoElements?
    @State private var showEventSheet: Bool = false
    
    init(_ ekEvent: EKEvent = createEvent(day: 11), date: Date = Date(), dateElement: dateElements) {
        self.ekEvent = ekEvent
        // 終日チェック
        let dateObj: DateObject = DateObject()
        let day: Int = dateObj.getDay(date)
        let startDate: Int = dateObj.getDay(ekEvent.startDate)
        let endDate: Int = dateObj.getDay(ekEvent.endDate)
        
        switch dateElement {
        case .year:
            self.isAllDayStart = false
            self.isAllDayend = false
            self.startTime = "\(dateObj.getMonth(ekEvent.startDate)) / \(dateObj.getDay(ekEvent.startDate))"
            self.endTime   = "\(dateObj.getMonth(ekEvent.endDate)) / \(dateObj.getDay(ekEvent.endDate))"
        case .month, .week:
            self.isAllDayStart = false
            self.isAllDayend = false
            self.startTime = "\(dateObj.getDay(ekEvent.startDate))"
            self.endTime = "\(dateObj.getDay(ekEvent.endDate))"
        default:
            if startDate == day {
                startTime = "\(dateObj.getHour(ekEvent.startDate)):\(String(format: "%02d", (dateObj.getMinute(ekEvent.startDate))))"
                
                if 0 == dateObj.getHour(ekEvent.startDate)
                    && 0 == dateObj.getMinute(ekEvent.startDate) {
                    isAllDayStart = true
                } else {
                    isAllDayStart = false
                }
            } else {
                startTime = ""
                isAllDayStart = true
            }
            
            if endDate == day {
                endTime = "\(dateObj.getHour(ekEvent.endDate)):\(String(format: "%02d", (dateObj.getMinute(ekEvent.endDate))))"
                
                if 23 == dateObj.getHour(ekEvent.endDate)
                    && 59 == dateObj.getMinute(ekEvent.endDate) {
                    isAllDayend = true
                } else {
                    isAllDayend = false
                }
            } else {
                endTime = ""
                isAllDayend = true
            }
        }
        
        self.dateElement = dateElement
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat  = geometry.size.width
            let height: CGFloat = geometry.size.height
            let padding: CGFloat = 10
            let rectangleWidth: CGFloat = 15
            let triangleSize: CGFloat = 8
            let timeWidth: CGFloat = 60
            let locationSize: CGFloat = 10
            let infoCircleSize: CGFloat = 20
            let titleWidth: CGFloat = width - rectangleWidth - timeWidth - infoCircleSize - (padding * 2)
            let centerSpace: CGFloat = height * 0.05
            HStack(spacing: 0) {
                // カレンダー色の図形
                RoundedRectangle(cornerRadius: width, style: .circular)
                    .fill(Color(ekEvent.calendar.cgColor))
                    .frame(width: rectangleWidth)
                HStack {
                    // 日付
                    VStack( alignment: .trailing, spacing: 0) {
                        switch dateElement {
                        case .year:
                            if startTime == endTime {
                                Text("\(startTime)")
                            } else {
                                /*
                                 VStack( alignment: .leading, spacing: 0) {
                                 Text("\(startTime)")
                                 .padding(EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding))
                                 HStack {
                                 Spacer()
                                 Image(systemName: "triangle.fill")
                                 .resizable()
                                 .frame(width: triangleSize, height: triangleSize)
                                 .rotationEffect(Angle(degrees: 90))
                                 .opacity(0.8)
                                 Text("\(endTime)")
                                 }
                                 }
                                 */
                                
                                Spacer()
                                Text(startTime)
                                Text(endTime)
                                Spacer()
                            }
                        case .month, .week:
                            if startTime == endTime {
                                Text("\(startTime)")
                            } else {
                                HStack {
                                    Text("\(startTime)")
                                    Image(systemName: "triangle.fill")
                                        .resizable()
                                        .frame(width: triangleSize, height: triangleSize)
                                        .rotationEffect(Angle(degrees: 90))
                                        .opacity(0.8)
                                    Text("\(endTime)")
                                }
                            }
                        default:
                            if isAllDayStart && isAllDayend {
                                Text("終日")
                            } else {
                                Spacer()
                                Text(startTime)
                                Text(endTime)
                                Spacer()
                            }
                        }
                    }
                    .font(.system(size: 15))
                    .frame(width: timeWidth)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        // 場所
                        if let location = ekEvent.location {
                            HStack {
                                Image("location_on")
                                    .resizable()
                                    .frame(width: locationSize * 0.8, height: locationSize)
                                    .foregroundColor(.blue)
                                Text("\(location)")
                                    .font(.system(size: 13))
                            }
                        } else {
                            Text(" ")
                                .font(.system(size: 13))
                        }
                        Spacer()
                            .frame(height: centerSpace)
                        // タイトル
                        Text("\(ekEvent.title)")
                            .font(.system(size: 17, weight: .bold))
                        Spacer()
                    }
                    .frame(width: titleWidth, alignment: .leading)
                }
                .background()
                .onTapGesture {
                    showEventSheet.toggle()
                }
                
                Menu {
                    Button {
                        infoSelection = .copy
                    } label: {
                        Text("イベントを複製").tag(infoElements.copy)
                    }
                    Divider()
                    if ekEvent.location != nil {
                        Button {
                            infoSelection = .location
                        } label: {
                            Text("マップを表示").tag(infoElements.location)
                        }
                    }
                    if ekEvent.url != nil {
                        Button {
                            infoSelection = .url
                        } label: {
                            Text("ブラウザを表示").tag(infoElements.url)
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        infoSelection = .delete
                    } label: {
                        Label("消去", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .resizable()
                        .frame(width: infoCircleSize, height: infoCircleSize)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(padding)
                }
                .menuOrder(.fixed)
            }
            .lineLimit(1)
            .sheet(isPresented: $showEventSheet) {
                Text("\(ekEvent)")
            }
        }
    }
    
    enum infoElements: String, CaseIterable {
        case copy = "イベントを複製"
        case location = "マップを表示"
        case url = "ブラウザを表示"
        case delete = "消去"
    }
}

 class EventSheetObject: ObservableObject {
 @Published var showEventSheet: Bool = false
 @Published var
 }
 */

#Preview {
    EventList([createEvent(day: 1), createEvent(day: 2), createEvent(day: 3), createEvent(day: 4),createEvent(day: 5), createEvent(day: 6), createEvent(day: 7), createEvent(day: 8)], target: Date())
}
