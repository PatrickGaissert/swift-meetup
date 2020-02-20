import UIKit
import MapKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

func handleError(_ error: Error) {}
func handleData(_ data: Data) {}

//: # Swift.Result

let url = URL(string: "https://cat-fact.herokuapp.com/facts/random")!

struct OldWay {
    static func fetchCatFact() {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                handleError(error!)
                return
            }

            guard let data = data else {
                return // Impossible?
            }

            handleData(data)
        }.resume()
    }
}

/*:
````
enum Result<Success, Failure> where Failure : Error {
    case success(Success)
    case failure(Failure)
}
````
*/

extension URLSession {
    open func dataTask(with url: URL, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }

            completion(.success(data!))
        }
    }
}

//: Usage

struct NewWay {
    static func fetchCatFactSwitch() {
        URLSession.shared.dataTask(with: url) { (result) in
            switch result {
            case .success(let data):
                handleData(data)
            case .failure(let error):
                handleError(error)
            }
        }.resume()
    }



    static func fetchCatFactGet() {
        URLSession.shared.dataTask(with: url) { (result) in
            do {
                let data = try result.get()
                handleData(data)
            } catch {
                handleError(error)
            }
        }.resume()
    }



    static func fetchCatFactTry() {
        URLSession.shared.dataTask(with: url) { (result) in
            guard let data = try? result.get() else {
                return
            }

            handleData(data)
        }.resume()
    }



    static func fetchCatFactCase() {
        URLSession.shared.dataTask(with: url) { (result) in
            guard case .success(let data) = result else {
                return
            }

            handleData(data)
        }.resume()
    }
}

//: Example using `init(catching:)`, `map(:)` & `flatMap(:)`

struct CatFact: Codable {
    let text: String
}

extension NewWay {
    static func fetchCatFact(completion: @escaping (Result<String, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { (result) in
            let catFactResult = result.flatMap({ (data) -> Result<String, Error> in
                Result(catching: { try JSONDecoder().decode(CatFact.self, from: data) })
                    .map({ $0.text })
            })
            completion(catFactResult)
        }.resume()
    }
}

NewWay.fetchCatFact { (result) in
    switch result {
    case .success(let catFact):
        print(catFact)
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//: Another example using `init(catching:)`, `map(:)` & `mapError(:)`

struct ExchangeRates: Codable {
    let rates: [String : Double]
}



enum ExchangeRatesError: Error {
    case decoding(Error)
    case invalidResponse(Int)
    case request(Error)
    case unsupportedDate
}



struct DataAccess {
    private let url = URL(string: "https://api.exchangeratesapi.io/2010-01-12")!

    func fetchExchangeRates(completion: @escaping (Result<[String : Double], ExchangeRatesError>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completion(.failure(.request(error!)))
                return
            }

            let statusCode = (response as! HTTPURLResponse).statusCode

            switch statusCode {
            case ..<200:
                completion(.failure(.invalidResponse(statusCode)))

            case 200..<300:
                let rates = Result(catching: { try JSONDecoder().decode(ExchangeRates.self, from: data!) })
                                .map({ $0.rates })
                                .mapError({ ExchangeRatesError.decoding($0) })
                completion(rates)

            case 300..<400:
                completion(.failure(.invalidResponse(statusCode)))

            case 400:
                completion(.failure(.unsupportedDate))

            case 401...:
                completion(.failure(.invalidResponse(statusCode)))

            default:
                fatalError()
            }
        }.resume()
    }
}



struct Controller {
    private let dataAccess = DataAccess()

    func printExchangeRates() {
        dataAccess.fetchExchangeRates { (result) in
            switch result {
            case .success(let rates):
                self.printRates(rates)
            case .failure(let error):
                self.printError(error)
            }
        }
    }



    // MARK: - Private interface



    private func printRates(_ rates: [String : Double]) {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency

        rates.forEach({ (key, value) in
            formatter.currencyCode = key
            print(formatter.string(from: NSNumber(value: value))!)
        })
    }



    private func printError(_ error: ExchangeRatesError) {
        let text: String

        switch error {
        case .decoding(let error), .request(let error):
            text = error.localizedDescription
        case .invalidResponse(let statusCode):
            text = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        case .unsupportedDate:
            text = NSLocalizedString("exchange_rates_unsupported_date", comment: "The selected date is not supported.")
        }

        print(text)
    }
}

let controller = Controller()
//controller.printExchangeRates()

//: Cocoa Touch integration by Apple (or you)

extension CLGeocoder {
    open func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (Result<[CLPlacemark], Error>) -> Void) {
        reverseGeocodeLocation(location) { (placemarks, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(placemarks!))
        }
    }
}



extension MKDirections {
    open func calculate(completion: @escaping (Result<MKDirections.Response, Error>) -> Void) {
        calculate { (response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(response!))
        }
    }
}



extension JSONDecoder {
    open func decodeResult<T>(_ type: T.Type, from data: Data) -> Result<T, DecodingError> where T : Decodable {
        return Result(catching: { try decode(type, from: data) }).mapError({ $0 as! DecodingError })
    }
}

let data = #"{ "text": "Cats own you." }"#.data(using: .utf8)!

struct CoolStuff {
    static func one() {
        let result = JSONDecoder().decodeResult(CatFact.self, from: data)
        print(result)
    }
}

//CoolStuff.one()



extension Result where Success == Data {
    func decoded<T: Decodable>() throws -> T {
        let decoder = JSONDecoder()
        let data = try get()
        return try decoder.decode(T.self, from: data)
    }
}

extension CoolStuff {
    static func two() {
        do {
            let result: Result<Data, Error> = .success(data)
            let catFact: CatFact = try result.decoded()
            print(catFact.text)
        } catch {
            print(error)
        }
    }
}

//CoolStuff.two()
