import os.log
import Foundation
import Combine

import SwiftRex

// MARK: - ACTIONS
public enum UserAction {
    case create
    case delete
    case update
    case read
}

public struct UserState: Codable, Equatable, Hashable {
    public let beaconid: UInt16?
    public let email: String?
    public let givenName: String?
    public let familyName: String?
    public let displayName: String?
    public let families: [String: Bool]?
    public let tracking: Bool?
    
    public static let empty: UserState = .init()
    
    public init(
        beaconid: UInt16? = nil,
        email: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil,
        displayName: String? = nil,
        families: [String: Bool]? = nil,
        tracking: Bool? = true
    )
    {
        self.beaconid = beaconid
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
        self.displayName = displayName
        self.families = families
        self.tracking = tracking
    }
}

// MARK: - ERRORS
public enum UserError: Error {
    case somethingSomething
}

// MARK: - PROTOCOL
public protocol UserStorage {
    func create(
        key: String,
        givenName: String,
        familyName: String,
        email: String
    ) -> AnyPublisher<String, UserError>
    func read(key: String) -> AnyPublisher<String, UserError>
    func update(
        key: String,
        params: [String: Any]
    ) -> AnyPublisher<String, UserError>
    func delete(key: String) -> AnyPublisher<Void, UserError>
}

// MARK: - MIDDLEWARE
public class UserMiddleware: Middleware {
    public typealias InputActionType = UserAction
    public typealias OutputActionType = UserAction
    public typealias StateType = UserState
    
    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "UserMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var getState: () -> StateType = {  StateType.empty }

    private var provider: UserStorage

    public init(provider: UserStorage) {
        self.provider = provider
    }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        os_log(
            "Receiving context...",
            log: UserMiddleware.logger,
            type: .debug
        )
        self.getState = getState
        self.output = output

    }
    
    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        switch action {
        default:
            os_log(
                "Not handling this case : %s ...",
                log: UserMiddleware.logger,
                type: .debug,
                String(describing: action)
            )
            break
        }

        afterReducer = .do { [self] in
            let newState = getState()
            os_log(
                "Calling afterReducer closure...",
                log: UserMiddleware.logger,
                type: .debug
            )
            switch action {
            default:
                os_log(
                    "Apparently not handling this case either : %s...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    String(describing: action)
                )
                break
            }
        }
    }
}
