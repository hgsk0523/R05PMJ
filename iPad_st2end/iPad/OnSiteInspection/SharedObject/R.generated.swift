import Foundation
import RswiftResources
import UIKit

private class BundleFinder {}
let R = _R(bundle: Bundle(for: BundleFinder.self))

struct _R {
    let bundle: Foundation.Bundle
    var string: string { .init(bundle: bundle, preferredLanguages: nil, locale: nil) }
    var color: color { .init(bundle: bundle) }
    var storyboard: storyboard { .init(bundle: bundle) }
    
    func string(bundle: Foundation.Bundle) -> string {
        .init(bundle: bundle, preferredLanguages: nil, locale: nil)
    }
    func string(locale: Foundation.Locale) -> string {
        .init(bundle: bundle, preferredLanguages: nil, locale: locale)
    }
    func string(preferredLanguages: [String], locale: Locale? = nil) -> string {
        .init(bundle: bundle, preferredLanguages: preferredLanguages, locale: locale)
    }
    func color(bundle: Foundation.Bundle) -> color {
        .init(bundle: bundle)
    }
    func storyboard(bundle: Foundation.Bundle) -> storyboard {
        .init(bundle: bundle)
    }
    func validate() throws {
        try self.storyboard.validate()
    }
    
    struct project {
        let developmentRegion = "en"
    }
    
    /// This `_R.string` struct is generated, and contains static references to 1 localization tables.
    struct string {
        let bundle: Foundation.Bundle
        let preferredLanguages: [String]?
        let locale: Locale?
        var localizable: localizable { .init(source: .init(bundle: bundle, tableName: "Localizable", preferredLanguages: preferredLanguages, locale: locale)) }
        
        func localizable(preferredLanguages: [String]) -> localizable {
            .init(source: .init(bundle: bundle, tableName: "Localizable", preferredLanguages: preferredLanguages, locale: locale))
        }
        
        
        /// This `_R.string.localizable` struct is generated, and contains static references to 0 localization keys.
        struct localizable {
            let source: RswiftResources.StringResource.Source
        }
    }
    
    /// This `_R.color` struct is generated, and contains static references to 1 colors.
    struct color {
        let bundle: Foundation.Bundle
        
        /// Color `AccentColor`.
        var accentColor: RswiftResources.ColorResource { .init(name: "AccentColor", path: [], bundle: bundle) }
    }
    
    /// This `_R.storyboard` struct is generated, and contains static references to 3 storyboards.
    struct storyboard {
        let bundle: Foundation.Bundle
        var launchScreen: launchScreen { .init(bundle: bundle) }
        var inspectionViewController: inspectionViewController { .init(bundle: bundle) }
        var cameraViewController: cameraViewController { .init(bundle: bundle) }
        var previewViewController: previewViewController { .init(bundle: bundle) }
        var standbyViewController: standbyViewController { .init(bundle: bundle) }
        
        func launchScreen(bundle: Foundation.Bundle) -> launchScreen {
            .init(bundle: bundle)
        }
        func inspectionViewController(bundle: Foundation.Bundle) -> inspectionViewController {
            .init(bundle: bundle)
        }
        func cameraViewController(bundle: Foundation.Bundle) -> cameraViewController {
            .init(bundle: bundle)
        }
        func previewViewController(bundle: Foundation.Bundle) -> previewViewController {
            .init(bundle: bundle)
        }
        func standbyViewController(bundle: Foundation.Bundle) -> standbyViewController {
            .init(bundle: bundle)
        }
        func validate() throws {
            try self.launchScreen.validate()
        }
        
        /// Storyboard `LaunchScreen`.
        struct launchScreen: RswiftResources.StoryboardReference, RswiftResources.InitialControllerContainer {
            typealias InitialController = UIKit.UIViewController
            
            let bundle: Foundation.Bundle
            
            let name = "LaunchScreen"
            func validate() throws {
                
            }
        }
        
        /// Storyboard `InspectionViewController`.
        struct inspectionViewController: RswiftResources.StoryboardReference, RswiftResources.InitialControllerContainer {
            typealias InitialController = InspectionViewController
            
            let bundle: Foundation.Bundle
            
            let name = "InspectionViewController"
            func validate() throws {
            }
        }
        
        /// Storyboard `CameraViewController`.
        struct cameraViewController: RswiftResources.StoryboardReference, RswiftResources.InitialControllerContainer {
            typealias InitialController = CameraViewController
            
            let bundle: Foundation.Bundle
            
            let name = "CameraViewController"
            func validate() throws {
            }
        }
        
        /// Storyboard `PreviewViewController`.
        struct previewViewController: RswiftResources.StoryboardReference, RswiftResources.InitialControllerContainer {
            typealias InitialController = PreviewViewController
            
            let bundle: Foundation.Bundle
            
            let name = "PreviewViewController"
            func validate() throws {
            }
        }
        
        /// Storyboard `StandbyViewController`.
        struct standbyViewController: RswiftResources.StoryboardReference, RswiftResources.InitialControllerContainer {
            typealias InitialController = StandbyViewController
            
            let bundle: Foundation.Bundle
            
            let name = "StandbyViewController"
            func validate() throws {
            }
        }
    }
}

