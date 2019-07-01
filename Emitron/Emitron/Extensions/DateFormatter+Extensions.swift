//
//  DateFormatter+Extensions.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

extension DateFormatter {
  static let apiDateFormatter: DateFormatter = {
    let dateFormatter        = DateFormatter()
    dateFormatter.dateFormat = .apiDateString
    return dateFormatter
  }()
}
