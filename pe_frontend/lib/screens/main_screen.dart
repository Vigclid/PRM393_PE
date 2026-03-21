import 'dart:async';

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/socket_service.dart';
import '../session/user_session.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'create_product_screen.dart';
import 'notification_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';

enum SortOption {
  nameAsc('Name: A → Z'),
  nameDesc('Name: Z → A'),
  priceLow('Price: Low → High'),
  priceHigh('Price: High → Low'),
  ratingHigh('Rating: High → Low'),
  stockHigh('Stock: Most first'),
  stockLow('Stock: Least first');

  final String label;
  const SortOption(this.label);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filtered = [];
  String _selectedCategory = 'All';
  SortOption _sortOption = SortOption.nameAsc;
  bool _loading = true;
  String? _error;
  int _unreadNotifCount = 0;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_applyFilters);
    _connectSocket();
  }

  void _connectSocket() {
    final userId = UserSession.instance.currentUser?.id;
    if (userId == null) return;
    SocketService.instance.connect(userId);
    _notifSub = SocketService.instance.notificationStream.listen((_) {
      if (mounted) setState(() => _unreadNotifCount++);
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ProductService.fetchProducts();
      setState(() {
        _allProducts = products;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load products. Please try again.';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final results = _allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    results.sort(
      (a, b) => switch (_sortOption) {
        SortOption.nameAsc => a.name.compareTo(b.name),
        SortOption.nameDesc => b.name.compareTo(a.name),
        SortOption.priceLow => a.price.compareTo(b.price),
        SortOption.priceHigh => b.price.compareTo(a.price),
        SortOption.ratingHigh => b.rating.compareTo(a.rating),
        SortOption.stockHigh => b.stock.compareTo(a.stock),
        SortOption.stockLow => a.stock.compareTo(b.stock),
      },
    );

    setState(() => _filtered = results);
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort by',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<SortOption>(
                groupValue: _sortOption,
                onChanged: (selected) {
                  if (selected == null) return;
                  setSheetState(() {});
                  setState(() => _sortOption = selected);
                  _applyFilters();
                  Navigator.pop(ctx);
                },
                child: Column(
                  children: SortOption.values
                      .map(
                        (option) => RadioListTile<SortOption>(
                          value: option,
                          title: Text(
                            option.label,
                            style: TextStyle(
                              color: _sortOption == option
                                  ? AppColors.gold
                                  : AppColors.goldMuted,
                              fontWeight: _sortOption == option
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          activeColor: AppColors.gold,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.border,
        title: const Text(
          'XS Market',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.gold,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.gold,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProductScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.gold),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.gold),
                onPressed: () async {
                  setState(() => _unreadNotifCount = 0);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadNotifCount > 99 ? '99+' : '$_unreadNotifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: _ProfileAvatar(
              email: UserSession.instance.currentUser?.email ?? '',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchController),
          _CategoryFilter(
            categories: ProductService.categories,
            selected: _selectedCategory,
            onSelect: _selectCategory,
          ),
          _SortBar(
            resultCount: _filtered.length,
            sortOption: _sortOption,
            onSortTap: _openSortSheet,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
        ),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
        icon: const Icon(Icons.forum_outlined),
        label: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: AppColors.goldMuted, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No products found',
              style: TextStyle(color: AppColors.goldMuted),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      onRefresh: _loadProducts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: _filtered[index]),
              ),
            );
            if (result == true) _loadProducts();
          },
          child: _ProductCard(product: _filtered[index]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.gold),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: AppColors.goldMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.goldMuted),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.goldMuted),
                    onPressed: () => controller.clear(),
                  )
                : const SizedBox.shrink(),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category filter chips
// ---------------------------------------------------------------------------
class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories
              .map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected == cat,
                    onSelected: (_) => onSelect(cat),
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.background,
                    checkmarkColor: AppColors.onGold,
                    labelStyle: TextStyle(
                      color: selected == cat
                          ? AppColors.onGold
                          : AppColors.goldMuted,
                      fontWeight: selected == cat
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected == cat
                          ? AppColors.gold
                          : AppColors.border,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort bar — result count + active sort label + sort button
// ---------------------------------------------------------------------------
class _SortBar extends StatelessWidget {
  final int resultCount;
  final SortOption sortOption;
  final VoidCallback onSortTap;

  const _SortBar({
    required this.resultCount,
    required this.sortOption,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$resultCount result${resultCount == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.goldMuted, fontSize: 13),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSortTap,
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  sortOption.label,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.gold,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product card
// ---------------------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final inStock = product.stock > 0;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              product.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: AppColors.background,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: AppColors.border,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge + stock
                Row(
                  children: [
                    _Badge(label: product.category),
                    const Spacer(),
                    Icon(
                      inStock
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 14,
                      color: inStock ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      inStock ? 'In stock (${product.stock})' : 'Out of stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: inStock ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.goldMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),

                // Price + rating
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navbar profile avatar — shows initials derived from the user's email
// ---------------------------------------------------------------------------
class _ProfileAvatar extends StatelessWidget {
  final String email;
  const _ProfileAvatar({required this.email});

  String get _initials {
    if (email.isEmpty) return '?';
    final local = email.split('@').first;
    final parts = local.split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.gold,
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppColors.onGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
