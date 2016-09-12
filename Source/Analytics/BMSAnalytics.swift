/*
*     Copyright 2016 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/


import BMSCore


// Initializer and send methods
public extension Analytics {
    
    
    internal static var automaticallyRecordUsers: Bool = true
    
    
    
    /**
         The required initializer for the `Analytics` class when communicating with a Bluemix analytics service.
         
         This method must be called after the `BMSClient.initializeWithBluemixAppRoute()` method and before calling `Analytics.send()` or `Logger.send()`.
         
         - parameter appName:         The application name.  Should be consistent across platforms (e.g. Android and iOS).
         - parameter apiKey:          A unique ID used to authenticate with the Bluemix analytics service
         - parameter hasUserContext:  If `false`, user identities will be automatically recorded using
                                      the device on which the app is installed.
                                      If you want to define user identities yourself using `Analytics.userIdentity`, set this parameter to `true`.
         - parameter deviceEvents:    Device events that will be recorded automatically by the `Analytics` class
     */
    public static func initializeWithAppName(appName: String?, apiKey: String?, hasUserContext: Bool = false, deviceEvents: DeviceEvent...) {
        
        BMSAnalytics.appName = appName
        
        if apiKey != nil {
            BMSAnalytics.apiKey = apiKey
        }
        
        // Link all of the BMSAnalytics implementation to the BMSAnalyticsSpec APIs
        Logger.delegate = BMSLogger()
        Analytics.delegate = BMSAnalytics()
        
        BMSLogger.startCapturingUncaughtExceptions()
        
        // Registering device events
        for event in deviceEvents {
            switch event {
            case .LIFECYCLE:
                #if os(iOS)
                    BMSAnalytics.startRecordingApplicationLifecycle()
                #else
                    #if swift(>=3.0)
                        Analytics.logger.warn(message: "The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                    #else
                        Analytics.logger.warn("The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                    #endif
                #endif
            }
        }
        
        Analytics.automaticallyRecordUsers = !hasUserContext
        
        // If the developer does not want to specify the user identities themselves, we do it for them.
        if automaticallyRecordUsers {
            // We associate each unique device with one unique user. As such, all users will be anonymous.
            Analytics.userIdentity = BMSAnalytics.uniqueDeviceId
        }
        
        // Package analytics metadata in a header for each request
        // Outbound request metadata is identical for all requests made on the same device from the same app
        if BMSClient.sharedInstance.bluemixRegion != nil {
            Request.requestAnalyticsData = BMSAnalytics.generateOutboundRequestMetadata()
        }
        else {
            #if swift(>=3.0)
                Analytics.logger.warn(message: "Make sure that the BMSClient class has been initialized before calling the Analytics initializer.")
            #else
                Analytics.logger.warn("Make sure that the BMSClient class has been initialized before calling the Analytics initializer.")
            #endif
        }
    }
    
    
    /**
         Send the accumulated analytics logs to the Bluemix server.
         
         Analytics logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
         
         - parameter completionHandler:  Optional callback containing the results of the send request
     */
    public static func send(completionHandler userCallback: BmsCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: userCallback)
    }
    
}



// MARK: -

/**
    `BMSAnalytics` provides the internal implementation of the BMSAnalyticsSpec `Analytics` API.
*/
public class BMSAnalytics: AnalyticsDelegate {
    
    
    // MARK: Properties (API)
    
    /// The name of the iOS/WatchOS app
    public private(set) static var appName: String?
    
    /// The unique ID used to send logs to the Analytics server
    public private(set) static var apiKey: String?
    
