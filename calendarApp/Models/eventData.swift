//
//  eventData.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/08.
//

import Foundation
import SwiftUI
import RealmSwift
import EventKitUI


class EventData: ObservableObject {
    var eventStore: EKEventStore
    
    @Published var ekEvent: EKEvent
    @Published var eventController: EventControllerClass
    // 日付が過ぎると消去
    @Published var isDeleteAfterEndDate: Bool
    
    @Published var isAllDay: Bool = false
    // 最初に表示するカレンダー
    var defaultCalendar: EKCalendar? {
        eventController.getCalendars().isEmpty ? nil : eventController.getCalendars()[0]
    }
    
    @Published var currentCalendar: EKCalendar?
    
    @Published var visibleSwitch: visibleDateTime = .invisible
    
    static func compareStartEnd(ekEvent: EKEvent, date: Date) -> Void {
        let start: Date = ekEvent.startDate
        let end:   Date = ekEvent.endDate
        if start > end {
            ekEvent.startDate = date
            ekEvent.endDate =   date
        }
    }
    
    init(isDeleteAfterEndDate: Bool = false) {
        self.eventStore = EKEventStore()
        self.ekEvent = EKEvent(eventStore: eventStore)
        self.eventController = EventControllerClass(eventStore: eventStore)
        self.isDeleteAfterEndDate = isDeleteAfterEndDate
        self.currentCalendar = eventController.getCalendars().isEmpty ? nil : eventController.getCalendars()[0]
        self.ekEvent.calendar = self.currentCalendar
        
        let calendar = DateObject().calendar
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: Date())
        let startDate = calendar.date(from: components)!
        self.ekEvent.startDate = startDate
        
        components.second = 30
        let endDate = calendar.date(from: components)!
        self.ekEvent.endDate = endDate
    }
    
    func initializeObj(isDeleteAfterEndDate: Bool = false) {
        self.eventStore = EKEventStore()
        self.ekEvent = EKEvent(eventStore: eventStore)
        self.eventController = EventControllerClass(eventStore: eventStore)
        self.isDeleteAfterEndDate = isDeleteAfterEndDate
        self.currentCalendar = eventController.getCalendars().isEmpty ? nil : eventController.getCalendars()[0]
        self.ekEvent.calendar = self.currentCalendar
        
        let calendar = DateObject().calendar
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: Date())
        let startDate = calendar.date(from: components)!
        self.ekEvent.startDate = startDate
        
        components.second = 30
        let endDate = calendar.date(from: components)!
        self.ekEvent.endDate = endDate
    }
}

enum visibleDateTime: Int {
    case startDate = 0
    case startTime = 1
    case endDate   = 2
    case endTime   = 3
    case invisible = 5
}

protocol EventController {
    var eventStore: EKEventStore { get }
    
    // アクセス状況を確認
    func checkAccess() -> Bool
    
    // 各処理
    // 取得
    func getEvents(startDate: Date?, endDate: Date?) -> [EKEvent]
    func getCalendars() -> [EKCalendar]
    // イベント追加
    func addEvent(calendar: EKCalendar,
                  title: String,
                  startDate: Date,
                  endDate: Date,
                  isAllDay: Bool,
                  location: String?,
                  timeZone: TimeZone,
                  url: URL?,
                  notes: String?, // メモ
                  recurrenceRules: [EKRecurrenceRule]?) -> Bool
    // カレンダー追加
    func addCalendar(nameCalendar: String, cgColor: CGColor) -> Bool
    // 消去
    func removeEvent(idEvent: String) -> Bool
}

// 純正カレンダーとの連絡
class EventControllerClass: EventController, ObservableObject {
    var eventStore: EKEventStore
    var calendar: Calendar
    
    init (eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.calendar = DateObject().calendar
        if !checkAccess() {
            self.eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if granted && error == nil {
                    print("許可")
                }
            })
        }
    }
    
    func checkAccess() -> Bool {
        let eventStoreStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch eventStoreStatus {
        case .authorized: // 許可済み
            return true
        case .denied: // 拒否
            return false
        case .notDetermined: // 未選択
            return false
        case .restricted: // 非許可
            return false
        default:
            return false
        }
    }
    
    func requestAccess() async -> Bool {
        if !checkAccess() {
            if #available(iOS 17.0, *) {
                    self.eventStore.requestFullAccessToEvents { granted, error in
                        if granted && error == nil {
                            print("許可")
                        } else {
                        }
                    }
            } else {
                // Fallback on earlier versions
                self.eventStore.requestAccess(to: .event, completion: { (granted, error) in
                    if granted && error == nil {
                        print("許可")
                    } else {
                    }
                })
            }
        }
        return checkAccess()
    }
    
    func getEvents(date: Date = Date()) -> [EKEvent] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        let startDate = calendar.date(from: components)
        components.hour = 23
        components.minute = 59
        components.second = 59
        let endDate = calendar.date(from: components)
        let predicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: getCalendars())
        return eventStore.events(matching: predicate)
    }
    
    func getEvents(startDate: Date? = Date(), endDate: Date? = Date()) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: getCalendars())
        return eventStore.events(matching: predicate)
    }
    
    func getEvents(year: Int?, month: Int?) -> [EKEvent] {
        let startDate = calendar.date(from: DateComponents(year: year!, month: month!, day: 1, hour: 0, minute: 0, second: 0))!
        let endDate = calendar.date(from: DateComponents(year: year!, month: month! + 1, day: 0, hour: 23, minute: 59, second: 59))!
        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: getCalendars())
        return self.eventStore.events(matching: predicate)
    }
    
    func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    func addEvent(calendar: EKCalendar,
                  title: String,
                  startDate: Date,
                  endDate: Date,
                  isAllDay: Bool,
                  location: String? = nil,
                  timeZone: TimeZone = TimeZone(identifier: "Asia/Tokyo")!,
                  url: URL? = nil,
                  notes: String? = nil, // メモ
                  recurrenceRules: [EKRecurrenceRule]? = nil // 繰り返しルール
    ) -> Bool {
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.calendar = calendar
        ekEvent.title = title
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.isAllDay = isAllDay
        ekEvent.location = location
        ekEvent.timeZone = timeZone
        ekEvent.url = url
        ekEvent.notes = notes
        ekEvent.recurrenceRules = recurrenceRules
        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            try eventStore.commit()
        } catch  {
            return false
        }
        return true
    }
    
    func addEvent(ekEvent: EKEvent) -> Bool {
        do {
            try self.eventStore.save(ekEvent, span: .thisEvent, commit: true)
        } catch  {
            return false
        }
        return true
    }

    
    func addCalendar(nameCalendar: String, cgColor: CGColor) -> Bool {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = nameCalendar
        calendar.cgColor = cgColor
        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            return false
        }
        return true
    }
    
    func removeEvent(idEvent: String) -> Bool {
        let event: EKEvent = eventStore.event(withIdentifier: idEvent)!
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            return false
        }
        return true
    }
}

// カレンダーのオブジェクト
class CalendarDataManager {
    var ekEvent: EKEvent?
    // 日跨ぎの途中
    var isSpan: passageType
    
    enum passageType: Int {
        case beginning = 1
        case span = 2
        case end = 3
        case disabled = 4
    }
    
    init(ekEvent: EKEvent, isSpan: passageType) {
        self.ekEvent = ekEvent
        self.isSpan = isSpan
    }
}
