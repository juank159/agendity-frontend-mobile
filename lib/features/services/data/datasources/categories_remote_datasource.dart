import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../shared/local_storage/local_storage.dart';
import '../models/category_model.dart';

class CategoriesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  CategoriesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<CategoryModel>> getCategories() async {
    try {
      final token = await localStorage.getToken();
      debugPrint(
          'Obteniendo categorías con token: ${token != null ? token.substring(0, min(token.length, 10)) + '...' : 'null'}');

      final response = await dio.get(
        '/categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint(
          'Respuesta del servidor (getCategories): ${response.statusCode}');

      if (response.statusCode == 200) {
        final categoriesList = (response.data as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        debugPrint('Categorías obtenidas: ${categoriesList.length}');
        return categoriesList;
      }

      throw Exception(
          'Failed to load categories: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en getCategories: $e');
      throw Exception('Error loading categories: $e');
    }
  }

  Future<void> createCategory(CategoryModel category) async {
    try {
      final token = await localStorage.getToken();
      debugPrint(
          'Creando categoría con token: ${token != null ? token.substring(0, min(token.length, 10)) + '...' : 'null'}');

      // Usamos toJson con isCreating = true para enviar solo name y description
      final dataToSend = category.toJson(isCreating: true);
      debugPrint('Datos a enviar: $dataToSend');

      final response = await dio.post(
        '/categories',
        data: dataToSend, // Aquí está el cambio
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint(
          'Respuesta del servidor (createCategory): ${response.statusCode}');

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        debugPrint('Categoría creada exitosamente en el servidor');
        debugPrint('Respuesta: ${response.data}');
      } else {
        throw Exception(
            'El servidor respondió con código ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error detallado en createCategory: $e');
      if (e is DioError) {
        debugPrint('DioError tipo: ${e.type}');
        debugPrint('DioError mensaje: ${e.message}');
        debugPrint(
            'DioError respuesta: ${e.response?.statusCode}, ${e.response?.data}');
      }
      throw Exception('Error creating category: $e');
    }
  }

  Future<void> updateCategoryStatus(String id, bool isActive) async {
    try {
      final token = await localStorage.getToken();
      debugPrint(
          'Actualizando estado de categoría $id a $isActive con token: ${token != null ? token.substring(0, min(token.length, 10)) + '...' : 'null'}');

      // Primero obtenemos los datos actuales para mantener los valores
      final getResponse = await dio.get(
        '/categories/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (getResponse.statusCode != 200) {
        throw Exception(
            'Error al obtener la categoría: ${getResponse.statusCode}');
      }

      final categoryData = getResponse.data;

      // Importante: incluimos isActive en los datos a enviar
      final updateData = {
        'name': categoryData['name'],
        'description': categoryData['description'],
        'isActive': isActive // Agregamos esta línea para enviar el nuevo estado
      };

      debugPrint('Datos a enviar: $updateData');

      final response = await dio.patch(
        '/categories/$id',
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint(
          'Respuesta del servidor (updateCategoryStatus): ${response.statusCode}');

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception(
            'El servidor respondió con código ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en updateCategoryStatus: $e');
      throw Exception('Error updating category status: $e');
    }
  }

  Future<void> updateCategory(
      String id, String name, String description) async {
    try {
      final token = await localStorage.getToken();
      debugPrint(
          'Actualizando categoría $id: nombre=$name, descripción=$description con token: ${token != null ? token.substring(0, min(token.length, 10)) + '...' : 'null'}');

      final response = await dio.patch(
        '/categories/$id',
        data: {
          'name': name,
          'description': description,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint(
          'Respuesta del servidor (updateCategory): ${response.statusCode}');

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception(
            'El servidor respondió con código ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en updateCategory: $e');
      throw Exception('Error updating category: $e');
    }
  }
}
