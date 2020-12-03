import os.log
import Foundation
import Combine

import SwiftRex

// MARK: - ACTIONS
//sourcery: Prism
public enum UserAction {
    case create
    case delete
    case update([UserInfo.CodingKeys: Any])
    case register(String)
    case stateChanged(UserState)
}

public struct UserState: Codable, Equatable, Hashable {
    public let key: String
    public let value: UserInfo
    
    public init(key: String, value: UserInfo) {
        self.key = key
        self.value = value
    }
}

public struct UserInfo: Equatable, Hashable {
    public let beaconid: UInt16
    public let email: String
    public let givenName: String
    public let familyName: String
    public var displayName: String { givenName + " " + familyName }
    public let families: [String: Bool]?
    public let tracking: Bool?

    public init(
        beaconid: UInt16 = UInt16.random(in: UInt16.min...UInt16.max),
        email: String,
        givenName: String,
        familyName: String,
        families: [String: Bool]? = nil,
        tracking: Bool? = true
    )
    {
        self.beaconid = beaconid
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
        self.families = families
        self.tracking = tracking
    }
}

extension UserInfo: Codable { }

extension UserInfo {
    public enum CodingKeys: String, CodingKey {
        case beaconid
        case email
        case givenName
        case familyName
        case families
        case tracking
    }
}

// MARK: - ERRORS
public enum UserError: Error {
    case userDecodingError
    case userEncodingError
    case userDataNotFoundError
    case userCreationError
    case userDeletionError
}

// MARK: - PROTOCOL
public protocol UserStorage {
    func register(key: String)
    func create(key: String, user: UserInfo) -> AnyPublisher<Void, UserError>
    func update(key: String, params: [String: Any]) -> AnyPublisher<Void, UserError>
    func delete(key: String) -> AnyPublisher<Void, UserError>
    func userChangeListener() -> AnyPublisher<UserState, UserError>
}

// MARK: - MIDDLEWARE

/// The UserMiddleware is specifically designed to suit the needs of one application.
///
/// It offers the following :
///   * it registers a key with the data provider (see below),
///   * it provides several facilities to create, update and delete the user entry
///   * it listens to all state changes for the particular key that was registered
/// Any new state change collected from the listener is dispatched as an action
/// so the global state can be modified accordingly.
///
public class UserMiddleware: Middleware {
    public typealias InputActionType = UserAction
    public typealias OutputActionType = UserAction
    public typealias StateType = UserState?
    
    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "UserMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var getState: GetState<StateType>? = nil

    private var provider: UserStorage
    
    private var stateChangeCancellable: AnyCancellable?
    private var userOperationCancellable: AnyCancellable?

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
        self.stateChangeCancellable = provider
            .userChangeListener()
            .sink { (completion: Subscribers.Completion<UserError>) in
                var result: String = "success"
                if case let Subscribers.Completion.failure(err) = completion {
                    result = "failure : " + err.localizedDescription
                }
                os_log(
                    "State change completed with %s.",
                    log: UserMiddleware.logger,
                    type: .debug,
                    result
                )
            } receiveValue: { user in
                os_log(
                    "State change receiving value for user : %s...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    String(describing: user.key)
                )
                self.output?.dispatch(.stateChanged(user))
            }
    }
    
    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        switch action {
            case let .register(id):
                os_log(
                    "Registering user with id : %s ...",
                    log: UserMiddleware.logger,
                    type: .debug,
                    String(describing: id)
                )
                provider.register(key: id)
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
            if let state = getState,
               let newState = state() {
                os_log(
                    "Calling afterReducer closure...",
                    log: UserMiddleware.logger,
                    type: .debug
                )
                switch action {
                    case .create:
                        userOperationCancellable = provider
                            .create(
                                key: newState.key,
                                user: UserInfo(
                                    email: newState.value.email,
                                    givenName: newState.value.givenName,
                                    familyName: newState.value.familyName
                                )
                            )
                            .sink { (completion: Subscribers.Completion<UserError>) in
                                var result: String = "success"
                                if case let Subscribers.Completion.failure(err) = completion {
                                    result = "failure : " + err.localizedDescription
                                }
                                os_log(
                                    "User creation completed with %s.",
                                    log: UserMiddleware.logger,
                                    type: .debug,
                                    result
                                )
                            } receiveValue: { _ in
                                os_log(
                                    "User creation received ack.",
                                    log: UserMiddleware.logger,
                                    type: .debug
                                )
                            }
                    case .delete:
                        userOperationCancellable = provider
                            .delete(key: newState.key)
                            .sink { (completion: Subscribers.Completion<UserError>) in
                                var result: String = "success"
                                if case let Subscribers.Completion.failure(err) = completion {
                                    result = "failure : " + err.localizedDescription
                                }
                                os_log(
                                    "User deletion completed with %s.",
                                    log: UserMiddleware.logger,
                                    type: .debug,
                                    result
                                )
                            } receiveValue: { _ in
                                os_log(
                                    "User deletion received ack.",
                                    log: UserMiddleware.logger,
                                    type: .debug
                                )
                            }
                    case let .update(params):
                        var paramDict: [String: Any] = [:]
                        params.forEach { key, value in
                            paramDict.updateValue(value, forKey: key.stringValue)
                        }
                        userOperationCancellable = provider
                            .update(key: newState.key, params: paramDict)
                            .sink { (completion: Subscribers.Completion<UserError>) in
                                var result: String = "success"
                                if case let Subscribers.Completion.failure(err) = completion {
                                    result = "failure : " + err.localizedDescription
                                }
                                os_log(
                                    "User update completed with %s.",
                                    log: UserMiddleware.logger,
                                    type: .debug,
                                    result
                                )
                            } receiveValue: { _ in
                                os_log(
                                    "User update received ack.",
                                    log: UserMiddleware.logger,
                                    type: .debug
                                )
                            }
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
}
