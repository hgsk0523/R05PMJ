import Swinject

/// ViewModelの依存関係を解決するAssembly
final class ViewModelAssembly: Assembly {
    
    func assemble(container: Swinject.Container) {
        /// 点検画面
        container.register(InspectionViewModelProtocol.self) { resolver in
            return InspectionViewModel()
        }
        
        /// 撮影画面
        container.register(CameraViewModelProtocol.self) { resolver in
            return CameraViewModel()
        }
        
        /// プレビュー画面
        container.register(PreviewViewModelProtocol.self) { resolver in
            return PreviewViewModel()
        }
    }
}

