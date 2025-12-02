import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../src/providers/theme_provider_enhanced.dart';
import '../../../providers/user_provider.dart';
import '../../star/screens/star_dashboard_screen.dart';
import '../../data_integration/screens/data_import_screen.dart';
import '../../../src/features/subscription/screens/subscription_plans_screen.dart';
import '../../../screens/starlist_main_screen.dart' show selectedTabProvider, selectedDrawerPageProvider;

// プロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

class SearchScreen extends ConsumerStatefulWidget {
  final bool isStandalone;
  
  const SearchScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  int? _selectedResultIndex;
  bool _isSearching = false;
  
  // フィルターオプション
  String _sortBy = 'relevance'; // relevance, followers, latest
  bool _verifiedOnly = false;
  String? _selectedCategory;
  RangeValues _followerRange = const RangeValues(0, 500000);

  // 人気スターデータを大幅に追加
  final List<Map<String, dynamic>> _popularStars = [
    {
      'name': 'テックレビューアー田中',
      'category': 'テクノロジー・ガジェット',
      'followers': 245000,
      'avatar': 'T',
      'verified': true,
      'description': '最新ガジェットの詳細レビューと比較',
      'gradientColors': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    },
    {
      'name': '料理研究家佐藤',
      'category': '料理・グルメ',
      'followers': 183000,
      'avatar': 'S',
      'verified': true,
      'description': '簡単で美味しい家庭料理レシピ',
      'gradientColors': [const Color(0xFFFFE66D), const Color(0xFFFF6B6B)],
    },
    {
      'name': 'ゲーム実況者山田',
      'category': 'ゲーム・エンタメ',
      'followers': 327000,
      'avatar': 'G',
      'verified': true,
      'description': 'FPS・RPGゲームの実況とレビュー',
      'gradientColors': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    },
    {
      'name': '旅行ブロガー鈴木',
      'category': '旅行・写真',
      'followers': 158000,
      'avatar': 'T',
      'verified': false,
      'description': '世界各地の絶景スポットと旅行Tips',
      'gradientColors': [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
    },
    {
      'name': 'ファッション系インフルエンサー',
      'category': 'ファッション・ライフスタイル',
      'followers': 281000,
      'avatar': 'F',
      'verified': true,
      'description': 'トレンドファッションとコーディネート',
      'gradientColors': [const Color(0xFFE17055), const Color(0xFFD63031)],
    },
    {
      'name': 'ビジネス系YouTuber中村',
      'category': 'ビジネス・投資',
      'followers': 412000,
      'avatar': 'B',
      'verified': true,
      'description': '投資戦略と起業ノウハウ',
      'gradientColors': [const Color(0xFF6C5CE7), const Color(0x00fda4de)],
    },
    {
      'name': 'アニメレビュアー小林',
      'category': 'アニメ・マンガ',
      'followers': 196000,
      'avatar': 'A',
      'verified': false,
      'description': '最新アニメの詳細レビューと考察',
      'gradientColors': [const Color(0xFFFF7675), const Color(0xFFE84393)],
    },
    {
      'name': 'DIYクリエイター木村',
      'category': 'DIY・ハンドメイド',
      'followers': 124000,
      'avatar': 'D',
      'verified': false,
      'description': '初心者でもできるDIYプロジェクト',
      'gradientColors': [const Color(0xFF00B894), const Color(0xFF00A085)],
    },
    {
      'name': 'プログラミング講師伊藤',
      'category': 'プログラミング・教育',
      'followers': 89000,
      'avatar': 'P',
      'verified': true,
      'description': 'Flutter・React開発チュートリアル',
      'gradientColors': [const Color(0xFF00B894), const Color(0xFF00A085)],
    },
    {
      'name': 'フィットネストレーナー渡辺',
      'category': 'フィットネス・健康',
      'followers': 156000,
      'avatar': 'F',
      'verified': false,
      'description': '自宅でできる効果的なトレーニング',
      'gradientColors': [const Color(0xFFE84393), const Color(0x00fdd5d5)],
    },
  ];

  // カテゴリデータを大幅に追加
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'テクノロジー・ガジェット',
      'icon': Icons.devices,
      'color': const Color(0xFF4ECDC4),
      'starCount': 156,
      'contentCount': 2340,
      'description': 'スマートフォン、PC、最新ガジェットのレビュー',
    },
    {
      'name': '料理・グルメ',
      'icon': Icons.restaurant,
      'color': const Color(0xFFFF6B6B),
      'starCount': 89,
      'contentCount': 1890,
      'description': 'レシピ、レストランレビュー、料理テクニック',
    },
    {
      'name': 'ゲーム・エンタメ',
      'icon': Icons.sports_esports,
      'color': const Color(0xFF667EEA),
      'starCount': 234,
      'contentCount': 4560,
      'description': 'ゲーム実況、レビュー、攻略情報',
    },
    {
      'name': 'ファッション・美容',
      'icon': Icons.checkroom,
      'color': const Color(0xFFE17055),
      'starCount': 178,
      'contentCount': 3210,
      'description': 'コーディネート、メイク、美容情報',
    },
    {
      'name': 'ビジネス・投資',
      'icon': Icons.trending_up,
      'color': const Color(0xFF6C5CE7),
      'starCount': 67,
      'contentCount': 1450,
      'description': '投資戦略、起業ノウハウ、ビジネススキル',
    },
    {
      'name': '旅行・写真',
      'icon': Icons.camera_alt,
      'color': const Color(0xFF74B9FF),
      'starCount': 123,
      'contentCount': 2780,
      'description': '旅行記、写真撮影テクニック、観光情報',
    },
    {
      'name': 'アニメ・マンガ',
      'icon': Icons.movie,
      'color': const Color(0xFFFF7675),
      'starCount': 145,
      'contentCount': 3890,
      'description': 'アニメレビュー、マンガ紹介、声優情報',
    },
    {
      'name': 'フィットネス・健康',
      'icon': Icons.fitness_center,
      'color': const Color(0xFFE84393),
      'starCount': 98,
      'contentCount': 1670,
      'description': 'トレーニング、ダイエット、健康管理',
    },
    {
      'name': 'プログラミング・IT',
      'icon': Icons.code,
      'color': const Color(0xFF00B894),
      'starCount': 76,
      'contentCount': 1230,
      'description': 'プログラミング学習、IT技術解説',
    },
    {
      'name': 'DIY・ハンドメイド',
      'icon': Icons.build,
      'color': const Color(0xFF00A085),
      'starCount': 54,
      'contentCount': 890,
      'description': 'DIYプロジェクト、手作り作品、工具レビュー',
    },
    {
      'name': '音楽・楽器',
      'icon': Icons.music_note,
      'color': const Color(0xFFFFD93D),
      'starCount': 87,
      'contentCount': 1560,
      'description': '楽器演奏、音楽理論、機材レビュー',
    },
    {
      'name': 'ペット・動物',
      'icon': Icons.pets,
      'color': const Color(0xFF55A3FF),
      'starCount': 112,
      'contentCount': 2100,
      'description': 'ペットケア、動物の生態、飼育方法',
    },
  ];

  // 検索結果データを拡充
  final List<Map<String, dynamic>> _searchResults = [
    {
      'type': 'star',
      'name': 'テックレビューアー田中',
      'category': 'テクノロジー・ガジェット',
      'followers': 245000,
      'avatar': 'T',
      'verified': true,
      'description': '最新ガジェットの詳細レビューと比較',
      'gradientColors': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    },
    {
      'type': 'star',
      'name': '料理研究家佐藤',
      'category': '料理・グルメ',
      'followers': 183000,
      'avatar': 'S',
      'verified': true,
      'description': '簡単で美味しい家庭料理レシピ',
      'gradientColors': [const Color(0xFFFFE66D), const Color(0xFFFF6B6B)],
    },
    {
      'type': 'content',
      'title': 'iPhone 15 Pro Max 完全レビュー - カメラ性能が革命的！',
      'star': 'テックレビューアー田中',
      'category': 'テクノロジー・ガジェット',
      'likes': 2340,
      'views': 15200,
      'duration': '25:30',
      'uploadDate': '2日前',
    },
    {
      'type': 'content',
      'title': '30分で作れる絶品パスタレシピ5選',
      'star': '料理研究家佐藤',
      'category': '料理・グルメ',
      'likes': 1560,
      'views': 8900,
      'duration': '12:45',
      'uploadDate': '1日前',
    },
    {
      'type': 'content',
      'title': 'Flutter 3.0 新機能完全解説',
      'star': 'プログラミング講師伊藤',
      'category': 'プログラミング・IT',
      'likes': 890,
      'views': 4560,
      'duration': '32:15',
      'uploadDate': '3日前',
    },
  ];

  final List<String> _trendingKeywords = [
    'iPhone 15',
    'Flutter 3.0',
    'パスタレシピ',
    'ゲーム実況',
    '映画レビュー',
    'ファッション',
    'DIY',
    '投資',
    'アニメ',
    'フィットネス',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // TabControllerの変更を状態に反映
      });
      ref.read(selectedTabProvider.notifier).state = _tabController.index;
    });
    
    // 検索履歴をロード（実際はSharedPreferencesなどから）
    
    // リアルタイム検索のリスナー
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchQuery = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    // If standalone (navigated directly), show with Scaffold and AppBar
    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            '検索',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: _buildContent(isDark),
        ),
      );
    }
    
    // If embedded in main screen, return just the content
    return _buildContent(isDark);
  }
  
  Widget _buildContent(bool isDark) {
    // 検索クエリがある場合は検索結果を表示
    if (_searchQuery.isNotEmpty) {
      return Column(
        children: [
          // 検索バー
          _buildSearchBar(isDark),
          // 検索結果
          Expanded(child: _buildSearchResults()),
        ],
      );
    }
    
    // 検索クエリがない場合はメインコンテンツを表示
    return Column(
      children: [
        // 検索バー
        _buildSearchBar(isDark),
        
        // メインコンテンツ
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 人気のスター
                _buildSectionHeader('人気のスター', '全て見る', isDark),
                const SizedBox(height: 16),
                _buildHorizontalStarList(_popularStars, isDark),
                
                const SizedBox(height: 20),
                
                // スター
                _buildSectionHeader('スター', '全て見る', isDark),
                const SizedBox(height: 16),
                _buildHorizontalStarList(_popularStars.reversed.toList(), isDark),
                
                const SizedBox(height: 20),
                
                // カテゴリ
                _buildSectionHeader('カテゴリ', '全て見る', isDark),
                const SizedBox(height: 16),
                _buildHorizontalCategoryList(isDark),
                
                const SizedBox(height: 20),
                
                // トレンドキーワード
                _buildSectionHeader('トレンドキーワード', null, isDark),
                const SizedBox(height: 16),
                _buildTrendingKeywords(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'スター、コンテンツを検索...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    prefixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSearching
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF4ECDC4),
                                  ),
                                ),
                              ),
                            )
                          : Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.transparent : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.transparent : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onTap: () {},
                  onSubmitted: (query) {
                    _performSearch(query);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    if (_verifiedOnly || _selectedCategory != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showFilterDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionText, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {},
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalStarList(List<Map<String, dynamic>> stars, bool isDark) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: stars.length,
        itemBuilder: (context, index) {
          final star = stars[index];
          final gradientColors = star['gradientColors'] as List<Color>;
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.black).withOpacity( 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withOpacity( 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        star['avatar'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          star['name'],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (star['verified'])
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF4ECDC4),
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    star['category'],
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(star['followers'] / 1000).toStringAsFixed(1)}万',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleFollowAction(star),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'フォロー',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCategoryList(bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'];
                _performCategorySearch(category['name']);
              });
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedCategory == category['name'] 
                      ? category['color'] 
                      : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                  width: _selectedCategory == category['name'] ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_selectedCategory == category['name'] 
                        ? category['color'] 
                        : (isDark ? Colors.black : Colors.black)).withOpacity( 0.1),
                    blurRadius: _selectedCategory == category['name'] ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity( 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'],
                        color: category['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category['starCount']}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingKeywords(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _trendingKeywords.asMap().entries.map((entry) {
        final index = entry.key;
        final keyword = entry.value;
        return GestureDetector(
          onTap: () {
            _searchController.text = keyword;
            _performSearch(keyword);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4ECDC4).withOpacity( 0.1),
                  const Color(0xFF44A08D).withOpacity( 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity( 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Color(0xFF4ECDC4),
                ),
                const SizedBox(width: 6),
                Text(
                  keyword,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final isSelected = _selectedResultIndex == index;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedResultIndex = isSelected ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF4ECDC4)
                    : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.black).withOpacity( 0.08),
                  blurRadius: isSelected ? 20 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: result['type'] == 'star' 
                ? _buildStarResultItem(result, isDark, isSelected)
                : _buildContentResultItem(result, isDark, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildStarResultItem(Map<String, dynamic> star, bool isDark, bool isSelected) {
    final gradientColors = star['gradientColors'] as List<Color>;
    
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity( 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              star['avatar'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      star['name'],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (star['verified'])
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                star['category'],
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                star['description'],
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${(star['followers'] / 1000).toStringAsFixed(1)}万フォロワー',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _handleFollowAction(star),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'フォロー',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentResultItem(Map<String, dynamic> content, bool isDark, bool isSelected) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withOpacity( 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Color(0xFF4ECDC4),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content['title'],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${content['star']} • ${content['category']}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${content['likes']}',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(content['views'] / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    content['duration'],
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'トレンドキーワード',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'すべて見る',
                  style: TextStyle(
                    color: Color(0xFF4ECDC4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _trendingKeywords.asMap().entries.map((entry) {
              final index = entry.key;
              final keyword = entry.value;
              return GestureDetector(
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch(keyword);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4ECDC4).withOpacity( 0.1),
                        const Color(0xFF44A08D).withOpacity( 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withOpacity( 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Color(0xFF4ECDC4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        keyword,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            '注目のコンテンツ',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 注目のコンテンツカード
          ..._searchResults.where((r) => r['type'] == 'content').take(3).map((content) => 
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildContentResultItem(content, isDark, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularStars() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _popularStars.length,
      itemBuilder: (context, index) {
        final star = _popularStars[index];
        final gradientColors = star['gradientColors'] as List<Color>;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.black).withOpacity( 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity( 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    star['avatar'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            star['name'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (star['verified'])
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF4ECDC4),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      star['category'],
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      star['description'],
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(star['followers'] / 1000).toStringAsFixed(1)}万フォロワー',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'フォロー',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['name'];
              _tabController.index = 0; // 検索結果タブに切り替え
              _performCategorySearch(category['name']);
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedCategory == category['name'] 
                    ? category['color'] 
                    : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                width: _selectedCategory == category['name'] ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_selectedCategory == category['name'] 
                      ? category['color'] 
                      : (isDark ? Colors.black : Colors.black)).withOpacity( 0.1),
                  blurRadius: _selectedCategory == category['name'] ? 20 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity( 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'],
                        color: category['color'],
                        size: 24,
                      ),
                    ),
                    if (_selectedCategory == category['name'])
                      Icon(
                        Icons.check_circle,
                        color: category['color'],
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  category['name'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: category['color'],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${category['starCount']}スター',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${(category['contentCount'] / 1000).toStringAsFixed(1)}k',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  category['description'],
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4ECDC4) : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.index = index;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });
    
    // 検索の擬似処理（実際はAPIコール）
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isSearching = false;
      });
    });
  }
  
  void _performCategorySearch(String category) {
    setState(() {
      _searchQuery = 'カテゴリ: $category';
      _selectedCategory = category;
    });
  }
  
  
  void _showFilterDialog() {
    final themeState = ref.read(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'フィルター',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _sortBy = 'relevance';
                          _verifiedOnly = false;
                          _selectedCategory = null;
                          _followerRange = const RangeValues(0, 500000);
                        });
                      },
                      child: const Text(
                        'リセット',
                        style: TextStyle(color: Color(0xFF4ECDC4)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ソート順
                      Text(
                        '並び順',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        {'value': 'relevance', 'label': '関連性'},
                        {'value': 'followers', 'label': 'フォロワー数'},
                        {'value': 'latest', 'label': '最新'},
                      ].map((option) {
                        return RadioListTile<String>(
                          value: option['value']!,
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setModalState(() {
                              _sortBy = value!;
                            });
                          },
                          title: Text(
                            option['label']!,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          activeColor: const Color(0xFF4ECDC4),
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
                      // 認証済みのみ
                      SwitchListTile(
                        value: _verifiedOnly,
                        onChanged: (value) {
                          setModalState(() {
                            _verifiedOnly = value;
                          });
                        },
                        title: Text(
                          '認証済みスターのみ',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '認証マークのあるスターのみ表示',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        thumbColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) => states.contains(WidgetState.selected)
                              ? const Color(0xFF4ECDC4)
                              : null,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // フォロワー数範囲
                      Text(
                        'フォロワー数',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_followerRange.start / 1000).toStringAsFixed(0)}k - ${(_followerRange.end / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      RangeSlider(
                        values: _followerRange,
                        min: 0,
                        max: 500000,
                        divisions: 50,
                        activeColor: const Color(0xFF4ECDC4),
                        inactiveColor: isDark ? Colors.white24 : Colors.black12,
                        onChanged: (values) {
                          setModalState(() {
                            _followerRange = values;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        // フィルターを適用
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '適用',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFollowAction(Map<String, dynamic> star) {
    final currentUser = ref.read(currentUserProvider);
    final themeState = ref.read(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    // フォロー機能の制限チェック
    if (currentUser.isStar) {
      // スターユーザーはフォローできない
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('スターアカウントは他のスターをフォローできません'),
          backgroundColor: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF6B6B),
        ),
      );
      return;
    }
    
    // ファンユーザーのみフォロー可能
    if (currentUser.isFan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${star['name']}をフォローしました'),
          backgroundColor: isDark ? const Color(0xFF4ECDC4) : const Color(0xFF4ECDC4),
        ),
      );
    }
  }

  Widget _buildDrawer() {
    final currentUser = ref.watch(currentUserProvider);
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        children: [
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4ECDC4),
                    Color(0xFF44A08D),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Starlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          currentUser.isStar ? 'スター' : 'ファン',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(Icons.home, 'ホーム', () => _navigateToHome()),
                _buildDrawerItem(Icons.search, '検索', null, isActive: true),
                _buildDrawerItem(Icons.star, 'マイリスト', () => _navigateToMylist()),
                // スターのみ表示
                if (currentUser.isStar) ...[
                  _buildDrawerItem(Icons.camera_alt, 'データ取込み', () => _navigateToDataImport()),
                  _buildDrawerItem(Icons.analytics, 'スターダッシュボード', () => _navigateToStarDashboard()),
                  _buildDrawerItem(Icons.workspace_premium, 'プランを管理', () => _navigateToPlanManagement()),
                ],
                _buildDrawerItem(Icons.person, 'マイページ', () => _navigateToProfile()),
                // ファンのみ課金プラン表示
                if (currentUser.isFan) ...[
                  _buildDrawerItem(Icons.credit_card, '課金プラン', () => _navigateToPlanManagement()),
                ],
                _buildDrawerItem(Icons.settings, '設定', () => _navigateToSettings()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback? onTap, {bool isActive = false}) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive ? const Color(0xFF4ECDC4).withOpacity( 0.15) : null,
        border: isActive ? Border.all(
          color: const Color(0xFF4ECDC4).withOpacity( 0.3),
          width: 1,
        ) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive 
              ? const Color(0xFF4ECDC4)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive 
              ? Colors.white
              : (isDark ? Colors.white54 : Colors.grey.shade600),
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive 
              ? const Color(0xFF4ECDC4) 
              : (isDark ? Colors.white : Colors.grey.shade800),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: isActive ? const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF4ECDC4),
          size: 14,
        ) : null,
        onTap: onTap != null ? () {
          Navigator.of(context).pop();
          onTap();
        } : null,
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    ref.read(selectedDrawerPageProvider.notifier).state = null;
    ref.read(selectedTabProvider.notifier).state = 0;
    context.go('/home');
  }


  void _navigateToMylist() {
    if (!mounted) return;
    ref.read(selectedDrawerPageProvider.notifier).state = null;
    ref.read(selectedTabProvider.notifier).state = 1;
    context.go('/home');
  }

  void _navigateToDataImport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DataImportScreen()),
    );
  }

  void _navigateToStarDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StarDashboardScreen()),
    );
  }

  void _navigateToPlanManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen()),
    );
  }

  void _navigateToProfile() {
    if (!mounted) return;
    ref.read(selectedDrawerPageProvider.notifier).state = null;
    ref.read(selectedTabProvider.notifier).state = 4;
    context.go('/home');
  }

  void _navigateToSettings() {
    if (!mounted) return;
    ref.read(selectedDrawerPageProvider.notifier).state = 'settings';
    context.go('/settings');
  }
} 
