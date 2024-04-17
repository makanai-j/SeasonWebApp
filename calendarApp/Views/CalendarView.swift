//
//  CalendarView.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/13.
//

import SwiftUI
import RealmSwift
import Foundation
import EventKit

struct CalendarView: View {
    @EnvironmentObject private var customColor: CustomColor
    private var eventData: EventData = EventData()
    //let realm = try! Realm()
    //@ObservedObject private var shoptable: modelData
    @ObservedObject private var dateObj: DateObject = DateObject()
    @State private var selection: Int = 0
    
    @State private var selectedEventDate: Date?
    @State private var showEvents: Bool = false
    private var selectedDateEvents: [EKEvent]? {
        if let eventDate = selectedEventDate {
            let ekEvents = eventData.eventController.getEvents(date: eventDate)
            return !ekEvents.isEmpty ? ekEvents : nil
        } else {
            return nil
        }
    }
    
    // イベント追加画面
    @State private var showAddEventView: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let CONTENT_HEIGHT = height - 45
            let CALENDAR_WIDTH = width - 8
            var CALENDAR_EVENT_HEIGHT: CGFloat {
                if !showEvents {
                    return CONTENT_HEIGHT
                } else {
                    return CONTENT_HEIGHT / 2
                }
            } 
            let padding: CGFloat = 5
            
            ZStack {
                customColor.homeBack.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    // トップバー
                    HStack {
                        Text("\(dateObj.yearView.description)年\(dateObj.monthView)月")
                            .foregroundColor(customColor.backGround)
                            .font(.system(size: 20, weight: .bold))
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                        Spacer()
                        
                        Button{
                            withAnimation(.easeInOut) {
                                dateObj.yearView = dateObj.getYear()
                                dateObj.monthView = dateObj.getMonth()
                                selection = 0
                            }
                        } label: {
                            Image(systemName: "v.square.fill")
                                .foregroundColor(customColor.backGround)
                                .font(.system(size: 20))
                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                        }
                        
                        Button{
                            showAddEventView.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(customColor.backGround)
                                .font(.system(size: 20, weight: .bold))
                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                        }
                        .sheet(isPresented: $showAddEventView) {
                            AddEventView()
                                //.environmentObject(eventData)
                        }
                        
                        Button{
                            //kari -----
                            selectedEventDate = nil
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(customColor.backGround)
                                .font(.system(size: 20, weight: .bold))
                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                        }
                    }
                    
                    // カレンダーの日付にtapgestureを追加---------------------------------------------------
                    // カレンダー と　イベント
                    VStack {
                        // カレンダー
                        VStack(spacing: 0) {
                            TabView(selection: $selection) {
                                MonthCalendar(YEAR: dateObj.yearView, MONTH: dateObj.monthView - 1, eventData: eventData, selectedEventDate: $selectedEventDate, showEvents: $showEvents)
                                    .background(.white)
                                    .frame(width: CALENDAR_WIDTH)
                                    .cornerRadius(5)
                                    .tag(-1)
                                
                                MonthCalendar(YEAR: dateObj.yearView, MONTH: dateObj.monthView, eventData: eventData, selectedEventDate: $selectedEventDate, showEvents: $showEvents)
                                    .background(.white)
                                    .frame(width: CALENDAR_WIDTH)
                                    .cornerRadius(5)
                                    .onDisappear() {
                                        
                                        if selection != 0 {
                                            dateObj.updateDateObj(selection: selection)
                                            selection = 0
                                        }
                                    }
                                    .tag(0)
                                
                                MonthCalendar(YEAR: dateObj.yearView, MONTH: dateObj.monthView + 1, eventData: eventData, selectedEventDate: $selectedEventDate, showEvents: $showEvents)
                                    .background(.white)
                                    .frame(width: CALENDAR_WIDTH)
                                    .cornerRadius(5)
                                    .tag(1)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                        }
                        .frame(height: CALENDAR_EVENT_HEIGHT - padding)
                        .animation(.default, value: showEvents)
                        
                        Spacer()
                        // イベント
                        if showEvents,
                        let ekEvents = selectedDateEvents{
                            VStack(spacing: 0) {
                                EventList(ekEvents, target: selectedEventDate!)
                                    .foregroundStyle(customColor.backGround)
                            }
                            .frame(height: CALENDAR_EVENT_HEIGHT - padding)
                            .zIndex(-1)
                            .animation(.default, value: showEvents)
                        }
                    }
                    .frame(height: CONTENT_HEIGHT)
                    
                    Spacer()
                }
            }
            
        }
    }
}

enum dateElements {
    case year
    case month
    case week
    case day
    case hour
    case minute
}

class DateObject: ObservableObject {
    var year: Int
    var month: Int
    @Published var yearView: Int
    @Published var monthView: Int
    @Published var viewDate: Date
    var rangeMonth: [Int] = Array<Int>(-2...2)
    let calendar: Calendar
    
    init(viewDate: Date = Date()) {
        self.viewDate = viewDate
        self.year = Calendar.current.component(.year, from: viewDate)
        self.month = Calendar.current.component(.month, from: viewDate)
        self.yearView = year
        self.monthView = month
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? calendar.timeZone
        calendar.locale = Locale(identifier: "ja_JP")
        self.calendar = calendar
    }
    
    func initializObj(date: Date) {
        self.viewDate = date
        self.rangeMonth = Array<Int>(-2...2)
        self.year = Calendar.current.component(.year, from: date)
        self.month = Calendar.current.component(.month, from: date)
        self.yearView = year
        self.monthView = month
    }
    
    func updateDateObj(selection: Int) {
        if selection < 0 {
            self.monthView -= 1
            if self.monthView < 1 {
                self.monthView = 12
                self.yearView -= 1
            }
        } else {
            self.monthView += 1
            if self.monthView > 12 {
                self.monthView = 1
                self.yearView += 1
            }
        }
    }
    
    func getYear(_ date: Date = Date()) -> Int {
        calendar.component(.year, from: date)
    }
    func getMonth(_ date: Date = Date()) -> Int {
        calendar.component(.month, from: date)
    }
    func getDay(_ date: Date = Date()) -> Int {
        calendar.component(.day, from: date)
    }
    func getHour(_ date: Date = Date()) -> Int {
        calendar.component(.hour, from: date)
    }
    func getMinute(_ date: Date = Date()) -> Int {
        calendar.component(.minute, from: date)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(CustomColor(foreGround: .black, backGround: .white))
            .environmentObject(EventData())
    }
}
