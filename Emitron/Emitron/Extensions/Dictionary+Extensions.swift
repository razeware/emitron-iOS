//
//  Dictionary+Extensions.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

extension Dictionary {
  mutating func merge<K, V>(_ dicts: [K: V]?...) {
    dicts.forEach { dict in
      dict?.forEach { k, v in
        if let key = k as? Key, let value = v as? Value {
          updateValue(value, forKey: key)
        }
      }
    }
  }
  
  func merged<K, V>(_ dicts: [K: V]?...) -> Dictionary {
    return dicts.reduce(into: self) { result, dict in
      result.merge(dict)
    }
  }
}
