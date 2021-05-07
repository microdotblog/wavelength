//
//  UURemoteData.swift
//  Useful Utilities - An extension to Useful Utilities 
//  UUDataCache that fetches data from a remote source
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//
//  UURemoteData provides a centralized place where application components can 
//  request data that may come from a remote source.  It utilizes existing 
//  UUDataCache functionality to locally store files for later fetching.  It 
//  will intelligently handle multiple requests for the same image so that 
//  extraneous network requests are not needed.
//
//  NOTE: This class depends on the following toolbox classes:
//
//  UUHttpSession
//  UUDataCache
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

public protocol UURemoteDataProtocol
{
    func data(for key: String) -> Data?
    func isDownloadActive(for key: String) -> Bool
    
    func metaData(for key: String) -> [String:Any]
    func set(metaData: [String:Any], for key: String)
}

public typealias UUDataLoadedCompletionBlock = (Data?, Error?) -> Void

public class UURemoteData : NSObject, UURemoteDataProtocol
{
    public struct Notifications
    {
        public static let DataDownloaded = Notification.Name("UUDataDownloadedNotification")
        public static let DataDownloadFailed = Notification.Name("UUDataDownloadFailedNotification")
    }

    public struct MetaData
    {
        public static let MimeType = "MimeType"
        public static let DownloadTimestamp = "DownloadTimestamp"
    }
    
    public struct NotificationKeys
    {
        public static let RemotePath = "UUDataRemotePathKey"
        public static let Error = "UURemoteDataErrorKey"
    }
    
	private var activeDownloads : UUThreadSafeDictionary<String, UUHttpRequest> = UUThreadSafeDictionary()
    private var pendingDownloads : UUThreadSafeArray<String> = UUThreadSafeArray()
	private var httpRequestLookups : UUThreadSafeDictionary<String, [UUDataLoadedCompletionBlock]> = UUThreadSafeDictionary()
    
    // Default to 4 active requests at a time...
    public var maxActiveRequests: Int = 4
    
    static public let shared : UURemoteData = UURemoteData()
    
    ////////////////////////////////////////////////////////////////////////////
    // UURemoteDataProtocol Implementation
    ////////////////////////////////////////////////////////////////////////////
    public func data(for key: String) -> Data?
    {
        return data(for: key, remoteLoadCompletion: nil)
    }
    
    public func data(for key: String, remoteLoadCompletion: UUDataLoadedCompletionBlock? = nil) -> Data?
    {
        let url = URL(string: key)
        if (url == nil)
        {
            return nil
        }
        
		if UUDataCache.shared.dataExists(for: key) {
			let data = UUDataCache.shared.data(for: key)
			if (data != nil)
			{
				return data
			}
        }
        
        if (self.isDownloadActive(for: key))
        {
            // An active UUHttpSession means a request is currently fetching the resource, so
            // no need to re-fetch
            UUDebugLog("Download pending for \(key)")
            self.appendRemoteHandler(for: key, handler: remoteLoadCompletion)

            return nil
        }
        
        if (self.activeDownloadCount() > self.maxActiveRequests)
        {
            self.queuePendingRequest(for: key, remoteLoadCompletion: remoteLoadCompletion)
            return nil
        }
        
        let request = UUHttpRequest(url: key)
        request.processMimeTypes  = false
        
        let client = UUHttpSession.executeRequest(request)
        { (response: UUHttpResponse) in
            self.handleDownloadResponse(response, key)
            self.checkForPendingRequests()
        }
    
        self.activeDownloads[key] = client
        self.appendRemoteHandler(for: key, handler: remoteLoadCompletion)
        
        return nil
    }
    
    private func checkForPendingRequests()
    {
        while (activeDownloadCount() < self.maxActiveRequests)
        {
            guard let next = self.dequeuePending() else
            {
                break
            }
            
            _ = self.data(for: next)
        }
    }
    
    private func pendingDownloadCount() -> Int
    {
        return self.pendingDownloads.count
    }
    
    private func activeDownloadCount() -> Int
    {
        return self.activeDownloads.count
    }
    
    private func dequeuePending() -> String?
    {
        return self.pendingDownloads.popLast()
    }
    
