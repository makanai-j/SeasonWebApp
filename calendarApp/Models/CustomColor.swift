//
//  CustomColor.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/11/12.
//

import Foundation
import SwiftUI

class CustomColor: ObservableObject {
    // ホーム 後ろ
    @Published var homeBack: Color
    @Published var foreGround: Color
    @Published var backGround: Color
    @Published var cancel: Color = .red
    @Published var complete: Color = .blue
    @Published var invalid: Color
    
    init(foreGround: Color, backGround: Color) {
        self.foreGround = foreGround
        self.backGround = backGround
        self.invalid = foreGround.opacity(0.5)
        self.homeBack = .gray
        
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(foreGround.opacity(0.5))], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(foreGround)], for: .selected)
    }
}
