import UIKit
import Combine

//: # Building truly global apps
//: ## General
//: Use system components (fight for them!)
UINavigationController()
UITabBar()
UISearchBar()
UIProgressView()
UISlider()
UISegmentedControl()
UIPageControl()
// etc.
//: Use system formatters (fight for these as well!)
let dateFormatter = DateFormatter() // July 15, 2019
dateFormatter.dateStyle
dateFormatter.timeStyle

// If that is not enough:
dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd") // December 31


let numberFormatter = NumberFormatter() // 1,234.56
numberFormatter.numberStyle = .currency // $12.00


ISO8601DateFormatter() // 2019-07-15
DateComponentsFormatter() // 10 minutes
DateIntervalFormatter() // 6/3/19 - 6/7/19
RelativeDateTimeFormatter() // 3 weeks ago


MeasurementFormatter() // -9.80665 m/s², 756 KB, 80 kcal, 175 lb, 5 ft, 500 miles
// Acceleration, Angle, Area, ConcentrationMass, Dispersion, Duration, ElectricCharge, ElectricCurrent, ElectricPotentialDifference, ElectricResistance, Energy, Frequency, FuelEfficiency, Length, Illuminance, Mass, Power, Pressure, Speed, Storage, Temperature, Volume


let temperatureMeasurement = Measurement(value: 72, unit: UnitTemperature.fahrenheit)
temperatureMeasurement.converted(to: .celsius)


let lengthMeasurement = Measurement(value: 52000, unit: UnitLength.meters)
let measurementFormatter = MeasurementFormatter()
measurementFormatter.unitOptions = .providedUnit
measurementFormatter.string(from: lengthMeasurement)


extension UnitLength {
    /// https://en.wikipedia.org/wiki/List_of_humorous_units_of_measurement#Beard-second
    static let beardSecond = UnitLength(symbol: "BS", converter: UnitConverterLinear(coefficient: 1 / 100000000))
}

Measurement(value: 5, unit: UnitLength.millimeters).converted(to: .beardSecond)


public class UnitBeauty: Dimension {
    /// https://en.wikipedia.org/wiki/Helen_(unit)
    static let helen = UnitBeauty(symbol: "👸", converter: UnitConverterLinear(coefficient: 1))
}

let helenOfTroy = Measurement(value: 1, unit: UnitBeauty.helen)


ListFormatter() // macOS, iOS, iPadOS, watchOS, and tvOS


PersonNameComponentsFormatter() // J. Appleseed
//: Use .strings/.stringsdict with placeholders and punctuation
// DON'T
let count = 500
let localizedString = NSLocalizedString("number_employees_selected", comment: "The number of employees currently selected.") // "team members selected"
"\(count) \(localizedString)"

// DO
let trulyLocalizedString = NSLocalizedString("correct_number_employees_selected", comment: "The number of employees currently selected.") // "تم اختيار %d من أعضاء الفريق"
String(format: trulyLocalizedString, count)
#imageLiteral(resourceName: "Bildschirmfoto 2020-02-18 um 19.37.13.png")
//: Calendar can save you localization effort
var calendar = Calendar.current
calendar.locale = Locale(identifier: "sv")
calendar.standaloneWeekdaySymbols[1]
//: Localize quotation delimiters
let locale = Locale(identifier: "ja")
locale.quotationBeginDelimiter
locale.quotationEndDelimiter
//: Respect Low Data Mode
extension URLSession {
    func adaptiveDataTaskPublisher(for url: URL, lowDataModeURL: URL) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.allowsConstrainedNetworkAccess = false
        return dataTaskPublisher(for: request)
            .tryCatch { (error) -> DataTaskPublisher in
                guard error.networkUnavailableReason == .constrained else {
                    throw error
                }
                return self.dataTaskPublisher(for: lowDataModeURL)
            }
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.unknown)
                }
                return data
            }
            .eraseToAnyPublisher()
    }
}
//: ## Right-to-left specific. There are more than 300 million Arabic- and Hebrew-speakers.
//: Use UIStackView as well as leading and trailing auto layout constraints
let stackView = UIStackView(arrangedSubviews: [])
stackView.alignment
stackView.axis
stackView.distribution
stackView.spacing

let superview = UIView()
let button = UIButton(type: .system)

// DON'T
button.leftAnchor.constraint(equalToSystemSpacingAfter: superview.leftAnchor, multiplier: 1)
button.rightAnchor.constraint(equalToSystemSpacingAfter: superview.rightAnchor, multiplier: 1)

// DO
button.leadingAnchor.constraint(equalToSystemSpacingAfter: superview.leadingAnchor, multiplier: 1)
button.trailingAnchor.constraint(equalToSystemSpacingAfter: superview.trailingAnchor, multiplier: 1)
//: Use natural (or center) alignment
let label = UILabel()
label.textAlignment = .natural // Default
label.textAlignment = .center
//: Possibly mirror assets
// Configure in asset catalog or in code:
let backArrow = UIImage(named: "backArrow")?.imageFlippedForRightToLeftLayoutDirection() // Flips if right-to-left layout

// BUT
let logo = UIImage(named: "logo")
//: Mirror animations and gestures
if UIView.userInterfaceLayoutDirection(for: superview.semanticContentAttribute) == .rightToLeft {
    // The view is shown in right-to-left mode right now
} else {
    // Use the previous technique
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
        // The app is in right-to-left mode
    }
}
//: Do mirror:
/*:
 - Workflows
 - Rating components
*/
//: Do NOT mirror:
/*:
 - Graphs
 - Clocks
 - Playback controls and timeline indicators
 - Music notes
 - Phone numbers
*/
//: Test using "Right-to-Left Pseudolanguage" in the scheme Run settings
//: ## Japanese graphical user interfaces are layed out left-to-right.
//: Top to bottom writing (reading the columns from right to left) is only used in literary works and printed newspapers.

//: Caution: colors can have different meanings!
#imageLiteral(resourceName: "IMG_0083.PNG")
