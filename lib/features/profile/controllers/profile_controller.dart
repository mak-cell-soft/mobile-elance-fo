import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  final ProfileService _service = ProfileService();

  final status = ViewStatus.initial.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String login = '';

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    final userId = StorageService.instance.userId;
    if (userId == null) {
      status.value = ViewStatus.success;
      _initFromStorage();
      return;
    }

    status.value = ViewStatus.loading;
    errorMessage.value = null;

    try {
      final data = await _service.fetchProfile(userId);
      login = data['login'] as String? ?? '';
      emailController.text = data['email'] as String? ?? StorageService.instance.userEmail ?? '';

      final person = data['person'] as Map<String, dynamic>?;
      if (person != null) {
        firstNameController.text = person['firstname'] as String? ?? '';
        lastNameController.text = person['lastname'] as String? ?? '';
        phoneController.text = person['phonenumber'] as String? ?? '';
        addressController.text = person['address'] as String? ?? '';
      } else {
        _initFromStorage();
      }

      status.value = ViewStatus.success;
    } on ApiException catch (e) {
      status.value = ViewStatus.error;
      errorMessage.value = e.message;
      _initFromStorage();
    }
  }

  void _initFromStorage() {
    final fullName = StorageService.instance.fullName ?? '';
    final parts = fullName.split(' ');
    if (parts.isNotEmpty) {
      firstNameController.text = parts.first;
      if (parts.length > 1) {
        lastNameController.text = parts.sublist(1).join(' ');
      }
    }
    emailController.text = StorageService.instance.userEmail ?? '';
  }

  Future<bool> saveProfile() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      errorMessage.value = 'Prénom, nom et e-mail sont requis.';
      return false;
    }

    isSaving.value = true;
    errorMessage.value = null;

    try {
      await _service.updateProfile(
        email: email,
        login: login.isNotEmpty ? login : email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
      );

      final newFullName = '$firstName $lastName';
      await StorageService.instance.saveSession(
        token: StorageService.instance.token ?? '',
        fullName: newFullName,
        enterpriseName: StorageService.instance.enterpriseName,
      );

      isSaving.value = false;
      successMessage.value = 'Profil mis à jour avec succès';
      return true;
    } on ApiException catch (e) {
      isSaving.value = false;
      errorMessage.value = e.message;
      return false;
    }
  }
}
