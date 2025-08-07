import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeService {
  static const String baseUrl = 'https://dummyjson.com';

  static Future<Map<String, dynamic>> getRecipes({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/recipes?limit=$limit&skip=$skip';
      if (search != null && search.isNotEmpty) {
        url = '$baseUrl/recipes/search?q=$search&limit=$limit&skip=$skip';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = (data['recipes'] as List)
            .map((recipeJson) => Recipe.fromJson(recipeJson))
            .toList();

        return {
          'recipes': recipes,
          'total': data['total'],
          'skip': data['skip'],
          'limit': data['limit'],
        };
      } else {
        throw Exception('Failed to load recipes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get recipes failed: $e');
    }
  }

  static Future<Recipe> getRecipeById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Recipe.fromJson(data);
      } else {
        throw Exception('Failed to load recipe: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get recipe failed: $e');
    }
  }

  static Future<List<String>> getRecipeTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes/tags'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data);
      } else {
        throw Exception('Failed to load tags: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get tags failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getRecipesByTag({
    required String tag,
    int limit = 10,
    int skip = 0,
  }) async {
    try {
      final url = '$baseUrl/recipes/tag/$tag?limit=$limit&skip=$skip';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = (data['recipes'] as List)
            .map((recipeJson) => Recipe.fromJson(recipeJson))
            .toList();

        return {
          'recipes': recipes,
          'total': data['total'],
          'skip': data['skip'],
          'limit': data['limit'],
        };
      } else {
        throw Exception('Failed to load recipes by tag: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get recipes by tag failed: $e');
    }
  }
}
