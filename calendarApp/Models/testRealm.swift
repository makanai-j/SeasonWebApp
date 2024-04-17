//
//  testRealm.swift
//  calendarApp
//
//  Created by 蒔苗純平 on 2023/10/08.
//

import Foundation
import RealmSwift

class userData: Object {
    @Persisted var name = ""
}

final class modelData: ObservableObject {
    @Published var shopdata: Results<userData> = getRealmData()
    
    func setter() -> Void {
        shopdata = getRealmData()
    }
}
func getRealmData() -> Results<userData> {
    let realm = try! Realm()
    
    return realm.objects(userData.self)
}
