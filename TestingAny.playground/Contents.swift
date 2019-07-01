import UIKit

var str = "Hello, playground"

print(str)

let anyDict: [String: Any] = [
  "Lea": 28,
  "Marolt": "Surname"
]

let age: Int? = anyDict["Lea"] as? Int
let marolt: String? =  anyDict["Marolt"] as? String

print(age ?? 0)
print(marolt ?? "nada")

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
let date = dateFormatter.date(from: "2019-05-31T06:45:07.887Z")!
print(date)

class MyDate {
  var date: Date
  
  init(newDate: Date){
    self.date = newDate
  }
}

let d = MyDate(newDate: Date())
print(d.date)

class Progression {
  
  var id: String?
  var target: Int?
  var progress: Int?
  var finished: Bool?
  var percentComplete: Double?
  var createdAt: Date?
  var updatedAt: Date?
  
  init() {
    self.createdAt = Date()
    self.updatedAt = Date()
  }
}

let p = Progression()
print(p.createdAt)
