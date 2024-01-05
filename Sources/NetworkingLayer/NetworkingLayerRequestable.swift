import Combine
import Foundation

public class NetworkingLayerRequestable: NSObject, Requestable {
    
    public var requestTimeOut: Float = 60
    public init(requestTimeOut: Float) {
        self.requestTimeOut = requestTimeOut
    }
    
    public func request<T>(_ req: NetworkRequest) -> AnyPublisher<T, NetworkError>
    where T: Decodable, T: Encodable {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = TimeInterval(req.requestTimeOut ?? requestTimeOut)
        
        guard SmilesNetworkReachability.isAvailable else {
            // Return a fail publisher if the internet is not reachable
            return AnyPublisher(
                Fail<T, NetworkError>(error: NetworkError.networkNotReachable("Please check your connectivity")).eraseToAnyPublisher()
            )
        }
        
        guard let url = URL(string: req.url) else {
            // Return a fail publisher if the url is invalid
            return AnyPublisher(
                Fail<T, NetworkError>(error: NetworkError.badURL("Invalid Url")).eraseToAnyPublisher()
            )
        }
        // We use the dataTaskPublisher from the URLSession which gives us a publisher to play around with.
        
        let delegate: URLSessionDelegate? = nil
      
        let urlSession = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
        return urlSession
            .dataTaskPublisher(for: req.buildURLRequest(with: url))
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { output in
                // throw an error if response is nil
                guard output.response is HTTPURLResponse else {
                    throw NetworkError.serverError(code: 0, error: "Server error")
                }
                if let jsonString = output.data.prettyPrintedJSONString {
                    print("---------- Request Response ----------\n", jsonString)
                }
              
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                // return error if json decoding fails
                print("API error: \(error)")
                switch error {
                case let urlError as URLError:
                    switch urlError.code {
                    case .timedOut :
                        return NetworkError.noResponse("ServiceFail")
                    default: break
                    }
                case _ as DecodingError:
                    return NetworkError.unableToParseData("ServiceFail")
                default: break
                }
                if let networkError = error as? NetworkError {
                    return NetworkError.noResponse(networkError.localizedDescription)
                } else {
                    return NetworkError.noResponse(error.localizedDescription)
                }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

enum NetworkErrorCode: String {
    case sessionExpired = "0000252"
    case sessionExpired2 = "101"
}
