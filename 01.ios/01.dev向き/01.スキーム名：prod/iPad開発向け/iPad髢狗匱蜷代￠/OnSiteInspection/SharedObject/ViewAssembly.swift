import Swinject
import SwinjectStoryboard

/// ViewControllerの依存関係を解決するAssembly
final class ViewAssembly: Assembly {
    
    func assemble(container: Container) {
        /// 点検画面
        container.storyboardInitCompleted(InspectionViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(InspectionViewModelProtocol.self)
        }
        
        /// 撮影
        container.storyboardInitCompleted(CameraViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(CameraViewModelProtocol.self)
        }
        
        /// プレビュー
        container.storyboardInitCompleted(PreviewViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(PreviewViewModelProtocol.self)
        }
    }
}

