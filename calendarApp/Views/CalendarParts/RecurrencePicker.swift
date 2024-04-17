//
//  RecurrencePicker.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/28.
//

import SwiftUI
import EventKit

struct RecurrencePicker: View {
    @Binding var ekEvent: EKEvent
    @State private var isValid: Bool = false
    @StateObject private var recurrenceRuleObj: RecurrenceRuleObj
    
    let date: Date
    
    init(ekEvent: Binding<EKEvent>) {
        self._ekEvent = ekEvent
        let recurrenceRules: [EKRecurrenceRule]? = ekEvent.wrappedValue.recurrenceRules
        self._recurrenceRuleObj = StateObject(wrappedValue: RecurrenceRuleObj(recurrenceRules: recurrenceRules, date: Date()))
        self.date = ekEvent.wrappedValue.startDate
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let paddingTenPer = width / CGFloat(10)
            let paddingTen: CGFloat = 12
            VStack {
                Button {
                    isValid.toggle()
                } label: {
                    HStack(alignment: .top) {
                        Text("繰り返し")
                            .padding(EdgeInsets(top: 0, leading: paddingTenPer, bottom: paddingTen, trailing: 0))
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(recurrenceRuleObj.eventStr)")
                                .font(.system(size: 12, weight: .bold))
                                .frame(minWidth: width / 4)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(width: width / 2, alignment: .trailing)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                .sheet(isPresented: $isValid) {
                    if let complete = recurrenceRuleObj.complete,
                       complete {
                        recurrenceRuleObj.translation(ekEvent: ekEvent)
                    } else {
                        recurrenceRuleObj.initReset(recurrenceRules: self.recurrenceRuleObj.recurrenceRules, date: Date())
                    }
                } content: {
                    RecurrenceSheet(recurrenceRuleObj: recurrenceRuleObj)
                }
                
            }
            .frame(height: 25)
            .padding(EdgeInsets(top: paddingTen, leading: 0, bottom: paddingTen, trailing: 0))
        }
    }
}

struct RecurrenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var recurrenceRuleObj: RecurrenceRuleObj
    @EnvironmentObject private var customColor: CustomColor
    let weeks = getInfoMonth(date: Date()).getWeek()

    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 15
            NavigationStack {
                VStack(spacing: 0) {
                    //ScrollView {
                    Picker("繰り返し", selection: $recurrenceRuleObj.frequency) {
                        Text("しない").tag(Optional<EKRecurrenceFrequency>(nil))
                            .foregroundStyle(customColor.foreGround)
                    }
                    .onChange(of: recurrenceRuleObj.frequency) { fre in
                        if fre == nil { recurrenceRuleObj.interval = 1 }
                        recurrenceRuleObj.reset(frequency: nil)
                        recurrenceRuleObj.reset(frequency: fre)
                        recurrenceRuleObj.switchMonthWeek = true
                        recurrenceRuleObj.isWeekYear = false
                    }
                    .pickerStyle(.segmented)
                    .padding(padding)
                    HStack(spacing: 0) {
                        Text("間隔")
                            .padding(padding)
                        Picker("繰り返し", selection: $recurrenceRuleObj.frequency) {
                            ForEach(recurrenceRuleObj.pickerItem
                                .sorted(by: { $0.value.rawValue < $1.value.rawValue })
                                .map{ $0.key }, id: \.self) { key in
                                    Text(key).tag(recurrenceRuleObj.pickerItem[key])
                                        .foregroundStyle(customColor.foreGround)
                                }
                        }
                        .pickerStyle(.segmented)
                        .padding(padding)
                    }
                    if recurrenceRuleObj.isValid {
                        Text("\(recurrenceRuleObj.eventStr)\(recurrenceRuleObj.frequency == .daily && recurrenceRuleObj.interval == 1 ? "" : "に")あるイベント")
                            .font(.system(size: 11))
                            .padding(EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding))
                            .frame(width: width, alignment: .leading)
                    }
                    
                    //日/その他----------------------------------------------
                    HStack(spacing: 0) {
                        if recurrenceRuleObj.isValid {
                            VerticalWheelPicker(initialCenterItem: recurrenceRuleObj.interval, numItem: 3, items: Array(1...555)) { item in
                                Text(item == 1 ? "毎" : "\(item)")
                                    .font(.system(size: 14))
                            } onChangeEvent: { item in
                                recurrenceRuleObj.interval = item
                            }
                            .frame(width: 30, height: (height * 0.2) * 0.7)
                            .padding(EdgeInsets(top: 0, leading: width / 2 - 15, bottom: 0, trailing: 0))
                            Text(recurrenceRuleObj.intervalUnit)
                                .font(.system(size: 11))
                                .padding(5)
                        }
                    }
                    .frame(width: width, height: height * 0.16, alignment: .leading)
                    .padding(EdgeInsets(top: padding, leading: 0, bottom: padding * 2, trailing: 0))
                    .animation(.easeIn, value: recurrenceRuleObj.isValid)
                    
                    switch recurrenceRuleObj.frequency {
                        //週----------------------------------------------------
                    case .weekly:
                        HStack(spacing: 0) {
                            ForEach(1...weeks.count, id: \.self) { weekDay in
                                Button {
                                    if recurrenceRuleObj.daysWeekToInt.contains(weekDay) {
                                        recurrenceRuleObj.removeDayWeek(dayWeek: weekDay)
                                    } else {
                                        recurrenceRuleObj.addDayWeek(dayWeek: weekDay)
                                    }
                                } label: {
                                    Text(weeks[weekDay - 1])
                                        .font(.system(size: 14))
                                        .underline(color:
                                                    Calendar.current.component(.weekday, from: Date()) == weekDay ?
                                                   (recurrenceRuleObj.daysWeekToInt.contains(weekDay) ? customColor.backGround : customColor.foreGround ) : .clear
                                        )
                                        .foregroundStyle(recurrenceRuleObj.daysWeekToInt.contains(weekDay) ? customColor.backGround : customColor.foreGround)
                                        .frame(width: 26, height: 26)
                                        .background(recurrenceRuleObj.daysWeekToInt.contains(weekDay) ? customColor.foreGround : customColor.backGround)
                                        .cornerRadius(13)
                                        .frame(width: abs(width - padding) / 7)
                                }
                            }
                        }
                        //月----------------------------------------------------
                    case .monthly:
                        Picker("月か曜日", selection: $recurrenceRuleObj.switchMonthWeek) {
                            Text("日付").tag(true)
                            Text("曜日").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: width / 2)
                        if recurrenceRuleObj.switchMonthWeek {
                            VStack(spacing: 0) {
                                ForEach(0..<5, id: \.self) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<7, id: \.self) { column in
                                            let day = row * 7 + (column + 1)
                                            if 1...31 ~= day {
                                                Button {
                                                    if recurrenceRuleObj.daysMonthToInt.contains(day){
                                                        recurrenceRuleObj.removeDayMonth(day: day)
                                                    } else {
                                                        recurrenceRuleObj.addDayMonth(day: day)
                                                    }
                                                } label: {
                                                    Text("\(day)")
                                                        .font(.system(size: 13))
                                                        .underline(color:
                                                                    Calendar.current.component(.day, from: Date()) == day ?
                                                                   (recurrenceRuleObj.daysMonthToInt.contains(day) ? customColor.backGround : customColor.foreGround ) : .clear
                                                        )
                                                        .foregroundStyle(recurrenceRuleObj.daysMonthToInt.contains(day) ? customColor.backGround : customColor.foreGround)
                                                }
                                                .frame(width: 26, height: 26)
                                                .background(recurrenceRuleObj.daysMonthToInt.contains(day) ? customColor.foreGround : customColor.backGround)
                                                .cornerRadius(13)
                                                .clipped()
                                                .padding()
                                                .frame(width: abs(floor((width - padding) / 7)), height: (height * 0.4) / 5)
                                            } else {
                                                Text("")
                                                    .frame(width: abs(width - padding) / 7)
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            HStack(spacing: 0) {
                                VerticalWheelPicker(initialCenterItem: recurrenceRuleObj.selectedSetPositions, numItem: 3, items: recurrenceRuleObj.numWeekMonth) { num in
                                    Text(num != -1 ? "第\(num)" : "最後" )
                                } onChangeEvent: { num in
                                    recurrenceRuleObj.setPositions = [NSNumber(value: num)]
                                }
                                .frame(width: 50, height: 120)
                                .padding(EdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0))
                                
                                VerticalWheelPicker(initialCenterItem: recurrenceRuleObj.selectedMonthWeekItem, numItem: 3, items: recurrenceRuleObj.monthWeekItem) { item in
                                    Text(item)
                                } onChangeEvent: { item in
                                    recurrenceRuleObj.selectedDaysWeek = recurrenceRuleObj.ekMonthWeekItem[item]!.map { EKRecurrenceDayOfWeek(EKWeekday(rawValue: $0)!) }
                                }
                                .frame(width: 100,height: 120)
                                .padding(EdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0))
                            }
                            
                        }
                        //年----------------------------------------------------
                    case .yearly:
                        ForEach(0..<2, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<6, id: \.self) { column in
                                    let month = row * 6 + column + 1
                                    Button {
                                        if recurrenceRuleObj.monthsYearToInt.contains(month) {
                                            recurrenceRuleObj.removeMonthYear(month: month)
                                        } else {
                                            recurrenceRuleObj.addMonthYear(month: month)
                                        }
                                    } label: {
                                        Text("\(month)")
                                            .font(.system(size: 13))
                                            .underline(color:
                                                        Calendar.current.component(.month, from: Date()) == month ?
                                                       (recurrenceRuleObj.monthsYearToInt.contains(month) ? customColor.backGround : customColor.foreGround ) : .clear
                                            )
                                            .foregroundStyle(recurrenceRuleObj.monthsYearToInt.contains(month) ? customColor.backGround : customColor.foreGround)
                                            .frame(width: 26, height: 26)
                                            .background(recurrenceRuleObj.monthsYearToInt.contains(month) ? customColor.foreGround : customColor.backGround)
                                            .cornerRadius(13)
                                            .frame(width: abs(width - padding) / 7)
                                            .padding(EdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0))
                                    }
                                    .frame(width: abs(width - padding) / 6, height: 50)
                                }
                            }
                        }
                        VStack {
                            Toggle("曜日", isOn: $recurrenceRuleObj.isWeekYear)
                                .frame(width: 100)
                                .padding(padding)
                                .frame(width: width, alignment: .trailing)
                            if recurrenceRuleObj.isWeekYear {
                                HStack(spacing: 0) {
                                    VerticalWheelPicker(initialCenterItem: recurrenceRuleObj.selectedSetPositions, numItem: 3, items: recurrenceRuleObj.numWeekMonth) { num in
                                        Text(num != -1 ? "第\(num)" : "最後" )
                                    } onChangeEvent: { num in
                                        recurrenceRuleObj.setPositions = [NSNumber(value: num)]
                                    }
                                    .frame(width: 50, height: 120)
                                    .padding(EdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0))
                                    
                                    VerticalWheelPicker(initialCenterItem: recurrenceRuleObj.selectedMonthWeekItem, numItem: 3, items: recurrenceRuleObj.monthWeekItem) { item in
                                        Text(item)
                                    } onChangeEvent: { item in
                                        recurrenceRuleObj.selectedDaysWeek = recurrenceRuleObj.ekMonthWeekItem[item]!.map { EKRecurrenceDayOfWeek(EKWeekday(rawValue: $0)!)
                                        }
                                    }
                                    .frame(width: 100,height: 120)
                                    .padding(EdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0))
                                }
                            }
                        }
                        .animation(.default, value: recurrenceRuleObj.isWeekYear)
                        .onAppear {
                            recurrenceRuleObj.reset(frequency: .monthly, element: .week)
                        }
                        
                    default:
                        Spacer()
                    }
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar() {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            recurrenceRuleObj.complete = false
                            dismiss()
                        } label: {
                            Text("キャンセル")
                                .foregroundStyle(customColor.cancel)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("繰り返し")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            recurrenceRuleObj.complete = true
                            dismiss()
                        } label: {
                            Text("完了")
                                .foregroundStyle(customColor.complete)
                        }
                    }
                }
                .background(customColor.backGround)
                .foregroundStyle(customColor.foreGround)
            }
        }
    }
}

