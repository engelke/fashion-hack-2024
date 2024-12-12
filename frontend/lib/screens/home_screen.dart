import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../screens/add_item_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedStyle;
  final Map<String, Color> _styleColors = {};

  Set<String> _availableCategories = {};
  Set<String> _availableColors = {};
  Set<String> _availableStyles = {};

  final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.red,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _apiService.getItems();
      setState(() {
        _items = items;
        // Extract unique values from the database
        _availableCategories =
            items.map((item) => toTitleCase(item.clothingType)).toSet();
        _availableColors = items.map((item) => toTitleCase(item.color)).toSet();
        _availableStyles = items.map((item) => toTitleCase(item.style)).toSet();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Item> filtered = List.from(_items);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((item) {
        return toTitleCase(item.clothingType) == _selectedCategory;
      }).toList();
    }

    // Apply color filter
    if (_selectedColor != null) {
      filtered = filtered.where((item) {
        return toTitleCase(item.color) == _selectedColor;
      }).toList();
    }

    // Apply style filter
    if (_selectedStyle != null) {
      filtered = filtered.where((item) {
        return toTitleCase(item.style) == _selectedStyle;
      }).toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  Widget _buildFilterDropdown(String label, String? value, Set<String> options,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          borderRadius: BorderRadius.circular(8),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All $label\s',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _getStyleColor(String style) {
    if (!_styleColors.containsKey(style)) {
      final colorIndex = _styleColors.length % _predefinedColors.length;
      _styleColors[style] = _predefinedColors[colorIndex];
    }
    return _styleColors[style]!;
  }

  TextStyle get _cardTitleStyle => GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
        shadows: [
          Shadow(
            offset: const Offset(0, 1),
            blurRadius: 3.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      );

  TextStyle get _modalTitleStyle => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.3,
      );

  TextStyle get _detailLabelStyle => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
        fontSize: 14,
      );

  TextStyle get _detailValueStyle => GoogleFonts.inter(
        fontSize: 16,
        height: 1.4,
      );

  Widget _buildStyleBadge(String style) {
    final color = _getStyleColor(style);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 2.0,
            color: Colors.black.withOpacity(0.2),
          ),
        ],
      ),
      child: Text(
        toTitleCase(style),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildItemCard(Item item) {
    final title =
        '${toTitleCase(item.color)} ${toTitleCase(item.material)} ${toTitleCase(item.clothingType)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () => _showItemDetails(context, item),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.85),
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            title,
                            style: _cardTitleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _buildStyleBadge(item.style),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Item item) {
    final title =
        '${toTitleCase(item.color)} ${toTitleCase(item.material)} ${toTitleCase(item.clothingType)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStyleBadge(item.style),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: _modalTitleStyle,
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Material', toTitleCase(item.material)),
                _buildDetailRow('Occasion', toTitleCase(item.occasion)),
                _buildDetailRow('Style', toTitleCase(item.style)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit functionality
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(
                    'Edit Item',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: _detailLabelStyle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: _detailValueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Coming Soon',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: const Logo(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Closet'),
            leading: const Icon(Icons.grid_view),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Add Item'),
            leading: const Icon(Icons.add_circle_outline),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemScreen()),
              );
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: Text('Stats')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.bar_chart),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: Text('Items from Email')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.email),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: Text('Boards')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.dashboard),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: Text('Outfit of the Day')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.style),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Calculate number of columns based on screen width
    int crossAxisCount;
    if (width < 500) {
      crossAxisCount = 1;
    } else if (width < 600) {
      crossAxisCount = 2;
    } else if (width < 900) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8, // Makes items half as tall (0.75 * 2 = 1.5)
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Closet',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? SizedBox.expand(
              child: Container(
                width: size.width,
                height: size.height,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : Column(
              children: [
                // Category tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // "All" category chip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            'All Items',
                            style: GoogleFonts.inter(
                              fontWeight: _selectedCategory == null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = null;
                                _applyFiltersAndSort();
                              });
                            }
                          },
                        ),
                      ),
                      ..._availableCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: GoogleFonts.inter(
                                fontWeight: _selectedCategory == category
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                                _applyFiltersAndSort();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Filter dropdowns
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Filter by:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        'Color',
                        _selectedColor,
                        _availableColors,
                        (value) {
                          setState(() {
                            _selectedColor = value;
                            _applyFiltersAndSort();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        'Style',
                        _selectedStyle,
                        _availableStyles,
                        (value) {
                          setState(() {
                            _selectedStyle = value;
                            _applyFiltersAndSort();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Grid of items
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'No items found',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : _buildResponsiveGrid(context),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
