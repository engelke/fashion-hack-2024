import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text, TextStyle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/vision_service.dart';
import '../models/item.dart';
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

  String? _expression;
  String? _temperature;
  String? _season;
  String? _outfitSuggestions;
  bool _isLoadingSuggestions = false;

  final Map<String, String> _imageUrlCache = {};
  final Set<String> _failedImageIds = {};

  final TextStyle _cardTitleStyle = GoogleFonts.inter(
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().getItems();
      if (mounted) {
        setState(() {
          _items = items;
          // Cache the signed URLs that we got from the API service
          for (var item in items) {
            _imageUrlCache[item.id] = item.imageUrl;
          }
          _availableCategories =
              _items.map((item) => toTitleCase(item.clothingType)).toSet();
          _availableColors =
              _items.map((item) => toTitleCase(item.color)).toSet();
          _availableStyles =
              _items.map((item) => toTitleCase(item.style)).toSet();
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _getCachedImageUrl(String itemId) {
    return _imageUrlCache[itemId];
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredItems = _items
          .where((item) =>
              (_selectedCategory == null ||
                  toTitleCase(item.clothingType) == _selectedCategory) &&
              (_selectedColor == null ||
                  toTitleCase(item.color) == _selectedColor) &&
              (_selectedStyle == null ||
                  toTitleCase(item.style) == _selectedStyle))
          .toList();
      print(
          'Applied filters: Category: $_selectedCategory, Color: $_selectedColor, Style: $_selectedStyle');
      print('Filtered to ${_filteredItems.length} items');
    });
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    Set<String> options,
    void Function(String?) onChanged,
  ) {
    return Expanded(
      child: DropdownButton<String>(
        value: value,
        hint: material.Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: material.Text(
              'All $label\s',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          ...options.map((option) => DropdownMenuItem<String>(
                value: option,
                child: material.Text(
                  option,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              )),
        ],
        onChanged: onChanged,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: material.Text(
        toTitleCase(style),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: FutureBuilder<String?>(
                          future: ApiService().getSignedUrl(item.imageUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              );
                            }
                            return Image.network(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                );
                              },
                            );
                          },
                        ),
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
                          child: material.Text(
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
    final cachedUrl = _getCachedImageUrl(item.id);
    if (cachedUrl == null) return;

    final itemTitle =
        '${toTitleCase(item.color)} ${toTitleCase(item.material)} ${toTitleCase(item.clothingType)}';
    final showOccasion =
        item.occasion.toLowerCase() != item.style.toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.width -
                              40, // Square aspect ratio
                          margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              cachedUrl,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded || frame != null) {
                                  return child;
                                }
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                Navigator.pop(context);
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 32,
                          child: _buildStyleBadge(item.style),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: material.Text(
                        itemTitle,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.purple.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.style, size: 24),
                              const SizedBox(width: 12),
                              material.Text(
                                'Get Outfit Ideas',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Expression',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  value: _expression,
                                  items: ['Masculine', 'Feminine']
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: material.Text(e)))
                                      .toList(),
                                  onChanged: (value) =>
                                      setModalState(() => _expression = value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Temperature',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  value: _temperature,
                                  items: ['Hot', 'Cold']
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: material.Text(e)))
                                      .toList(),
                                  onChanged: (value) =>
                                      setModalState(() => _temperature = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Season',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: _season,
                            items: ['Spring', 'Summer', 'Fall', 'Winter']
                                .map((e) => DropdownMenuItem(
                                    value: e, child: material.Text(e)))
                                .toList(),
                            onChanged: (value) =>
                                setModalState(() => _season = value),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _expression != null &&
                                      _temperature != null &&
                                      _season != null &&
                                      !_isLoadingSuggestions
                                  ? () async {
                                      setModalState(() {
                                        _isLoadingSuggestions = true;
                                        _outfitSuggestions = null;
                                      });
                                      try {
                                        final suggestions =
                                            await VisionService()
                                                .getOutfitSuggestions(
                                          item:
                                              '${item.color} ${item.material} ${item.style} ${item.clothingType}',
                                          expression: _expression!,
                                          temperature: _temperature!,
                                          season: _season!,
                                        );
                                        setModalState(() {
                                          _outfitSuggestions = suggestions;
                                          _isLoadingSuggestions = false;
                                        });
                                      } catch (e) {
                                        setModalState(() {
                                          _isLoadingSuggestions = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: material.Text(
                                                'Failed to get outfit suggestions'),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoadingSuggestions)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                  material.Text(
                                    _isLoadingSuggestions
                                        ? 'Getting Ideas...'
                                        : 'Get Outfit Ideas',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_outfitSuggestions != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: MarkdownBody(
                                data: _outfitSuggestions!,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.black87,
                                    fontFamily: 'Inter',
                                  ),
                                  strong: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 2,
                                    fontFamily: 'Inter',
                                  ),
                                  listBullet: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontFamily: 'Inter',
                                  ),
                                  blockSpacing: 12,
                                  listIndent: 20,
                                  listBulletPadding:
                                      const EdgeInsets.only(right: 8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Material', item.material),
                                if (showOccasion) ...[
                                  const Divider(height: 24),
                                  _buildDetailRow('Occasion', item.occasion),
                                ],
                                const Divider(height: 24),
                                _buildDetailRow('Style', item.style),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailImage(Item item) {
    final cachedUrl = _getCachedImageUrl(item.id);
    if (cachedUrl == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return Image.network(
      cachedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: material.Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: material.Text(
            toTitleCase(value),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const material.Text(
        'Coming Soon',
        style: material.TextStyle(
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
            title: const material.Text('Closet'),
            leading: const Icon(Icons.grid_view),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: material.Text('Add Item')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.add_circle_outline),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Row(
              children: [
                const Expanded(child: material.Text('Stats')),
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
                const Expanded(child: material.Text('Items from Email')),
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
                const Expanded(child: material.Text('Boards')),
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
                const Expanded(child: material.Text('Outfit of the Day')),
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
            title: Row(
              children: [
                const Expanded(child: material.Text('Settings')),
                const SizedBox(width: 8),
                _buildComingSoonBadge(),
              ],
            ),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getItemTitle(Item item) {
    return '${toTitleCase(item.color)} ${toTitleCase(item.clothingType)}';
  }

  Widget _buildGridItem(BuildContext context, Item item) {
    final cachedUrl = _getCachedImageUrl(item.id);
    if (cachedUrl == null) {
      print('No cached URL for item ${item.id}');
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showItemDetails(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              cachedUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image for item ${item.id}: $error');
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  print('Successfully loaded image for item ${item.id}');
                  return child;
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
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
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: material.Text(
                  _getItemTitle(item),
                  style: _cardTitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
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
                  label: material.Text(
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
                    label: material.Text(
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              material.Text(
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: material.Text(
          'Closet',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: material.Text(
                          'No items found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildGridItem(context, item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
