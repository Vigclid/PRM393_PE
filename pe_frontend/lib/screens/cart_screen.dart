import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/bill_api.dart';
import '../api/cart_api.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem>? _items;
  bool _loading = true;
  String? _error;
  final Set<String> _updatingItems = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------
  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await CartApi.fetchCart();
      if (!mounted) return;
      setState(() {
        _items = cart.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load cart. Please try again.';
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Quantity update — optimistic UI
  // ---------------------------------------------------------------------------
  Future<void> _updateQuantity(CartItem item, int newQty) async {
    final snapshot = List<CartItem>.from(_items!);

    setState(() {
      _updatingItems.add(item.id);
      if (newQty <= 0) {
        _items!.removeWhere((i) => i.id == item.id);
      } else {
        final idx = _items!.indexWhere((i) => i.id == item.id);
        if (idx != -1) _items![idx] = item.copyWith(quantity: newQty);
      }
    });

    try {
      await CartApi.updateCart(
        productId: item.product.id,
        priceAtTime: item.priceAtTime,
        quantity: newQty,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _items = snapshot);
      _showError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _items = snapshot);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = snapshot);
      _showError('Failed to update cart. Please try again.');
    } finally {
      if (mounted) setState(() => _updatingItems.remove(item.id));
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

  double get _total =>
      (_items ?? []).fold(0.0, (sum, item) => sum + item.subtotal);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _items != null && _items!.isNotEmpty
          ? _BottomBar(
              total: _total,
              onCheckout: _onCheckout,
              isLoading: _checkingOut,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.goldMuted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_items == null || _items!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.goldMuted,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(color: AppColors.goldMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _CartItemCard(
        item: _items![index],
        isUpdating: _updatingItems.contains(_items![index].id),
        onDecrease: () =>
            _updateQuantity(_items![index], _items![index].quantity - 1),
        onIncrease: () =>
            _updateQuantity(_items![index], _items![index].quantity + 1),
      ),
    );
  }

  bool _checkingOut = false;

  Future<void> _onCheckout() async {
    if (_checkingOut) return;
    setState(() => _checkingOut = true);
    try {
      await BillApi.checkout();
      if (!mounted) return;
      setState(() => _items = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          behavior: SnackBarBehavior.floating,
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
      _showError('Checkout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Cart item card
// ---------------------------------------------------------------------------
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isUpdating;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CartItemCard({
    required this.item,
    required this.isUpdating,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.imageUrl.isNotEmpty
                ? Image.network(
                    item.product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder,
                  )
                : _placeholder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.product.category,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${item.priceAtTime.toStringAsFixed(2)} each',
                      style: const TextStyle(
                        color: AppColors.goldMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _QtyControl(
                      quantity: item.quantity,
                      isUpdating: isUpdating,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                      maxStock: item.product.stock,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _placeholder => Container(
    width: 80,
    height: 80,
    color: AppColors.background,
    child: const Icon(
      Icons.image_not_supported,
      color: AppColors.border,
      size: 28,
    ),
  );
}

// ---------------------------------------------------------------------------
// Quantity control
// ---------------------------------------------------------------------------
class _QtyControl extends StatelessWidget {
  final int quantity;
  final bool isUpdating;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final int maxStock;

  const _QtyControl({
    required this.quantity,
    required this.isUpdating,
    required this.onDecrease,
    required this.onIncrease,
    required this.maxStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
            color: quantity == 1 ? Colors.redAccent : AppColors.gold,
            onTap: isUpdating ? null : onDecrease,
          ),
          if (isUpdating)
            const SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.gold,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: 28,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          _btn(
            icon: Icons.add,
            color: quantity < maxStock ? AppColors.gold : AppColors.border,
            onTap: isUpdating || quantity >= maxStock ? null : onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar — total + checkout
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;
  final bool isLoading;

  const _BottomBar({
    required this.total,
    required this.onCheckout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: AppColors.goldMuted, fontSize: 12),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: FilledButton(
              onPressed: isLoading ? null : onCheckout,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.onGold,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onGold,
                      ),
                    )
                  : const Text(
                      'Checkout',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
