import 'package:get_it/get_it.dart';
import 'data/database.dart';
import 'data/services/storage_service.dart';
import 'data/services/pdf_service.dart';
import 'domain/repositories/product_repository.dart';
import 'data/repositories/product_repository_impl.dart';
import 'application/viewmodels/invoice_view_model.dart';
import 'application/viewmodels/invoice_history_view_model.dart';
import 'application/viewmodels/product_view_model.dart';
import 'application/viewmodels/settings_view_model.dart';
import 'domain/interfaces/base_calculation_strategy.dart';
import 'domain/services/pdf_generator_interface.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External Services
  final storageService = StorageService();
  await storageService.init();
  getIt.registerSingleton<StorageService>(storageService);
  
  // 2. Database
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  
  // 3. Services (Data Layer implementations of Domain interfaces)
  getIt.registerLazySingleton<IPdfGeneratorService>(() => PdfService());
  getIt.registerLazySingleton<BaseCalculationStrategy>(() => DefaultCalculationStrategy());
  
  // Repositories
  getIt.registerLazySingleton<IProductRepository>(
    () => ProductRepositoryImpl(getIt<AppDatabase>()),
  );

  // 4. ViewModels (Factory: create new instance when requested)
  getIt.registerFactory<InvoiceViewModel>(
    () => InvoiceViewModel(
      database: getIt<AppDatabase>(),
      pdfService: getIt<IPdfGeneratorService>(),
      calculationStrategy: getIt<BaseCalculationStrategy>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  getIt.registerFactory<InvoiceHistoryViewModel>(
    () => InvoiceHistoryViewModel(
      database: getIt<AppDatabase>(),
      pdfService: getIt<IPdfGeneratorService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  getIt.registerFactory<ProductViewModel>(
    () => ProductViewModel(getIt<IProductRepository>()),
  );
  
  getIt.registerFactory<SettingsViewModel>(
    () => SettingsViewModel(getIt<StorageService>()),
  );
}
