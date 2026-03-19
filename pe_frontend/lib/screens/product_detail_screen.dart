import 'package:flutter/material.dart';
import 'package:pe_frontend/screens/cart_screen.dart';
import '../api/api_client.dart';
import '../api/cart_api.dart';
import '../api/product_api.dart';
import '../models/product.dart';
import '../session/user_session.dart';
import '../theme/app_theme.dart';
import 'create_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _deleting = false;

  bool get _isOwner =>
      widget.product.userId == UserSession.instance.currentUser?.id;

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProductScreen(initialProduct: widget.product),
      ),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Product',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"?',
          style: const TextStyle(color: AppColors.goldMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ProductApi.deleteProduct(widget.product.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to delete product. Please try again.');
    } finally {
      if (mounted) setState(() => _deleting = false);
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final inStock = product.stock > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ---------------------------------------------------------------
          // Collapsible app bar with product image
          // ---------------------------------------------------------------
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.gold,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: _isOwner
                ? [
                    if (_deleting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.gold,
                        ),
                        onPressed: _onEdit,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: _onDelete,
                      ),
                    ],
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${product.id}',
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder,
                      )
                    : _imagePlaceholder,
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // Content
          // ---------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge + stock status
                  Row(
                    children: [
                      _Badge(label: product.category),
                      const Spacer(),
                      Icon(
                        inStock
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 16,
                        color: inStock ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        inStock
                            ? 'In stock (${product.stock})'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: inStock
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                      const Spacer(),
                      _StarRating(rating: product.rating),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.goldMuted,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details card
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  const Text(
                    'Details',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: product.category,
                  ),
                  _DetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    value: '${product.stock} units',
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Listed on',
                    value: _formatDate(product.createdAt),
                  ),
                  _DetailRow(
                    icon: Icons.fingerprint,
                    label: 'Product ID',
                    value: '${product.id.substring(0, 8)}…',
                  ),
                  const SizedBox(height: 100), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ---------------------------------------------------------------
      // Sticky Add to Cart bottom bar
      // ---------------------------------------------------------------
      bottomNavigationBar: _BottomBar(product: product),
    );
  }

  Widget get _imagePlaceholder => Container(
    color: AppColors.surface,
    child: const Center(
      child: Icon(Icons.image_not_supported, color: AppColors.border, size: 64),
    ),
  );
}

// ---------------------------------------------------------------------------
// Star rating display
// ---------------------------------------------------------------------------
class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return const Icon(
              Icons.star_rounded,
              color: AppColors.gold,
              size: 20,
            );
          } else if (i < rating) {
            return const Icon(
              Icons.star_half_rounded,
              color: AppColors.gold,
              size: 20,
            );
          } else {
            return const Icon(
              Icons.star_outline_rounded,
              color: AppColors.goldMuted,
              size: 20,
            );
          }
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row item
// ---------------------------------------------------------------------------
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldMuted, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: AppColors.goldMuted, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category badge
// ---------------------------------------------------------------------------
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom bar — Add to Cart
// ---------------------------------------------------------------------------
class _BottomBar extends StatefulWidget {
  final Product product;
  const _BottomBar({required this.product});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  int _quantity = 1;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final inStock = widget.product.stock > 0;
    final canAct = inStock && !_loading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: canAct && _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: canAct && _quantity < widget.product.stock
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Add to cart button
          Expanded(
            child: FilledButton.icon(
              onPressed: canAct ? () => _onAddToCart() : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: inStock ? AppColors.gold : AppColors.border,
                foregroundColor: AppColors.onGold,
                disabledBackgroundColor: AppColors.border,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onGold,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined, size: 20),
              label: Text(
                inStock ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddToCart() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _loading = true);
    try {
      await CartApi.updateCart(
        productId: widget.product.id,
        priceAtTime: widget.product.price,
        quantity: _quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity × ${widget.product.name} added to cart'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
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
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.gold : AppColors.border,
        ),
      ),
    );
  }
}
