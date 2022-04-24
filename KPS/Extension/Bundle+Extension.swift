//
//  Bundle+Extension.swift
//  KPS
//


extension Bundle {
    static var current: Bundle {
        class __ { }
        return Bundle(for: __.self)
    }
    
    static var resourceBundle: Bundle {

        if let resourceBundleURL = Bundle.current.url(forResource: "KPS_iOS", withExtension: "bundle") {
            // Create a bundle object for the bundle found at that URL.
            guard let resourceBundle = Bundle(url: resourceBundleURL)
                else { fatalError("Cannot access SDK.bundle!") }
            
            return resourceBundle
        }
        return Bundle.current
    }
}
