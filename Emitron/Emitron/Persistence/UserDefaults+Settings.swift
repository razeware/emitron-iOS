/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

// MARK: UserDefaults
// For saving individual search/filter preferences
// Progress for contentID
// App Settings
enum UserDefaultsKey: String {
  // Filters
  case filters
  case sort
  // Playback
  case playbackToken
  // User settings
  case playSpeed
  case closedCaptionOn
  case wifiOnlyDownloads
  case downloadQuality
}

extension UserDefaults {
  // MARK: - Filters
  // Construct filters from UserDefaults
  // Search is not included?
  // Filters = filters (domains + content + categories + difficulties) + sort
  var filters: Set<Filter> {
    guard let filterDataArray = UserDefaults.standard.object(forKey: UserDefaultsKey.filters.rawValue) as? [Data] else {
      return []
    }
    
    let decoder  = JSONDecoder()
    let decodedFilterArray = filterDataArray.compactMap { try? decoder.decode(Filter.self, from: $0) }
    return Set(decodedFilterArray)
  }
  
  func updateFilters(with newFilters: Filters) {
    let encoder  = JSONEncoder()
    
    var encodedFilterArray: [Data] = []
    for filter in newFilters.all {
      let encodedFilter = try? encoder.encode(filter)
      encodedFilterArray.append(encodedFilter!)
    }
    
    set(encodedFilterArray, forKey: UserDefaultsKey.filters.rawValue)
  }
  
  func deleteAllFilters() {
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.filters.rawValue)
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.sort.rawValue)
  }
  
  var sort: SortFilter {
    guard let sortFilterData = UserDefaults.standard.object(forKey: UserDefaultsKey.sort.rawValue) as? Data else {
      return SortFilter.newest
    }
    
    let decoder = JSONDecoder()
    let sortFilter = try? decoder.decode(SortFilter.self, from: sortFilterData)
    return sortFilter!
  }
  
  func updateSort(with sortFilter: SortFilter) {
    let encoder  = JSONEncoder()
    let encodedFilter = try? encoder.encode(sortFilter)
    set(encodedFilter, forKey: UserDefaultsKey.sort.rawValue)
  }
  
  // MARK: - Playback Token
  func setPlaybackToken(token: String) {
    set(token, forKey: UserDefaultsKey.playbackToken.rawValue)
  }
  
  var playbackToken: String? {
    return UserDefaults.standard.object(forKey: UserDefaultsKey.playbackToken.rawValue) as? String
  }
  
  // MARK: - User Settings
  var playSpeed: Float {
    if let speedString = UserDefaults.standard.object(forKey: UserDefaultsKey.playSpeed.rawValue) as? String,
      let speed = Double(speedString) {
      return Float(speed)
    } else {
      return 1.0
    }
  }
  
  var wifiOnlyDownloads: Bool {
    return UserDefaults.standard.object(forKey: UserDefaultsKey.wifiOnlyDownloads.rawValue) as? Bool ?? false
  }
  
  var downloadQuality: String? {
    return UserDefaults.standard.object(forKey: UserDefaultsKey.downloadQuality.rawValue) as? String ?? Attachment.Kind.hdVideoFile.detail
  }
  
  var closedCaptionOn: Bool {
    return UserDefaults.standard.object(forKey: UserDefaultsKey.closedCaptionOn.rawValue) as? Bool ?? false
  }
}