class RecurrenceRuleObj: ObservableObject {
    @Published var recurrenceRules: [EKRecurrenceRule]?
    @Published var frequency: EKRecurrenceFrequency?
    @Published var recurrenceEnd: EKRecurrenceEnd?
    @Published var interval: Int = 1
    @Published var selectedDaysWeek: [EKRecurrenceDayOfWeek]?
    @Published var selectedDaysMonth: [NSNumber]?
    @Published var selectedDaysYear: [NSNumber]?
    @Published var selectedWeeksYear: [NSNumber]?
    @Published var selectedMonthsYear: [NSNumber]?
    @Published var setPositions: [NSNumber]?
    var date: Date
    
    @Published var switchMonthWeek: Bool = true
    @Published var isWeekYear: Bool = false
    var complete: Bool?
    
    init(recurrenceRules: [EKRecurrenceRule]?, date: Date) {
        self.recurrenceRules = recurrenceRules
        if recurrenceRules != nil {
            for rule in recurrenceRules! {
                self.frequency = rule.frequency
                if rule.recurrenceEnd != nil { self.recurrenceEnd = rule.recurrenceEnd }
                self.interval = rule.interval
                if rule.daysOfTheWeek != nil { self.selectedDaysWeek = rule.daysOfTheWeek }
                if rule.daysOfTheMonth != nil { self.selectedDaysMonth = rule.daysOfTheMonth }
                if rule.daysOfTheYear != nil { self.selectedDaysYear = rule.daysOfTheYear }
                if rule.weeksOfTheYear != nil { self.selectedWeeksYear = rule.weeksOfTheYear }
                if rule.monthsOfTheYear != nil { self.selectedMonthsYear = rule.monthsOfTheYear }
                if rule.setPositions != nil { self.setPositions = rule.setPositions }
            }
        }
        self.date = date
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")
        self.monthWeekItem = calendar.weekdaySymbols + ["平日","週末","日"]
        self.ekMonthWeekItem = [
            self.monthWeekItem[0]: [1],
            self.monthWeekItem[1]: [2],
            self.monthWeekItem[2]: [3],
            self.monthWeekItem[3]: [4],
            self.monthWeekItem[4]: [5],
            self.monthWeekItem[5]: [6],
            self.monthWeekItem[6]: [7],
            self.monthWeekItem[7]: [2,3,4,5,6],
            self.monthWeekItem[8]: [1,7],
            self.monthWeekItem[9]: [1,2,3,4,5,6,7]
        ]
}
    
