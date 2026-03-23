import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../api/product_api.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class CreateProductScreen extends StatefulWidget {
  final Product? initialProduct;

  const CreateProductScreen({super.key, this.initialProduct});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  XFile? _pickedImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    if (p != null) {
      _nameController.text = p.name;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _stockController.text = p.stock.toString();
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.gold,
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: AppColors.gold),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.gold,
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: AppColors.gold),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length > 200) return 'Name must not exceed 200 characters';
    return null;
  }

  String? _validateDescription(String? v) {
    if (v == null || v.trim().isEmpty) return 'Description is required';
    if (v.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  String? _validatePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final price = double.tryParse(v.trim());
    if (price == null) return 'Enter a valid number';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  String? _validateStock(String? v) {
    if (v == null || v.trim().isEmpty) return 'Stock is required';
    final stock = int.tryParse(v.trim());
    if (stock == null) return 'Enter a whole number';
    if (stock < 0) return 'Stock cannot be negative';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null && widget.initialProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a product image'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _loading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());

      if (widget.initialProduct != null) {
        await ProductApi.updateProduct(
          id: widget.initialProduct!.id,
          name: name,
          description: description,
          price: price,
          category: _selectedCategory!,
          stock: stock,
          existingImageUrl: widget.initialProduct!.imageUrl,
          newImage: _pickedImage != null ? File(_pickedImage!.path) : null,
        );
      } else {
        await ProductApi.createProduct(
          name: name,
          description: description,
          price: price,
          category: _selectedCategory!,
          stock: stock,
          image: File(_pickedImage!.path),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialProduct != null
                ? 'Product updated successfully!'
                : 'Product created successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final categories = ProductService.categories
        .where((c) => c != 'All')
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.border,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.gold,
          ),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialProduct != null ? 'Edit Product' : 'New Product',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // Image picker
              // ---------------------------------------------------------------
              GestureDetector(
                onTap: _loading ? null : _showImageSourceSheet,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (_pickedImage != null ||
                              widget.initialProduct != null)
                          ? AppColors.gold
                          : AppColors.border,
                      width:
                          (_pickedImage != null ||
                              widget.initialProduct != null)
                          ? 2
                          : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _loading ? null : _showImageSourceSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : widget.initialProduct != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              widget.initialProduct!.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.border,
                                size: 48,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _loading ? null : _showImageSourceSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.goldMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to add product image',
                              style: TextStyle(color: AppColors.goldMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(
                                color: AppColors.goldMuted.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Name
              // ---------------------------------------------------------------
              TextFormField(
                controller: _nameController,
                enabled: !_loading,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // Description
              // ---------------------------------------------------------------
              TextFormField(
                controller: _descriptionController,
                enabled: !_loading,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: _validateDescription,
              ),
              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // Price
              // ---------------------------------------------------------------
              TextFormField(
                controller: _priceController,
                enabled: !_loading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // Category
              // ---------------------------------------------------------------
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: AppColors.surface,
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // Stock
              // ---------------------------------------------------------------
              TextFormField(
                controller: _stockController,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: _validateStock,
              ),
              const SizedBox(height: 28),

              // ---------------------------------------------------------------
              // Submit
              // ---------------------------------------------------------------
              FilledButton(
                onPressed: _loading ? null : _onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        widget.initialProduct != null
                            ? 'Update Product'
                            : 'Post Product',
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