    private func queuePendingRequest(for key: String, remoteLoadCompletion: UUDataLoadedCompletionBlock?)
    {
        if (self.pendingDownloads.contains(key)) {
            self.pendingDownloads.remove(key)
        }
        self.pendingDownloads.prepend(key)

        appendRemoteHandler(for: key, handler: remoteLoadCompletion)
    }
    
    private func appendRemoteHandler(for key: String, handler: UUDataLoadedCompletionBlock?)
    {
        if let remoteHandler = handler
        {
            var handlers = self.httpRequestLookups[key]
            if (handlers == nil)
            {
                handlers = []
            }
            
            if (handlers != nil)
            {
                handlers!.append(remoteHandler)
                self.httpRequestLookups[key] = handlers!
            }
        }
    }
    
    public func isDownloadActive(for key: String) -> Bool
    {
        return (activeDownloads[key] != nil)
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        return UUDataCache.shared.metaData(for: key)
    }
    
    public func set(metaData: [String:Any], for key: String)
    {
        UUDataCache.shared.set(metaData: metaData, for: key)
    }
    
    private func getHandlers(for key: String) -> [UUDataLoadedCompletionBlock]?
    {
        return self.httpRequestLookups[key]
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private Implementation
    ////////////////////////////////////////////////////////////////////////////
    private func handleDownloadResponse(_ response: UUHttpResponse, _ key: String)
    {
        var md : [String:Any] = [:]
        md[UURemoteData.NotificationKeys.RemotePath] = key
        
        if (response.httpError == nil && response.rawResponse != nil)
        {
            let responseData = response.rawResponse!
            
            UUDataCache.shared.set(data: responseData, for: key)
            updateMetaDataFromResponse(response, for: key)
            notifyDataDownloaded(metaData: md)
            
            if let handlers = self.getHandlers(for: key)
            {
                notifyRemoteDownloadHandlers(key: key, data: responseData, error: nil, handlers: handlers)
            }
        }
        else
        {
            UUDebugLog("Remote download failed!\n\nPath: %@\nStatusCode: %d\nError: %@\n", key, String(describing: response.httpResponse?.statusCode), String(describing: response.httpError))
            
            md[NotificationKeys.Error] = response.httpError
            
            DispatchQueue.main.async
            {
                NotificationCenter.default.post(name: Notifications.DataDownloadFailed, object: nil, userInfo: md)
            }
            
            if let handlers = self.getHandlers(for: key)
            {
                notifyRemoteDownloadHandlers(key: key, data: nil, error: response.httpError, handlers: handlers)
            }
        }
        
        _ = self.activeDownloads.removeValue(forKey: key)
        _ = self.httpRequestLookups.removeValue(forKey: key)
    }
    
    private func updateMetaDataFromResponse(_ response: UUHttpResponse, for key: String)
    {
        var md = UUDataCache.shared.metaData(for: key)
        md[MetaData.MimeType] = response.httpResponse!.mimeType!
        md[MetaData.DownloadTimestamp] = Date()
        
        UUDataCache.shared.set(metaData: md, for: key)
    }
    
    public func save(data: Data, key: String)
    {
        UUDataCache.shared.set(data: data, for: key)
        
        var md = UUDataCache.shared.metaData(for: key)
        md[MetaData.MimeType] = "raw"
        md[MetaData.DownloadTimestamp] = Date()
        md[UURemoteData.NotificationKeys.RemotePath] = key
        
        UUDataCache.shared.set(metaData: md, for: key)
        
        notifyDataDownloaded(metaData: md)
    }
    
    private func notifyDataDownloaded(metaData: [String:Any])
    {
        DispatchQueue.main.async
        {
            NotificationCenter.default.post(name: Notifications.DataDownloaded, object: nil, userInfo: metaData)
        }
    }
    
    private func notifyRemoteDownloadHandlers(key: String, data: Data?, error: Error?, handlers: [UUDataLoadedCompletionBlock])
    {
        for handler in handlers
        {
            DispatchQueue.main.async
            {
                handler(data, error)
            }
        }
    }
    
}

extension Notification
{
    public var uuRemoteDataPath : String?
    {
        return userInfo?[UURemoteData.NotificationKeys.RemotePath] as? String
    }
    
    public var uuRemoteDataError : Error?
    {
        return userInfo?[UURemoteData.NotificationKeys.Error] as? Error
    }
}