    let pickerItem = [
        "日": EKRecurrenceFrequency.daily,
        "週": EKRecurrenceFrequency.weekly,
        "月": EKRecurrenceFrequency.monthly,
        "年": EKRecurrenceFrequency.yearly,
    ]
    
    let numWeekMonth = [
        1,
        2,
        3,
        4,
        5,
        -1
    ]
    
    let monthWeekItem: [String]
    
    let ekMonthWeekItem: [String: [Int]]
    
    var intervalUnit: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "日" : "日 おき"
        case .weekly:
            return interval == 1 ? "週" : "週 おき"
        case .monthly:
            return interval == 1 ? "月" : "ヶ月 おき"
        case .yearly:
            return interval == 1 ? "年" : "年 おき"
        default:
            return ""
        }
    }
    
    var isValid: Bool {
        self.frequency == nil ? false : true
    }
    
    var daysWeekToInt: [Int] {
        guard let daysWeek = self.selectedDaysWeek else { return [-1] }
        return daysWeek.map { $0.dayOfTheWeek.rawValue }
    }
    
    var selectedMonthWeekItem: String {
        guard let element = self.ekMonthWeekItem.first(where: {
            $0.value == daysWeekToInt.sorted(by: { $0 < $1 })
        }) else { return self.monthWeekItem[0] }
        
        return element.key
    }
    
    var selectedSetPositions: Int {
        guard let setPositions = self.setPositions else { return self.numWeekMonth[0] }
        return setPositions.first!.intValue
    }
    
    var daysMonthToInt: [Int] {
        guard let daysMonth = self.selectedDaysMonth else { return [-1] }
        return daysMonth.map { $0.intValue }
    }
    
    var monthsYearToInt: [Int] {
        guard let monthsYear = self.selectedMonthsYear else { return [-1] }
        return monthsYear.map { $0.intValue }
    }
    
    var eventStr: String {
        let interval = self.interval
        var str = "\(interval == 1 ? "毎" : "\(interval)")\(self.intervalUnit)"
        let freq = self.frequency
        switch freq {
        case .daily:
            guard interval != 1 else { break }
            str = "\(str)"
        case .weekly:
            var weekStr = ""
            guard daysWeekToInt.first != -1 else { return "weekStr" }
            let weeksLong = daysWeekToInt.sorted(by: { $0 < $1 }).map({ getInfoMonth(date: Date()).getWeek()[$0 - 1] })
            for week in weeksLong {
                weekStr = "\(weekStr)\(weeksLong.firstIndex(of: week) == 0 ? " " : "、")\(week)曜日"
            }
            str = "\(str)\( weekStr )"
        case .monthly:
            if self.switchMonthWeek {
                var dayStr = ""
                guard daysMonthToInt.first != -1 else { return dayStr }
                let days = daysMonthToInt.sorted(by: { $0 < $1 })
                for day in days {
                    dayStr = "\(dayStr)\(days.firstIndex(of: day) == 0 ? " " : "、")\(day)日"
                }
                str = "\(str)\(dayStr)"
            } else {
                guard let setPositions = self.setPositions else { return "" }
                str = "\(str)\(setPositions[0].intValue != -1 ? "第\(setPositions[0].intValue)" : "最後の" )\(selectedMonthWeekItem)"
            }
        case .yearly:
            var monthStr = ""
            let months = monthsYearToInt.sorted(by: { $0 < $1 })
            guard months.first != -1 else { return monthStr }
            for month in months {
                monthStr = "\(monthStr)\(month)月\(months.firstIndex(of: month) == months.count - 1 ? (self.isWeekYear ? "の" : "") : "、")"
            }
            str = "\(str)\(monthStr)"
            if self.isWeekYear {
                guard let setPositions = self.setPositions else { return "" }
                str = "\(str)\(setPositions[0].intValue != -1 ? "第\(setPositions[0].intValue)" : "最後の" )\(selectedMonthWeekItem)"
            }
        default:
            return "なし"
        }
        
        return "\(str)"//\(freq == .daily && interval == 1 ? "" : "に")あるイベント"//recurrenceRuleObj.eventStr!
    }
    
    func addDayWeek(dayWeek: Int) {
        if self.selectedDaysWeek == nil
            || !self.selectedDaysWeek!.map({ $0.dayOfTheWeek.rawValue }).contains(dayWeek) {
            selectedDaysWeek?.append(EKRecurrenceDayOfWeek(EKWeekday(rawValue: dayWeek)!))
        }
    }
    
    func removeDayWeek(dayWeek: Int) {
        guard let daysWeek = self.selectedDaysWeek else { return }
        if daysWeek.count > 1 {
            self.selectedDaysWeek = self.selectedDaysWeek?.filter { $0.dayOfTheWeek.rawValue != dayWeek }
        }
    }
    
    func addDayMonth(day: Int) {
        if self.selectedDaysMonth == nil
            || !self.selectedDaysMonth!.map({ $0.intValue }).contains(day) {
            selectedDaysMonth?.append(NSNumber(value: day))
        }
    }
    
    func removeDayMonth(day: Int) {
        guard let daysMonth = self.selectedDaysMonth else { return }
        if daysMonth.count > 1 {
            self.selectedDaysMonth = self.selectedDaysMonth?.filter { $0.intValue != day }
        }
    }
    
    func addMonthYear(month: Int) {
        if self.selectedMonthsYear == nil
            || !self.selectedMonthsYear!.map({ $0.intValue }).contains(month) {
            selectedMonthsYear?.append(NSNumber(value: month))
        }
    }
    
    func removeMonthYear(month: Int) {
        guard let daysMonth = self.selectedMonthsYear else { return }
        if daysMonth.count > 1 {
            self.selectedMonthsYear = self.selectedMonthsYear?.filter { $0.intValue != month }
        }
    }
    
    
    
    func reset(frequency: EKRecurrenceFrequency?, element: dateElements? = nil) {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            let weekDay = calendar.component(.weekday, from: date)
            self.selectedDaysWeek = [EKRecurrenceDayOfWeek(EKWeekday(rawValue: weekDay)!)]
        case .monthly:
            self.selectedDaysWeek = [EKRecurrenceDayOfWeek(EKWeekday.sunday)]
            self.setPositions = [NSNumber(value: 1)]
            
            let day = calendar.component(.day, from: date)
            self.selectedDaysMonth = [NSNumber(value: day)]
            
        case .yearly:
            self.selectedDaysWeek = [EKRecurrenceDayOfWeek(EKWeekday.sunday)]
            self.setPositions = [NSNumber(value: 1)]
            
            let month = calendar.component(.month, from: date)
            self.selectedMonthsYear = [NSNumber(value: month)]
        default:
            self.selectedDaysWeek = nil
            self.selectedDaysMonth = nil
            self.selectedDaysYear = nil
            self.selectedWeeksYear = nil
            self.selectedMonthsYear = nil
            self.setPositions = nil
            return
        }
    }
    
    
    func initReset(recurrenceRules: [EKRecurrenceRule]?, date: Date) {
        self.recurrenceRules = recurrenceRules
        if recurrenceRules != nil {
            for rule in recurrenceRules! {
                self.frequency = rule.frequency
                if rule.recurrenceEnd != nil { self.recurrenceEnd = rule.recurrenceEnd
                    self.interval = rule.interval }
                if rule.daysOfTheWeek != nil { self.selectedDaysWeek = rule.daysOfTheWeek }
                if rule.daysOfTheMonth != nil { self.selectedDaysMonth = rule.daysOfTheMonth }
                if rule.daysOfTheYear != nil { self.selectedDaysYear = rule.daysOfTheYear }
                if rule.weeksOfTheYear != nil { self.selectedWeeksYear = rule.weeksOfTheYear }
                if rule.monthsOfTheYear != nil { self.selectedMonthsYear = rule.monthsOfTheYear }
                if rule.setPositions != nil { self.setPositions = rule.setPositions }
            }
        } else {
            self.frequency = nil
            self.reset(frequency: nil)
        }
        self.date = date
    }
    // ここから
    // ルールの入れ替え
    func translation(ekEvent: EKEvent) {
        if let rules = recurrenceRules {
            for rule in rules {
                ekEvent.removeRecurrenceRule(rule)
            }
        }
        
        guard let freq = self.frequency else { return }
        
        let newRule = EKRecurrenceRule(
            recurrenceWith: freq, interval: self.interval,
            daysOfTheWeek: freq == .weekly || freq == .daily ? self.selectedDaysWeek :
                ( freq == .monthly ? (self.switchMonthWeek ? nil : self.selectedDaysWeek) : (self.isWeekYear ? self.selectedDaysWeek : nil)),
            daysOfTheMonth: freq == .monthly ? (switchMonthWeek ? self.selectedDaysMonth : nil) : nil,
            monthsOfTheYear: self.selectedMonthsYear,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: !self.switchMonthWeek || self.isWeekYear ? self.setPositions : nil, end: self.recurrenceEnd)
        
        self.recurrenceRules = [newRule]
        self.reset(frequency: freq)
        self.initReset(recurrenceRules: [newRule], date: date)
        ekEvent.addRecurrenceRule(newRule)
    }
}

