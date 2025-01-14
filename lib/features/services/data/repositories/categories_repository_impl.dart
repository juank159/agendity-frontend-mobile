import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDataSource remoteDataSource;

  CategoriesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Category>> getCategories() async {
    try {
      return await remoteDataSource.getCategories();
    } catch (e) {
      rethrow;
    }
  }
}
