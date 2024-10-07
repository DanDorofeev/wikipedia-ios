import Foundation

@objc public final class WMFDeveloperSettingsDataController: NSObject {
    
    public static let shared = WMFDeveloperSettingsDataController()
    
    private let service: WMFService?
    private let sharedCacheStore: WMFKeyValueStore?
    
    private var featureConfig: WMFFeatureConfigResponse?
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.developerSettings.rawValue
    private let cacheFeatureConfigFileName = "AppsFeatureConfig"
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
    }
    
    // MARK: - Local Settings from App Settings Menu

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    public var doNotPostImageRecommendationsEdit: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: newValue)
        }
    }
    
    @objc public var enableAltTextExperimentForEN: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsEnableAltTextExperimentForEN.rawValue, value: newValue)
        }
    }
    
    @objc public var alwaysShowAltTextEntryPoint: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.alwaysShowAltTextEntryPoint.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.alwaysShowAltTextEntryPoint.rawValue, value: newValue)
        }
    }
    
    @objc public var sendAnalyticsToWMFLabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue, value: newValue)
        }
    }
    
    // MARK: - Remote Settings from donatewiki AppsFeatureConfig json
    
    func loadFeatureConfig() -> WMFFeatureConfigResponse? {
        
        // First pull from memory
        guard featureConfig == nil else {
            return featureConfig
        }
        
        // Fall back to persisted objects if within three hours
        let featureConfig: WMFFeatureConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheFeatureConfigFileName)
        
        guard let featureConfigCachedDate = featureConfig?.cachedDate else {
            return nil
        }
        
        let threeHours = TimeInterval(60 * 60 * 3)
        guard (-featureConfigCachedDate.timeIntervalSinceNow) < threeHours else {
            return nil
        }
        
        self.featureConfig = featureConfig
        
        return featureConfig
    }
    
    public func fetchFeatureConfig(completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        guard let featureConfigURL = URL.featureConfigURL() else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let featureConfigParameters: [String: Any] = [
            "action": "raw"
        ]

        let featureConfigRequest = WMFBasicServiceRequest(url: featureConfigURL, method: .GET, parameters: featureConfigParameters, acceptType: .json)
        service.performDecodableGET(request: featureConfigRequest) { [weak self] (result: Result<WMFFeatureConfigResponse, Error>) in
            
            guard let self else {
                return
            }
            
            switch result {
            case .success(let response):
                self.featureConfig = response
                self.featureConfig?.cachedDate = Date()
                
                try? self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cacheFeatureConfigFileName, value: featureConfig)
                
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
