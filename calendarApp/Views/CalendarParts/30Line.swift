//
//  30Line.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/06.
//

import SwiftUI

struct _0Line: View {
    let weeks = ["土","月","火","水","木","金","日"]
    @Binding var startWeek = "土"
    var indexStartWeek = weeks.firstIndex(of: startWeek)
    for i in 0..<7 {
        var indexWeek = (i + indexStartWeek) % 7
        return Text(weeks[indexWeek])
    }
    var body: some View {
        VStack {
            HStack {
            }
        }
    }
}

struct _0Line_Previews: PreviewProvider {
    @State private var startWeek = "土"
    static var previews: some View {
        _0Line()
    }
}
