import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  List<String> _availableTags = [];
  final List<String> _selectedTags = [];
  final Set<String> _selectedMealTypes = {};
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _totalRecipes = 0;
  bool _hasMoreRecipes = true;
  static const int _pageSize = 20;

  List<Recipe> get recipes => _filteredRecipes;
  List<String> get availableTags => _availableTags;
  List<String> get selectedTags => _selectedTags;
  Set<String> get selectedMealTypes => _selectedMealTypes;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreRecipes => _hasMoreRecipes;

  RecipeProvider() {
    _loadRecipesFromPrefs();
    fetchRecipes();
    fetchTags();
  }

  Future<void> fetchRecipes({bool loadMore = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    if (!loadMore) {
      _currentPage = 0;
      _recipes.clear();
      _filteredRecipes.clear();
    }

    notifyListeners();

    try {
      final result = await RecipeService.getRecipes(
        limit: _pageSize,
        skip: _currentPage * _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final newRecipes = result['recipes'] as List<Recipe>;
      _totalRecipes = result['total'];

      if (loadMore) {
        _recipes.addAll(newRecipes);
      } else {
        _recipes = newRecipes;
      }

      _hasMoreRecipes = _recipes.length < _totalRecipes;
      _currentPage++;

      _applyFilters();
      await _saveRecipesToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTags() async {
    try {
      _availableTags = await RecipeService.getRecipeTags();
      notifyListeners();
    } catch (e) {}
  }

  void searchRecipes(String query) {
    _searchQuery = query;
    _currentPage = 0;
    fetchRecipes();
  }

  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _applyFilters();
    notifyListeners();
  }

  void toggleMealTypeFilter(String mealType) {
    if (_selectedMealTypes.contains(mealType)) {
      _selectedMealTypes.remove(mealType);
    } else {
      _selectedMealTypes.add(mealType);
    }
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedTags.clear();
    _selectedMealTypes.clear();
    _searchQuery = '';

    _currentPage = 0;
    fetchRecipes();
  }

  void applyFilters(List<String> tags, Set<String> mealTypes) {
    _selectedTags.clear();
    _selectedTags.addAll(tags);
    _selectedMealTypes.clear();
    _selectedMealTypes.addAll(mealTypes);

    if (_selectedTags.isNotEmpty) {
      _fetchRecipesByFilters();
    } else {
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> _fetchRecipesByFilters() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _recipes.clear();
    _filteredRecipes.clear();
    notifyListeners();

    try {
      List<Recipe> allTaggedRecipes = [];
      Set<int> uniqueRecipeIds = {};

      for (String tag in _selectedTags) {
        final result = await RecipeService.getRecipesByTag(
          tag: tag,
          limit: _pageSize,
          skip: 0,
        );

        final tagRecipes = result['recipes'] as List<Recipe>;

        for (Recipe recipe in tagRecipes) {
          if (!uniqueRecipeIds.contains(recipe.id)) {
            uniqueRecipeIds.add(recipe.id);
            allTaggedRecipes.add(recipe);
          }
        }
      }

      _recipes = allTaggedRecipes;
      _totalRecipes = _recipes.length;
      _hasMoreRecipes = false;
      _currentPage++;

      _applyFilters();
      await _saveRecipesToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredRecipes = _recipes.where((recipe) {
      bool matchesMealTypes =
          _selectedMealTypes.isEmpty ||
          _selectedMealTypes.any(
            (mealType) => recipe.mealType.contains(mealType),
          );

      bool matchesSearch =
          _searchQuery.isEmpty ||
          recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredients.any(
            (ingredient) =>
                ingredient.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      bool matchesTags = true;
      if (_selectedTags.isNotEmpty) {
        matchesTags = _selectedTags.any((tag) => recipe.tags.contains(tag));
      }

      return matchesTags && matchesMealTypes && matchesSearch;
    }).toList();
  }

  void deleteRecipe(int recipeId) {
    _recipes.removeWhere((recipe) => recipe.id == recipeId);
    _applyFilters();
    _saveRecipesToPrefs();
    notifyListeners();
  }

  void updateRecipe(Recipe updatedRecipe) {
    final index = _recipes.indexWhere(
      (recipe) => recipe.id == updatedRecipe.id,
    );
    if (index != -1) {
      _recipes[index] = updatedRecipe;
      _applyFilters();
      _saveRecipesToPrefs();
      notifyListeners();
    }
  }

  void addRecipe(Recipe newRecipe) {
    _recipes.insert(0, newRecipe);
    _applyFilters();
    _saveRecipesToPrefs();
    notifyListeners();
  }

  Recipe? getRecipeById(int id) {
    try {
      return _recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveRecipesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = _recipes.map((recipe) => recipe.toJson()).toList();
    await prefs.setString('recipes', jsonEncode(recipesJson));
  }

  Future<void> _loadRecipesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getString('recipes');
    if (recipesJson != null) {
      try {
        final recipesList = jsonDecode(recipesJson) as List;
        _recipes = recipesList.map((json) => Recipe.fromJson(json)).toList();
        _applyFilters();
        notifyListeners();
      } catch (e) {}
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Set<String> get availableMealTypes {
    final mealTypes = <String>{};
    for (final recipe in _recipes) {
      mealTypes.addAll(recipe.mealType);
    }
    return mealTypes;
  }
}
