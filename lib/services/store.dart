import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class ProductStore {
  static const _key = 'bikam.products.v1';
  late SharedPreferences _prefs;
  final List<ProductItem> products = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      products.addAll(list.map((e) => ProductItem.fromJson(Map<String,dynamic>.from(e))));
    } catch (_) {
      products.clear();
    }
  }

  Future<void> add(ProductItem product) async {
    products.insert(0, product);
    await _save();
  }

  Future<void> remove(String id) async {
    products.removeWhere((p) => p.id == id);
    await _save();
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(products.map((p) => p.toJson()).toList()));

  List<ProductItem> inMarket(String market) =>
      products.where((p) => p.market == market).toList();

  Map<String, int> get counts {
    final result = <String,int>{};
    for (final p in products) {
      result[p.market] = (result[p.market] ?? 0) + 1;
    }
    return result;
  }
}
