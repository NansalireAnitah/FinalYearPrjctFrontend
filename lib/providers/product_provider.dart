import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    try {
      _setLoading(true);
      final snapshot = await _firestore.collection('products').get();
      _products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      if (kDebugMode) {
        print('Fetched ${_products.length} products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch products error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      _setLoading(true);

      // String imageUrl = product.imageUrl;
      // if (image != null) {
      //   imageUrl = await _uploadImageToImgBB(image);
      // }

      final productToAdd = product;
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(productToAdd.toMap());

      _products.add(productToAdd);
      notifyListeners();

      if (kDebugMode) {
        print('Added product: ${productToAdd.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Add product error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _setLoading(true);

      // String imageUrl = product.imageUrl;
      // if (image != null) {
      //   imageUrl = await _uploadImageToImgBB(image);
      // }

      final updatedProduct = product;
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }

      if (kDebugMode) {
        print('Updated product: ${product.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update product error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      await _firestore.collection('products').doc(productId).delete();
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();

      if (kDebugMode) {
        print('Deleted product: $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete product error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
