//
//  OrderedSet.swift
//  Foodlog
//
//  Created by David on 2/8/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

class OrderedSet<T: Hashable> {
    private var array: [T] = []
    private var indexes: [T: Int] = [:]
    
    var count: Int {
        return array.count
    }
    var items: [T] {
        return array
    }
    
    init() {}
    
    func append(_ object: T) {
        guard indexes[object] == nil else { return }
        array.append(object)
        indexes[object] = array.count - 1
    }
}
