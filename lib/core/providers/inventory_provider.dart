// ignore_for_file: constant_identifier_names, prefer_final_fields

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stiuffcoletorinventario/core/models/inventory_item.dart';
import 'package:stiuffcoletorinventario/core/models/package_model.dart';
import 'package:stiuffcoletorinventario/core/services/local_storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InventoryProvider with ChangeNotifier {
  static const int DEFAULT_PACKAGE_ID = 0;
  static const String DEFAULT_BARCODE_ID = "-1";

  List<InventoryItem> _localItems = [];
  List<PackageModel> _localPackages = [];

  Map<int, List<InventoryItem>> _packagesItemsMap = {};
  List<PackageModel> _sentPackages = [];

  List<InventoryItem> get items => _localItems;
  List<PackageModel> get packages => _localPackages;

  Map<int, List<InventoryItem>> get packagesItemsMap => _packagesItemsMap;
  List<PackageModel> get sentPackages => _sentPackages;

  final _random = Random();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updatePackagesItemsMap() async {
    try {
      await getPackages();

      Map<int, List<InventoryItem>> updatedMap = {};

      for (var package in _sentPackages) {
        final items = await getItemsForPackage(package.id);
        updatedMap[package.id] = items;
      }

      _packagesItemsMap = updatedMap;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar _sentItems: $e');
    }
  }

  Future<void> getPackages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Usuário não autenticado');
        return;
      }

      final packagesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('packages')
          .get();

      final sentPackages = packagesSnapshot.docs
          .map((doc) => PackageModel.fromMap(doc.data()))
          .toList();

      _sentPackages = sentPackages;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao recuperar pacotes: $e');
    }
  }

  Future<List<InventoryItem>> getItemsForPackage(int packageId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Usuário não autenticado');
        return [];
      }

      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('packages')
          .doc(packageId.toString())
          .collection('items')
          .get();

      List<InventoryItem> items = [];

      List<String> imageUrls = [];

      for (var doc in itemsSnapshot.docs) {
        final item = InventoryItem.fromMap(doc.data());

        imageUrls = [];
        if (item.images != null && item.images!.isNotEmpty) {
          for (var imagePath in item.images!) {
            try {
              imageUrls.add(imagePath);
            } catch (e) {
              debugPrint(
                  'Erro ao obter URL da imagem para o item ${item.barcode}: $e');
            }
          }
          item.images = imageUrls;
        }

        items.add(item);
      }

      return items;
    } catch (e) {
      debugPrint('Erro ao recuperar itens para o pacote #$packageId: $e');
      return [];
    }
  }

  Future<String> uploadImageToStorage(String path, String storagePath) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final file = File(path);
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Imagem enviada com sucesso: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Erro ao enviar imagem para o Firebase Storage: $e');
      throw Exception('Erro ao enviar imagem');
    }
  }

  // Future<void> deleteImageFromStorage(String storagePath) async {
  //   try {
  //     final storageRef = FirebaseStorage.instance.ref().child(storagePath);
  //     await storageRef.delete();
  //     debugPrint('Imagem deletada com sucesso: $storagePath');
  //   } catch (e) {
  //     debugPrint('Erro ao deletar imagem do Firebase Storage: $e');
  //     throw Exception('Erro ao deletar imagem');
  //   }
  // }

  Future<int> sendPackageToFirebase(
      List<PackageModel> selectedPackages, List<InventoryItem> allItems) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('Erro: Usuário não autenticado');
        return 401;
      }

      for (var package in selectedPackages) {
        final packageItems =
            allItems.where((item) => item.packageId == package.id).toList();

        int newId;
        do {
          newId = _random.nextInt(90000000) + 10000000;
        } while (_localPackages.any((p) => p.id == newId));

        package.id = newId;

        package.createdAt = DateTime.now();
        package.userId = user.uid;

        final packageRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('packages')
            .doc(package.id.toString());
        await packageRef.set(package.toMap());

        bool success = true;

        List<String> uploadedUrls = [];
        for (var item in packageItems) {
          item.packageId = package.id;
          item.userId = user.uid;

          if (item.images != null && item.images!.isNotEmpty) {
            for (var imagePath in item.images!) {
              try {
                final imageUrl = await uploadImageToStorage(
                  imagePath,
                  'users/${user.uid}/packages/${package.id}/items/${item.barcode}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                );
                uploadedUrls.add(imageUrl);
              } catch (e) {
                debugPrint(
                    'Erro ao fazer upload de imagem do item ${item.barcode}: $e');
                success = false;
                break;
              }
            }
            if (!success) break;
            item.images = uploadedUrls;
            uploadedUrls = [];
          }

          await packageRef
              .collection('items')
              .doc(item.barcode)
              .set(item.toMap());

          if (!success) break;
        }

        if (success) {
          await clearItemsForPackage(package.id);
          await updatePackagesItemsMap();
        } else {
          debugPrint(
              'Erro no envio do pacote ${package.id}, itens não foram limpos');
          return 502;
        }
      }
      return 200;
    } catch (e) {
      debugPrint('Erro ao enviar para o Firebase: $e');
    }
    return 500;
  }

  Future<void> clearItemsForPackage(int packageId) async {
    final localStorageService = DatabaseHelper();

    try {
      await localStorageService.removeItemsByPackageId(packageId).then((value) {
        _localItems.removeWhere((item) => item.packageId == packageId);
        notifyListeners();
      });
      debugPrint('Itens do pacote #$packageId limpos com sucesso.');
    } catch (e) {
      debugPrint('Erro ao limpar itens do pacote #$packageId: $e');
    }
  }

  Future<void> loadPackages() async {
    final localStorageService = DatabaseHelper();
    _localPackages = await localStorageService.getAllPackages();
    notifyListeners();
  }

  Future<void> updatePackage(PackageModel package) async {
    final localStorageService = DatabaseHelper();

    try {
      await localStorageService.updatePackage(package);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar pacote: $e');
    }
  }

  Future<int> addPackage(PackageModel package) async {
    final localStorageService = DatabaseHelper();

    final existingPackages = await localStorageService.getAllPackages();
    final existingPackage = existingPackages.firstWhere(
      (existingPackage) => existingPackage.id == package.id,
      orElse: () => PackageModel(id: 1, name: '', tags: []),
    );

    if (existingPackage.id != 1) {
      debugPrint('Erro: Já existe um pacote com o mesmo id.');
      return 1;
    }

    try {
      await localStorageService.insertPackage(package);
      _localPackages.add(package);
      notifyListeners();
      return 0;
    } catch (e) {
      debugPrint('Erro ao adicionar pacote: $e');
      return 1;
    }
  }

  Future<void> removePackage(int packageId) async {
    final localStorageService = DatabaseHelper();

    try {
      await localStorageService.removePackage(packageId);

      for (var item in _localItems) {
        if ((item.packageId) == packageId) {
          item.packageId = DEFAULT_PACKAGE_ID;
        }
      }

      _localPackages.removeWhere((package) => package.id == packageId);

      notifyListeners();
      debugPrint('Pacote removido com sucesso! #$packageId');
    } catch (e) {
      debugPrint('Erro ao remover pacote: $e');
    }
  }

  Future<void> loadItems() async {
    final localStorageService = DatabaseHelper();
    _localItems = await localStorageService.getAllItems();
    notifyListeners();
  }

  Future<int> addItem(InventoryItem item) async {
    final localStorageService = DatabaseHelper();

    final existingItems = await localStorageService.getAllItems();
    final existingItem = existingItems.firstWhere(
      (existingItem) => existingItem.barcode == item.barcode,
      orElse: () => InventoryItem(
        barcode: DEFAULT_BARCODE_ID,
        name: '',
        description: '',
        packageId: DEFAULT_PACKAGE_ID,
        location: '',
        geolocation: '',
        observations: '',
        date: DateTime.now(),
        images: [],
      ),
    );

    if (existingItem.barcode != DEFAULT_BARCODE_ID) {
      debugPrint('Erro: Já existe um item com o mesmo barcode.');
      return 1;
    }

    try {
      await localStorageService.saveInventoryItemLocally(item);
      _localItems.add(item);
      notifyListeners();
      return 0;
    } catch (e) {
      debugPrint('Erro ao adicionar item: $e');
    }
    return 1;
  }

  Future<void> removeItem(InventoryItem item) async {
    final localStorageService = DatabaseHelper();

    try {
      await localStorageService.removeItem(item);

      _localItems
          .removeWhere((existingItem) => existingItem.barcode == item.barcode);

      notifyListeners();

      debugPrint('Item de inventário removido com sucesso!');
    } catch (e) {
      debugPrint('Erro ao remover item: $e');
    }
  }

  Future<int> updateItem(InventoryItem item) async {
    final localStorageService = DatabaseHelper();
    try {
      await localStorageService.updateInventoryItem(item);

      final index = _localItems
          .indexWhere((existingItem) => existingItem.barcode == item.barcode);
      _localItems[index] = item;
      notifyListeners();
      return 0;
    } catch (e) {
      debugPrint('Erro ao atualizar item: $e');
    }
    return 1;
  }

  Future<void> clearItems() async {
    final localStorageService = DatabaseHelper();
    await localStorageService.clearItems();
    _localItems.clear();
    notifyListeners();
  }
}
