import SwiftUI

enum RuleTypeEnum : String {
  case long = "long"
  case bool = "boolean"
  case listOfLong = "list_of_long"
  case string = "string"
    
    var value: String {
        rawValue
    }
}
