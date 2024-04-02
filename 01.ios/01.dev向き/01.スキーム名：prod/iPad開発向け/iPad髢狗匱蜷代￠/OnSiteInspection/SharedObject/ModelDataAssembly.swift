import Swinject

/// Model／DataSourceの依存関係を解決するAssembly
final class ModelDataAssembly: Assembly {
    
    func assemble(container: Swinject.Container) {
        
        /// ModelConfiguration
        container.register(ModelConfiguration.self) { _ in
            ModelConfiguration(modelFileDirectory: FileDirectory.modelFileDirectory)
        }.inObjectScope(.container)
        
        // MARK: - Keychain
        
        /// KeychainDataSource
        container.register(KeychainDataSourceProtocol.self) { _ in
            return KeychainDataSource()
        }.inObjectScope(.container)
        
        // MARK: - Realm
        
        /// BaseRealmDataSource
        container.register(BaseRealmDataSourceProtocol.self) { resolver in
            guard let keychainDataSOurce = resolver.resolve(KeychainDataSourceProtocol.self) else { fatalError() }
            guard let modelConfiguration = resolver.resolve(ModelConfiguration.self) else { fatalError() }
            return BaseRealmDataSource(fileURL: modelConfiguration.modelFileDirectory, keychainDataSource: keychainDataSOurce)
        }.inObjectScope(.container)
        
        // MARK: - API
        
        /// ApiDataSource
        container.register(ApiDataSourceProtocol.self) { _ in
            return ApiDataSource()
        }.inObjectScope(.container)
    }
}

