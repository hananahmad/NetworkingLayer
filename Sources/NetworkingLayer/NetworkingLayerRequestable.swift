import Combine
import Foundation

public class NetworkingLayerRequestable: Requestable {
    public var requestTimeOut: Float = 60

    public init(requestTimeOut: Float) {
        SmilesNetworkReachability.shared.startMonitoring()
        self.requestTimeOut = requestTimeOut
    }
    
    public func request<T>(_ req: NetworkRequest) -> AnyPublisher<T, NetworkError>
    where T: Decodable, T: Encodable {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = TimeInterval(req.requestTimeOut ?? requestTimeOut)
        
        guard SmilesNetworkReachability.shared.isReachable else {
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
        return URLSession.shared
            .dataTaskPublisher(for: req.buildURLRequest(with: url))
            .tryMap { output in
                // throw an error if response is nil
                guard output.response is HTTPURLResponse else {
                    throw NetworkError.serverError(code: 0, error: "Server error")
                }
                
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(BaseMainResponse.self, from: output.data)
                    if let errorMessage = result.errorMsg, !errorMessage.isEmpty {
                        throw NetworkError.apiError(code: Int(result.errorCode ?? "") ?? 0, error: errorMessage)
                    }
                }
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                // return error if json decoding fails
                NetworkError.noResponse(String(describing: error))
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