    /// Identifies the current application user.
    /// To reset the userId, set the value to nil.
    public var userIdentity: String? {
        
        // Note: The developer sets this value via Analytics.userIdentity
        didSet {
            
            // userIdentity is being set by the SDK
            if userIdentity == BMSAnalytics.uniqueDeviceId {
                BMSAnalytics.logInternal(event: Constants.Metadata.Analytics.user)
            }
            // userIdentity is being set by the developer
            else {
                guard !Analytics.automaticallyRecordUsers else {
                    #if swift(>=3.0)
                        Analytics.logger.error(message: "Before setting the userIdentity property, you must first set the hasUserContext parameter to true in the Analytics initializer.")
                    #else
                        Analytics.logger.error("Before setting the userIdentity property, you must first set the hasUserContext parameter to true in the Analytics initializer.")
                    #endif
                    
                    userIdentity = BMSAnalytics.uniqueDeviceId
                    return
                }
                
                if BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] != nil {
                    
                    BMSAnalytics.logInternal(event: Constants.Metadata.Analytics.user)
                }
                else {
                    #if swift(>=3.0)
                        Analytics.logger.error(message: "To see active users in the analytics console, you must either opt in for DeviceEvents.LIFECYCLE in the Analytics initializer (for iOS apps) or first call Analytics.recordApplicationDidBecomeActive() before setting Analytics.userIdentity (for watchOS apps).")
                    #else
                        Analytics.logger.error("To see active users in the analytics console, you must either opt in for DeviceEvents.LIFECYCLE in the Analytics initializer (for iOS apps) or first call Analytics.recordApplicationDidBecomeActive() before setting Analytics.userIdentity (for watchOS apps).")
                    #endif
                    
                    userIdentity = nil
                }
            }
        }
    }
    

    // MARK: Properties (internal)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    // The timestamp for when the current session started
    internal static var startTime: Int64 = 0
    
    internal static var sdkVersion: String {
        #if swift(>=3.0)
            if let bundle = Bundle(identifier: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics") {
                return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            }
        #else
            if let bundle = NSBundle(identifier: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics") {
                return bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
            }
        #endif
        
        return ""
    }
    
    
    
    // MARK: - App sessions
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionStart() {
        
        // If this method is called before logSessionEnd() gets called, exit early so that the original startTime and metadata from the previous session start do not get discarded.
        
        #if swift(>=3.0)
            
            guard lifecycleEvents.isEmpty else {
                Analytics.logger.info(message: "A new session is starting before previous session ended. Data for this new session will be discarded.")
                return
            }
            
            BMSAnalytics.startTime = Int64(NSDate.timeIntervalSinceReferenceDate * 1000) // milliseconds
            
            lifecycleEvents[Constants.Metadata.Analytics.sessionId] = NSUUID().uuidString
            lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
            
            Analytics.log(metadata: lifecycleEvents)
            
            BMSAnalytics.logInternal(event: Constants.Metadata.Analytics.initialContext)
            
        #else
        
            guard lifecycleEvents.isEmpty else {
                Analytics.logger.info("A new session is starting before previous session ended. Data for this new session will be discarded.")
                return
            }
            
            BMSAnalytics.startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
            
            lifecycleEvents[Constants.Metadata.Analytics.sessionId] = NSUUID().UUIDString
            lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
            
            Analytics.log(lifecycleEvents)
            
            BMSAnalytics.logInternal(event: Constants.Metadata.Analytics.initialContext)
            
        #endif
    }
    
    
    // Log that the app session is ending, and use the timer from logSessionStart() to record the duration of this session
    // This method should be called when the app closes.
    //      In iOS, this occurs when the app enters the background.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionEnd() {
        
        // If logSessionStart() has not been called yet, the app session is ending before it starts.
        //      This may occur if the app crashes while launching. In this case, set the session duration to 0.
        var sessionDuration: Int64 = 0
        if !lifecycleEvents.isEmpty && BMSAnalytics.startTime > 0 {
            #if swift(>=3.0)
                sessionDuration = Int64(NSDate.timeIntervalSinceReferenceDate * 1000) - BMSAnalytics.startTime
            #else
                sessionDuration = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) - BMSAnalytics.startTime
            #endif
        }
        
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        
        lifecycleEvents[Constants.Metadata.Analytics.duration] = Int(sessionDuration)
        
        // Let the Analytics service know how the app was last closed
        if BMSLogger.exceptionHasBeenCalled {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.CRASH.rawValue
            Logger.isUncaughtExceptionDetected = true
        }
        else {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.USER.rawValue
            Logger.isUncaughtExceptionDetected = false
        }
        
        #if swift(>=3.0)
            Analytics.log(metadata: lifecycleEvents)
        #else
            Analytics.log(lifecycleEvents)
        #endif
        
        lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        #if swift(>=3.0)
            NotificationCenter.default.removeObserver(self)
        #else
            NSNotificationCenter.defaultCenter().removeObserver(self)
        #endif
    }
    
    
    
    // MARK: - Request analytics
    
    // Create a JSON string containing device/app data for the Analytics server to use
    // This data gets added to a Request header
    internal static func generateOutboundRequestMetadata() -> String? {
        
        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]
        
        // Device info
        var osVersion = "", model = "", deviceId = ""
        
        #if os(iOS)
            (osVersion, model, deviceId) = BMSAnalytics.getiOSDeviceInfo()
            requestMetadata["os"] = "iOS"
        #elseif os(watchOS)
            (osVersion, model, deviceId) = BMSAnalytics.getWatchOSDeviceInfo()
            requestMetadata["os"] = "watchOS"
        #endif

        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = BMSAnalytics.appName
        #if swift(>=3.0)
            requestMetadata["appStoreLabel"] = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
            requestMetadata["appStoreId"] = Bundle.main.bundleIdentifier ?? ""
            requestMetadata["appVersionCode"] = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
            requestMetadata["appVersionDisplay"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        #else
            requestMetadata["appStoreLabel"] = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? ""
            requestMetadata["appStoreId"] = NSBundle.mainBundle().bundleIdentifier ?? ""
            requestMetadata["appVersionCode"] = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? ""
            requestMetadata["appVersionDisplay"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        #endif
        requestMetadata["sdkVersion"] = sdkVersion
        
        var requestMetadataString: String?

        #if swift(>=3.0)
            do {
                let requestMetadataJson = try JSONSerialization.data(withJSONObject: requestMetadata, options: [])
                requestMetadataString = String(data: requestMetadataJson, encoding: .utf8)
            }
            catch let error {
                Analytics.logger.error(message: "Failed to append analytics metadata to request. Error: \(error)")
            }
            
        #else
            
            do {
                let requestMetadataJson = try NSJSONSerialization.dataWithJSONObject(requestMetadata, options: [])
                requestMetadataString = String(data: requestMetadataJson, encoding: NSUTF8StringEncoding)
            }
            catch let error {
                Analytics.logger.error("Failed to append analytics metadata to request. Error: \(error)")
            }
            
        #endif
        
        return requestMetadataString
    }
    
    
    // Gather response data as JSON to be recorded in an analytics log
    internal static func generateInboundResponseMetadata(request: Request, response: Response, url: String) -> [String: AnyObject] {
        
        #if swift(>=3.0)
            Analytics.logger.debug(message: "Network response inbound")
            
            let endTime = NSDate.timeIntervalSinceReferenceDate
            let roundTripTime = (endTime - request.startTime) * 1000 // Converting to milliseconds
            
            let bytesSent = request.requestBody?.count ?? 0
        #else
            Analytics.logger.debug("Network response inbound")
            
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            let roundTripTime = (endTime - request.startTime) * 1000 // Converting to milliseconds
            
            let bytesSent = request.requestBody?.length ?? 0
        #endif
        
        // Data for analytics logging
        var responseMetadata: [String: AnyObject] = [:]
        
        responseMetadata["$category"] = "network"
        responseMetadata["$path"] = url
        responseMetadata["$trackingId"] = request.trackingId
        responseMetadata["$outboundTimestamp"] = request.startTime
        responseMetadata["$inboundTimestamp"] = endTime
        responseMetadata["$roundTripTime"] = roundTripTime
        responseMetadata["$responseCode"] = response.statusCode
        responseMetadata["$bytesSent"] = bytesSent
        
        if (response.responseText != nil && !response.responseText!.isEmpty) {
            #if swift(>=3.0)
                responseMetadata["$bytesReceived"] = response.responseText?.lengthOfBytes(using: .utf8)
            #else
                responseMetadata["$bytesReceived"] = response.responseText?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            #endif
        }
        
        return responseMetadata
    }
    
    
    
    // MARK: - Helpers
    
    internal static func logInternal(event category: String) {
        
        let currentTime = Int64(NSDate().timeIntervalSince1970 * 1000.0)
        
        var metadata: [String: AnyObject] = [:]
        metadata[Constants.Metadata.Analytics.category] = category
        metadata[Constants.Metadata.Analytics.userId] = Analytics.userIdentity
        metadata[Constants.Metadata.Analytics.sessionId] = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId]
        #if swift(>=3.0)
            metadata[Constants.Metadata.Analytics.timestamp] = NSNumber(value: currentTime)
        #else
            metadata[Constants.Metadata.Analytics.timestamp] = NSNumber(longLong: currentTime)
        #endif
        
        #if swift(>=3.0)
            Analytics.log(metadata: metadata)
        #else
            Analytics.log(metadata)
        #endif
    }
    
    
    // Retrieve the unique device ID, or return "unknown" if it is unattainable.
    internal static func getDeviceId(from uniqueDeviceId: String?) -> String {
        
        if let id = uniqueDeviceId {
            return id
        }
        else {
            #if swift(>=3.0)
                Analytics.logger.warn(message: "Cannot determine the unique ID for this device, so the recorded analytics data will not include it.")
            #else
                Analytics.logger.warn("Cannot determine the unique ID for this device, so the recorded analytics data will not include it.")
            #endif
            
            return "unknown"
        }
    }
}


// How the last app session ended
private enum AppClosedBy: String {
    
    case USER
    case CRASH
}



// MARK: -

// For unit testing only
internal extension BMSAnalytics {
    
    internal static func uninitialize() {
        Analytics.delegate = nil
        BMSAnalytics.apiKey = nil
        BMSAnalytics.appName = nil
        NSSetUncaughtExceptionHandler(nil)
    }
}
