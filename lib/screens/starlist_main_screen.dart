import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 画面のインポート
import '../features/search/screens/search_screen.dart';
import '../features/mylist/screens/mylist_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/data_integration/screens/data_import_screen.dart';
import '../features/star/screens/star_dashboard_screen.dart';
import '../src/features/gacha/presentation/gacha_screen.dart';
import '../features/content/screens/post_detail_screen.dart';
import '../src/features/subscription/screens/subscription_plans_screen.dart';
import '../src/features/points/screens/star_points_purchase_screen.dart';
import 'login_status_screen.dart';
import 'test_account_switcher_screen.dart';
import 'star_data_view_page.dart';
import 'package:starlist_app/src/features/star_data/presentation/star_data_view_page_simple.dart';

// プロバイダー・サービス
import '../providers/user_provider.dart';
import '../src/providers/theme_provider_enhanced.dart';
import '../providers/youtube_history_provider.dart';
import '../providers/posts_provider.dart';
import '../services/access_control_service.dart';

// ウィジェット・モデル
import '../src/core/components/service_icons.dart';
import '../src/widgets/post_card.dart';
import '../data/models/post_model.dart';
import '../models/user.dart';

// データモデル
class StarData {
  final String name;
  final String category;
  final String followers;
  final String avatar;
  final List<Color> gradientColors;
  final bool isFollowing;

  StarData({
    required this.name,
    required this.category,
    required this.followers,
    required this.avatar,
    required this.gradientColors,
    this.isFollowing = false,
  });
}

class ContentData {
  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final Color iconColor;
  final String timeAgo;

  ContentData({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.timeAgo,
  });
}

// プロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);
final selectedDataTypeProvider = StateProvider<String?>((ref) => null);
final selectedDrawerPageProvider = StateProvider<String?>((ref) => null);

class StarlistMainScreen extends ConsumerStatefulWidget {
  const StarlistMainScreen({super.key});

  @override
  ConsumerState<StarlistMainScreen> createState() => _StarlistMainScreenState();
}

class _StarlistMainScreenState extends ConsumerState<StarlistMainScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ScrollController _scrollController;
  bool _isRedirectingToLogin = false;

  // サンプルデータ
  final List<StarData> recommendedStars = [
    StarData(
      name: 'テックレビューアー田中',
      category: 'テクノロジー / ガジェット',
      followers: '24.5万',
      avatar: 'T1',
      gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    ),
    StarData(
      name: '料理研究家佐藤',
      category: '料理・グルメ / レシピ',
      followers: '18.3万',
      avatar: 'S2',
      gradientColors: [const Color(0xFFFFE66D), const Color(0xFFFF6B6B)],
    ),
    StarData(
      name: 'ゲーム実況者山田',
      category: 'ゲーム / エンタメ',
      followers: '32.7万',
      avatar: 'G3',
      gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    ),
    StarData(
      name: '旅行ブロガー鈴木',
      category: '旅行 / 写真',
      followers: '15.8万',
      avatar: 'T4',
      gradientColors: [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
    ),
    StarData(
      name: 'ファッション系インフルエンサー',
      category: 'ファッション / ライフスタイル',
      followers: '28.1万',
      avatar: 'F5',
      gradientColors: [const Color(0xFFE17055), const Color(0xFFD63031)],
    ),
    StarData(
      name: 'ビジネス系YouTuber中村',
      category: 'ビジネス / 投資',
      followers: '41.2万',
      avatar: 'B6',
      gradientColors: [const Color(0xFF6C5CE7), const Color(0x00fda4de)],
    ),
    StarData(
      name: 'アニメレビュアー小林',
      category: 'アニメ / マンガ',
      followers: '19.6万',
      avatar: 'A7',
      gradientColors: [const Color(0xFFFF7675), const Color(0xFFE84393)],
    ),
    StarData(
      name: 'DIYクリエイター木村',
      category: 'DIY / ハンドメイド',
      followers: '12.4万',
      avatar: 'D8',
      gradientColors: [const Color(0xFF00B894), const Color(0xFF00A085)],
    ),
  ];

  final List<StarData> newStars = [
    StarData(
      name: 'プログラミング講師伊藤',
      category: 'プログラミング / 教育',
      followers: '5.2万',
      avatar: 'P1',
      gradientColors: [const Color(0xFF00B894), const Color(0xFF00A085)],
    ),
    StarData(
      name: 'フィットネストレーナー渡辺',
      category: 'フィットネス / 健康',
      followers: '8.9万',
      avatar: 'F2',
      gradientColors: [const Color(0xFFE84393), const Color(0x00fdd5d5)],
    ),
    StarData(
      name: 'アート系クリエイター高橋',
      category: 'アート / デザイン',
      followers: '3.8万',
      avatar: 'A3',
      gradientColors: [const Color(0xFF6C5CE7), const Color(0x00fda4de)],
    ),
    StarData(
      name: '音楽プロデューサー松本',
      category: '音楽 / DTM',
      followers: '7.1万',
      avatar: 'M4',
      gradientColors: [const Color(0xFFFFD93D), const Color(0xFFFF6B35)],
    ),
    StarData(
      name: 'ペット系YouTuber佐々木',
      category: 'ペット / 動物',
      followers: '11.3万',
      avatar: 'P5',
      gradientColors: [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
    ),
    StarData(
      name: '語学学習コーチ田村',
      category: '語学 / 教育',
      followers: '6.7万',
      avatar: 'L6',
      gradientColors: [const Color(0xFF55A3FF), const Color(0xFF003D82)],
    ),
  ];

  final List<ContentData> recentContent = [
    ContentData(
      title: 'iPhone 15 Pro Max 詳細レビュー',
      subtitle: 'テックレビューアー田中 • 25:30',
      type: '動画',
      icon: Icons.play_arrow,
      iconColor: const Color(0xFF4ECDC4),
      timeAgo: '2時間前',
    ),
    ContentData(
      title: 'Sony α7 IV ミラーレスカメラ',
      subtitle: 'Amazon • ¥289,800',
      type: '商品',
      icon: Icons.shopping_bag,
      iconColor: const Color(0xFFFFE66D),
      timeAgo: '3時間前',
    ),
    ContentData(
      title: '簡単チキンカレーの作り方',
      subtitle: '料理研究家佐藤 • 12:45',
      type: 'レシピ',
      icon: Icons.restaurant,
      iconColor: const Color(0xFFFF6B6B),
      timeAgo: '4時間前',
    ),
    ContentData(
      title: 'Apex Legends ランクマッチ配信',
      subtitle: 'ゲーム実況者山田 • ライブ',
      type: 'ライブ',
      icon: Icons.live_tv,
      iconColor: const Color(0xFF667EEA),
      timeAgo: '30分前',
    ),
    ContentData(
      title: '京都の隠れた名所巡り',
      subtitle: '旅行ブロガー鈴木 • 18:20',
      type: '動画',
      icon: Icons.place,
      iconColor: const Color(0xFF74B9FF),
      timeAgo: '1日前',
    ),
    ContentData(
      title: '秋冬コーディネート特集',
      subtitle: 'ファッション系インフルエンサー • 15:10',
      type: '動画',
      icon: Icons.checkroom,
      iconColor: const Color(0xFFE17055),
      timeAgo: '1日前',
    ),
    ContentData(
      title: 'Flutter開発のベストプラクティス',
      subtitle: 'プログラミング講師伊藤 • 32:15',
      type: 'チュートリアル',
      icon: Icons.code,
      iconColor: const Color(0xFF00B894),
      timeAgo: '2日前',
    ),
    ContentData(
      title: '自宅でできる筋トレメニュー',
      subtitle: 'フィットネストレーナー渡辺 • 20:30',
      type: '動画',
      icon: Icons.fitness_center,
      iconColor: const Color(0xFFE84393),
      timeAgo: '2日前',
    ),
    ContentData(
      title: '投資初心者のための株式投資講座',
      subtitle: 'ビジネス系YouTuber中村 • 28:45',
      type: '動画',
      icon: Icons.trending_up,
      iconColor: const Color(0xFF6C5CE7),
      timeAgo: '3日前',
    ),
    ContentData(
      title: '鬼滅の刃 最新話レビュー',
      subtitle: 'アニメレビュアー小林 • 16:20',
      type: '動画',
      icon: Icons.movie,
      iconColor: const Color(0xFFFF7675),
      timeAgo: '3日前',
    ),
    ContentData(
      title: 'DIY本棚の作り方',
      subtitle: 'DIYクリエイター木村 • 22:10',
      type: 'チュートリアル',
      icon: Icons.build,
      iconColor: const Color(0xFF00B894),
      timeAgo: '4日前',
    ),
    ContentData(
      title: 'Lo-Fi Hip Hop ビートメイキング',
      subtitle: '音楽プロデューサー松本 • 35:40',
      type: '音楽',
      icon: Icons.music_note,
      iconColor: const Color(0xFFFFD93D),
      timeAgo: '4日前',
    ),
    ContentData(
      title: '猫の健康管理のコツ',
      subtitle: 'ペット系YouTuber佐々木 • 14:30',
      type: '動画',
      icon: Icons.pets,
      iconColor: const Color(0xFF74B9FF),
      timeAgo: '5日前',
    ),
    ContentData(
      title: '英語リスニング上達法',
      subtitle: '語学学習コーチ田村 • 19:15',
      type: '教育',
      icon: Icons.school,
      iconColor: const Color(0xFF55A3FF),
      timeAgo: '5日前',
    ),
    ContentData(
      title: 'MacBook Pro M3 開封レビュー',
      subtitle: 'テックレビューアー田中 • 21:30',
      type: '動画',
      icon: Icons.laptop_mac,
      iconColor: const Color(0xFF4ECDC4),
      timeAgo: '6日前',
    ),
  ];

  // 追加のテストデータ
  final List<Map<String, dynamic>> trendingTopics = [
    {
      'title': 'iPhone 15',
      'color': const Color(0xFF4ECDC4),
    },
    {
      'title': 'Flutter 3.0',
      'color': const Color(0xFF00B894),
    },
    {
      'title': '秋のファッション',
      'color': const Color(0xFFE17055),
    },
    {
      'title': 'Apex Legends',
      'color': const Color(0xFF667EEA),
    },
    {
      'title': 'ChatGPT',
      'color': const Color(0xFF6C5CE7),
    },
    {
      'title': '鬼滅の刃',
      'color': const Color(0xFFFF7675),
    },
    {
      'title': 'DIY',
      'color': const Color(0xFF00B894),
    },
    {
      'title': '投資',
      'color': const Color(0xFFFFD93D),
    },
  ];

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'テックレビューアー田中が新しい動画を投稿しました',
      'time': '5分前',
      'type': 'new_post',
      'read': false,
    },
    {
      'title': 'ゲーム実況者山田がライブ配信を開始しました',
      'time': '30分前',
      'type': 'live',
      'read': false,
    },
    {
      'title': '料理研究家佐藤があなたの投稿にいいねしました',
      'time': '2時間前',
      'type': 'like',
      'read': false,
    },
    {
      'title': 'ビジネス系YouTuber中村が新しい投資動画を投稿',
      'time': '3時間前',
      'type': 'new_post',
      'read': true,
    },
    {
      'title': 'フィットネストレーナー渡辺があなたをフォローしました',
      'time': '5時間前',
      'type': 'follow',
      'read': true,
    },
    {
      'title': 'アニメレビュアー小林があなたのコメントに返信しました',
      'time': '1日前',
      'type': 'reply',
      'read': true,
    },
    {
      'title': 'DIYクリエイター木村が新しいチュートリアルを投稿',
      'time': '1日前',
      'type': 'new_post',
      'read': true,
    },
    {
      'title': '音楽プロデューサー松本があなたの楽曲をシェアしました',
      'time': '2日前',
      'type': 'share',
      'read': true,
    },
  ];

  // 新しいセクション用データ
  final List<Map<String, dynamic>> featuredPlaylists = [
    {
      'title': '今週のトップ動画',
      'description': '最も人気の高い動画をまとめました',
      'itemCount': 12,
      'thumbnail': const Color(0xFF4ECDC4),
      'creator': 'Starlist編集部',
    },
    {
      'title': 'プログラミング学習',
      'description': '初心者から上級者まで対応',
      'itemCount': 8,
      'thumbnail': const Color(0xFF00B894),
      'creator': 'プログラミング講師伊藤',
    },
    {
      'title': '料理レシピ集',
      'description': '簡単で美味しいレシピばかり',
      'itemCount': 15,
      'thumbnail': const Color(0xFFFF6B6B),
      'creator': '料理研究家佐藤',
    },
    {
      'title': 'ゲーム攻略',
      'description': '最新ゲームの攻略法',
      'itemCount': 20,
      'thumbnail': const Color(0xFF667EEA),
      'creator': 'ゲーム実況者山田',
    },
  ];

  final List<Map<String, dynamic>> liveStreams = [
    {
      'title': 'Apex Legends ランクマッチ',
      'streamer': 'ゲーム実況者山田',
      'viewers': '2,341',
      'category': 'ゲーム',
      'thumbnail': const Color(0xFF667EEA),
    },
    {
      'title': 'リアルタイム料理配信',
      'streamer': '料理研究家佐藤',
      'viewers': '1,567',
      'category': '料理',
      'thumbnail': const Color(0xFFFF6B6B),
    },
    {
      'title': 'プログラミング質問会',
      'streamer': 'プログラミング講師伊藤',
      'viewers': '892',
      'category': '教育',
      'thumbnail': const Color(0xFF00B894),
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    final currentUser = ref.watch(currentUserProvider);

    // ログイン状態をチェック（ルーターが遷移を管理するため、ここでは画面遷移しない）
    if (currentUser.id.isEmpty) {
      if (!_isRedirectingToLogin) {
        _isRedirectingToLogin = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/login');
        });
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(selectedTab),
      bottomNavigationBar:
          currentUser.isStar ? _buildBottomNavigationBar(selectedTab) : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TestAccountSwitcherScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4ECDC4),
        child: const Icon(Icons.swap_horiz, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final selectedTab = ref.watch(selectedTabProvider);
    final themeState = ref.watch(themeProviderEnhanced);
    final titles = ['ホーム', 'マイリスト', 'データ取込み', 'マイデータ', 'マイページ'];
    final isDark = themeState.isDarkMode;

    String title = titles[selectedTab];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: Icon(Icons.menu,
                color: isDark ? Colors.white54 : Colors.black54),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      automaticallyImplyLeading: false, // 戻るボタンを無効化
      actions: [
        IconButton(
          icon: const Icon(Icons.casino, color: Colors.amber),
          tooltip: 'ガチャ',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const GachaScreen()),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          tooltip: '通知',
          onPressed: () {},
        ),
      ],
    );
  }


  Drawer _buildDrawer() {
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
                      color: Colors.white.withOpacity(0.2),
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
                _buildDrawerItem(Icons.home, 'ホーム', 0, null),
                _buildDrawerItem(Icons.search, '検索', -1, 'search'),
                _buildDrawerItem(Icons.star, 'マイリスト', 1, null),
                if (currentUser.isStar) ...[
                  _buildDrawerItem(Icons.camera_alt, 'データ取込み', 2, null),
                  _buildDrawerItem(Icons.analytics, 'ダッシュボード', -1, 'dashboard'),
                ],
                _buildDrawerItem(Icons.person, 'マイページ', 4, null),
                if (currentUser.isFan) ...[
                  _buildDrawerItem(Icons.credit_card, '課金プラン', -1, 'subscription'),
                  _buildDrawerItem(Icons.stars, 'スターポイント購入', -1, 'buy_points'),
                ],
                _buildDrawerItem(Icons.settings, '設定', -1, 'settings'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                  child: Text(
                    'クイック操作',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: isDark,
                  onChanged: (_) {
                    ref.read(themeProviderEnhanced.notifier).toggleLightDark();
                  },
                  dense: true,
                  activeColor: const Color(0xFF4ECDC4),
                  title: const Text('ダークモード'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.login),
                  title: const Text('ログイン状態'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginStatusScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int tabIndex, String? pageKey) {
    final selectedTab = ref.watch(selectedTabProvider);
    final selectedDrawerPage = ref.watch(selectedDrawerPageProvider);
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;

    final isTabActive = tabIndex != -1 && selectedTab == tabIndex && selectedDrawerPage == null;
    final isPageActive = pageKey != null && selectedDrawerPage == pageKey;
    final isActive = isTabActive || isPageActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive ? const Color(0xFF4ECDC4).withOpacity(0.15) : null,
        border: isActive
            ? Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1,
              )
            : null,
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
        trailing: isActive
            ? const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF4ECDC4),
                size: 14,
              )
            : null,
        onTap: () {
          Navigator.of(context).pop();
          if (tabIndex != -1) {
            ref.read(selectedTabProvider.notifier).state = tabIndex;
            ref.read(selectedDrawerPageProvider.notifier).state = null;
          } else if (pageKey != null) {
            ref.read(selectedDrawerPageProvider.notifier).state = pageKey;
            _navigateToPage(pageKey);
          }
        },
      ),
    );
  }

  void _navigateToPage(String pageKey) {
    final currentUser = ref.read(currentUserProvider);
    switch (pageKey) {
      case 'dashboard':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StarDashboardScreen()),
        );
        return;
      case 'subscription':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SubscriptionPlansScreen(),
          ),
        );
        return;
      case 'buy_points':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const StarPointsPurchaseScreen(),
          ),
        );
        return;
      case 'search':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        return;
      case 'settings':
        if (mounted) context.go('/settings');
        return;
      default:
        return;
    }
  }

  Widget _buildBody(int selectedTab) {
    final currentUser = ref.watch(currentUserProvider);
    switch (selectedTab) {
      case 0:
        return _buildHomeView();
      case 1:
        return const MylistScreen();
      case 2:
        return const DataImportScreen(showAppBar: false);
      case 3:
        return StarDataViewPageSimple(
          starId: currentUser.name,
          username: currentUser.name,
        );
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLatestYouTubeHistorySection(),
          const SizedBox(height: 16),
          _buildRecentPostsSection(),
          const SizedBox(height: 16),
          _buildPaidFollowContentSection(),
          const SizedBox(height: 16),
          _buildFollowingUsersRegistrationSection(),
          const SizedBox(height: 16),
          _buildNotificationsSection(),
          const SizedBox(height: 16),
          _buildNativeAd1(),
          const SizedBox(height: 16),
          _buildTrendingTopicsSection(),
          const SizedBox(height: 16),
          _buildFeaturedPlaylistsSection(),
          const SizedBox(height: 16),
          _buildNativeAd2(),
          const SizedBox(height: 16),
          _buildRecommendedStarsSection(),
          const SizedBox(height: 16),
          _buildNewStarsSection(),
          const SizedBox(height: 16),
          _buildTodayPickupSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLatestYouTubeHistorySection() {
    try {
      final themeState = ref.watch(themeProviderEnhanced);
      final isDark = themeState.isDarkMode;
      final youtubeHistoryGroups = ref.watch(groupedYoutubeHistoryProvider);
      final youtubePosts = ref.watch(youtubePostsProvider);

    // YouTube履歴とYouTube投稿の両方が空の場合は、デフォルトデータを表示
    if (youtubeHistoryGroups.isEmpty && youtubePosts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('最新YouTube履歴'),
          const SizedBox(height: 16),
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFF3F4F6)),
            ),
            child: Center(
              child: Text(
                'YouTube履歴データが取り込まれるとここに表示されます',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // YouTube投稿とYouTube履歴を組み合わせたリストを作成
    final combinedItems = <dynamic>[];

    // YouTube投稿を追加
    for (final post in youtubePosts) {
      combinedItems.add({'type': 'post', 'data': post});
    }

    // YouTube履歴を追加
    for (final group in youtubeHistoryGroups) {
      combinedItems.add({'type': 'history', 'data': group});
    }

    // 作成日時でソート（新しい順）
    combinedItems.sort((a, b) {
      DateTime aTime;
      DateTime bTime;

      if (a['type'] == 'post') {
        aTime = a['data'].createdAt;
      } else {
        final YouTubeHistoryGroup group = a['data'];
        aTime = group.importedAt;
      }

      if (b['type'] == 'post') {
        bTime = b['data'].createdAt;
      } else {
        final YouTubeHistoryGroup group = b['data'];
        bTime = group.importedAt;
      }

      return bTime.compareTo(aTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('最新YouTube履歴'),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: combinedItems.length,
            itemBuilder: (context, index) {
              final item = combinedItems[index];

              if (item['type'] == 'post') {
                // YouTube投稿の表示（PostCardを使用）
                final post = item['data'];
                return Container(
                  width: 340,
                  margin: const EdgeInsets.only(right: 16),
                  child: PostCard(
                    post: post,
                    isCompact: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(post: post),
                        ),
                      );
                    },
                  ),
                );
              } else {
                // YouTube履歴の表示
                final group = item['data'];
                return GestureDetector(
                  onTap: () {
                    // グループの詳細を表示するダイアログ
                    showDialog(
                      context: context,
                      builder: (context) =>
                          _buildGroupDetailDialog(context, group, isDark),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : Colors.black)
                              .withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFF3F4F6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ServiceIcons.buildIcon(
                                    serviceId: 'youtube',
                                    size: 24,
                                    isDark: false,
                                  ),
                                  if (group.itemCount > 1)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4ECDC4),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${group.itemCount}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.itemCount > 1
                                        ? '${group.itemCount}件の動画をインポート'
                                        : group.items.first.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    group.itemCount > 1
                                        ? _formatImportTime(group.importedAt)
                                        : group.items.first.channel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (group.itemCount > 1) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${group.items.map((e) => e.channel).toSet().length}チャンネル',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
    } catch (e, stackTrace) {
      debugPrint('[StarlistMainScreen] Error in _buildLatestYouTubeHistorySection: $e');
      debugPrintStack(stackTrace: stackTrace);
      final themeState = ref.watch(themeProviderEnhanced);
      final isDark = themeState.isDarkMode;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('最新YouTube履歴'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFF3F4F6)),
            ),
            child: Center(
              child: Text(
                'エラーが発生しました: ${e.toString()}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  String _formatImportTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildGroupDetailDialog(
      BuildContext context, YouTubeHistoryGroup group, bool isDark) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.video_library,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${group.itemCount}件の動画',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: group.items.length,
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ServiceIcons.buildIcon(
                            serviceId: 'youtube',
                            size: 20,
                            isDark: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.channel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              if (item.duration != null ||
                                  item.viewCount != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (item.duration != null) ...[
                                      Text(
                                        item.duration!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (item.viewCount != null)
                                      Text(
                                        '${item.viewCount}回視聴',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black38,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAd1() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apps,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'おすすめアプリ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PR',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'あなたの興味に合わせたアプリを発見',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '見る',
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
  }

  Widget _buildNativeAd2() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE66D), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'スポンサードコンテンツ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '新しいスターを発見して、特別なコンテンツを楽しもう',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '詳細',
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
  }

  Widget _buildNotificationsSection() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;

    final notifications = [
      {
        'type': 'upload',
        'title': '新しい動画がアップロードされました',
        'subtitle': 'テックレビューアー田中 • iPhone 15 Pro レビュー',
        'time': '2時間前',
        'isUnread': true,
        'icon': Icons.video_library,
        'iconColor': const Color(0xFF4ECDC4),
      },
      {
        'type': 'follow',
        'title': '新しいフォロワーがいます',
        'subtitle': '5人の新しいフォロワー',
        'time': '4時間前',
        'isUnread': true,
        'icon': Icons.person_add,
        'iconColor': const Color(0xFFFF6B6B),
      },
      {
        'type': 'live',
        'title': 'ライブ配信が開始されました',
        'subtitle': 'ゲーム実況者山田 • Apex Legends ランクマッチ',
        'time': '6時間前',
        'isUnread': false,
        'icon': Icons.live_tv,
        'iconColor': const Color(0xFFFFE66D),
      },
      {
        'type': 'comment',
        'title': 'コメントが投稿されました',
        'subtitle': '料理研究家佐藤の動画にコメント',
        'time': '8時間前',
        'isUnread': false,
        'icon': Icons.comment,
        'iconColor': const Color(0xFF8B5CF6),
      },
      {
        'type': 'like',
        'title': 'いいねがつきました',
        'subtitle': 'あなたの投稿に15件のいいね',
        'time': '12時間前',
        'isUnread': false,
        'icon': Icons.favorite,
        'iconColor': const Color(0xFFEF4444),
      },
      {
        'type': 'mention',
        'title': 'メンションされました',
        'subtitle': 'ビジネス系YouTuber中村があなたをメンション',
        'time': '1日前',
        'isUnread': true,
        'icon': Icons.alternate_email,
        'iconColor': const Color(0xFF06B6D4),
      },
      {
        'type': 'subscription',
        'title': 'サブスクリプションが更新されました',
        'subtitle': 'プレミアムプランが自動更新',
        'time': '2日前',
        'isUnread': false,
        'icon': Icons.star,
        'iconColor': const Color(0xFFF59E0B),
      },
      {
        'type': 'achievement',
        'title': '達成バッジを獲得しました',
        'subtitle': '100時間視聴バッジを獲得',
        'time': '3日前',
        'isUnread': false,
        'icon': Icons.emoji_events,
        'iconColor': const Color(0xFF10B981),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('通知'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = notification['isUnread'] as bool;

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnread
                        ? const Color(0xFF4ECDC4).withOpacity(0.3)
                        : (isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFF3F4F6)),
                    width: isUnread ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black)
                          .withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (notification['iconColor'] as Color)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        notification['icon'] as IconData,
                        color: notification['iconColor'] as Color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            notification['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isUnread
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.grey[700]),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification['time'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ECDC4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('トレンドトピック'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: trendingTopics.length,
            itemBuilder: (context, index) {
              final topic = trendingTopics[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      topic['color'],
                      topic['color'].withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: topic['color'].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPlaylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('プレイリスト'),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: featuredPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = featuredPlaylists[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      playlist['thumbnail'],
                      playlist['thumbnail'].withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: playlist['thumbnail'].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      playlist['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playlist['description'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedStarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('おすすめスター'),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: recommendedStars.length,
            itemBuilder: (context, index) {
              final star = recommendedStars[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                child: _buildStarCard(star, 180),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewStarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('新しく参加したスター'),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: newStars.length,
            itemBuilder: (context, index) {
              final star = newStars[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                child: _buildStarCard(star, 180),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStarCard(StarData star, double height) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: star.gradientColors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                star.avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  star.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  star.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${star.followers}フォロワー',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  star.isFollowing ? Colors.grey : star.gradientColors.first,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              minimumSize: const Size(50, 28),
            ),
            child: Text(
              star.isFollowing ? 'フォロー中' : 'フォロー',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPickupSection() {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;

    final todayPickup = [
      {
        'title': '今日のおすすめスター',
        'subtitle': 'テックレビューアー田中',
        'description': '最新のガジェットレビューが人気',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.star,
      },
      {
        'title': '注目のコンテンツ',
        'subtitle': 'iPhone 15 Pro Max レビュー',
        'description': '詳細なカメラ性能テスト',
        'color': const Color(0xFF10B981),
        'icon': Icons.video_library,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日のピックアップ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...todayPickup.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black)
                        .withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 16,
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBottomNavigationBar(int selectedTab) {
    final themeState = ref.watch(themeProviderEnhanced);
    final isDark = themeState.isDarkMode;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(Icons.home, 'ホーム', 0, selectedTab, isDark),
              _buildBottomNavItem(
                  Icons.star, 'マイリスト', 1, selectedTab, isDark),
              _buildBottomNavItem(
                  Icons.camera_alt, 'データ取込み', 2, selectedTab, isDark),
              _buildBottomNavItem(
                  Icons.analytics, 'マイデータ', 3, selectedTab, isDark),
              _buildBottomNavItem(
                  Icons.person, 'マイページ', 4, selectedTab, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, int index, int selectedTab, bool isDark) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedTabProvider.notifier).state = index;
          ref.read(selectedDrawerPageProvider.notifier).state =
              null; // ドロワー選択をリセット
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF4ECDC4)
                    : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4ECDC4)
                      : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPostsSection() {
    final allPosts = ref.watch(accessiblePostsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = ref.watch(themeProviderEnhanced).isDarkMode;

    final recentPosts = allPosts
        .where((post) => post.type != PostType.youtube)
        .take(6)
        .toList();
    final otherPosts = _mockOtherPosts().take(6).toList();

    if (recentPosts.isEmpty && otherPosts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('新着投稿'),
          const SizedBox(height: 12),
          _buildMutedInfoCard('まだ投稿がありません。'),
        ],
      );
    }

    final cards = <Widget>[
      ...recentPosts.map(
        (post) => SizedBox(
          width: 280,
          child: PostCard(
            post: post,
            isCompact: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            },
          ),
        ),
      ),
      ...otherPosts.map(
        (data) => _buildSummaryContentCard(
          data,
          isDark,
          currentUser.fanPlanType == FanPlanType.free,
          width: 260,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('新着投稿'),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => cards[index],
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPaidFollowContentSection() {
    final posts = ref.watch(hanayamaMizukiPostsProvider);
    final currentUser = ref.watch(currentUserProvider);

    final paidPosts = posts.where((post) {
      if (post.accessLevel == AccessLevel.public) {
        return false;
      }
      final contentType = _mapAccessLevelToContentType(post.accessLevel);
      return AccessControlService.canViewContent(
        currentUser.fanPlanType,
        contentType,
      );
    }).toList();
    final displayPaidPosts = paidPosts.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('有料フォローしている内容'),
        const SizedBox(height: 12),
        if (displayPaidPosts.isEmpty)
          _buildMutedInfoCard('現在アクセス可能な有料コンテンツはありません。')
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: displayPaidPosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final post = displayPaidPosts[index];
                return SizedBox(
                  width: 280,
                  child: PostCard(
                    post: post,
                    isCompact: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(post: post),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFollowingUsersRegistrationSection() {
    final registrations = _mockFollowingRegistrations();
    final currentUser = ref.watch(currentUserProvider);
    final isDark = ref.watch(themeProviderEnhanced).isDarkMode;
    final isFreePlan = currentUser.fanPlanType == FanPlanType.free;

    final displayRegistrations = registrations.take(6).toList();

    if (displayRegistrations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('フォローユーザーの登録内容'),
          const SizedBox(height: 12),
          _buildMutedInfoCard('フォロー中のユーザーによる新規登録はまだありません。'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('フォローユーザーの登録内容'),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _buildFollowingRegistrationCard(
              displayRegistrations[index],
              isDark,
              isFreePlan,
              width: 260,
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: displayRegistrations.length,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContentCard(
    Map<String, dynamic> post,
    bool isDark,
    bool isFreePlan, {
    double width = 260,
  }) {
    final restricted = isFreePlan &&
        (post['accessLevel'] as AccessLevel) != AccessLevel.public;

    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F23) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black12).withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: post['color'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    post['icon'] as IconData,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restricted)
                            Icon(Icons.lock_outline,
                                size: 16,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF475569)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['author'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post['summary'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  post['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  (post['accessLevel'] as AccessLevel).displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: restricted
                        ? (isDark ? Colors.redAccent : const Color(0xFFDC2626))
                        : (isDark ? Colors.white70 : const Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingRegistrationCard(
    Map<String, dynamic> item,
    bool isDark,
    bool isFreePlan, {
    double width = 260,
  }) {
    final restricted = isFreePlan &&
        (item['accessLevel'] as AccessLevel) != AccessLevel.public;

    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F23) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black12).withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: item['color'] as Color,
              child: Text(
                (item['initial'] as String?) ??
                    (item['starName'] as String).substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['starName'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item['isNew'] as bool)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF159F91),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['summary'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['time'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (item['accessLevel'] as AccessLevel).displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: restricted
                              ? (isDark
                                  ? Colors.redAccent
                                  : const Color(0xFFDC2626))
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF0F766E)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutedInfoCard(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _mockOtherPosts() {
    return [
      {
        'title': 'iPhone 15 Pro Max レビュー',
        'author': 'テックレビューアー田中',
        'summary': '最新機能とカメラ性能を徹底チェック。',
        'time': '2時間前',
        'icon': Icons.devices,
        'color': const Color(0xFF4ECDC4),
        'accessLevel': AccessLevel.light,
      },
      {
        'title': '簡単チキンカレーの作り方',
        'author': '料理研究家佐藤',
        'summary': '15分でできるスパイシーな本格カレー。',
        'time': '4時間前',
        'icon': Icons.restaurant,
        'color': const Color(0xFFFF6B6B),
        'accessLevel': AccessLevel.light,
      },
      {
        'title': 'Flutter開発のコツ',
        'author': 'プログラミング講師伊藤',
        'summary': '状態管理とテストのベストプラクティスを紹介。',
        'time': '6時間前',
        'icon': Icons.code,
        'color': const Color(0xFF00B894),
        'accessLevel': AccessLevel.standard,
      },
      {
        'title': '週末リフレッシュ術',
        'author': 'ライフスタイルコーチ高橋',
        'summary': '心と体を整えるセルフケアの習慣。',
        'time': '8時間前',
        'icon': Icons.self_improvement,
        'color': const Color(0xFF6366F1),
        'accessLevel': AccessLevel.public,
      },
    ];
  }

  List<Map<String, dynamic>> _mockFollowingRegistrations() {
    return [
      {
        'starName': '花山瑞樹',
        'initial': '花',
        'category': '日常Blog・ファッション',
        'summary': '朝のルーティン動画とコスメレビューを公開。',
        'time': '30分前',
        'isNew': true,
        'accessLevel': AccessLevel.light,
        'color': const Color(0xFFFFB6C1),
      },
      {
        'starName': 'テックレビューアー田中',
        'initial': 'テ',
        'category': 'テクノロジー',
        'summary': '最新スマートウォッチの比較レビューを投稿。',
        'time': '2時間前',
        'isNew': false,
        'accessLevel': AccessLevel.standard,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'starName': '料理研究家佐藤',
        'initial': '料',
        'category': 'グルメ',
        'summary': '春野菜を使ったレシピコレクションを追加。',
        'time': '5時間前',
        'isNew': true,
        'accessLevel': AccessLevel.light,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'starName': '旅写真家中村',
        'initial': '旅',
        'category': '旅行・写真',
        'summary': '北海道の絶景スポットをフォトログで公開。',
        'time': '昨日',
        'isNew': false,
        'accessLevel': AccessLevel.public,
        'color': const Color(0xFF74B9FF),
      },
    ];
  }

  ContentType _mapAccessLevelToContentType(AccessLevel level) {
    switch (level) {
      case AccessLevel.public:
        return ContentType.basicProfile;
      case AccessLevel.light:
        return ContentType.purchaseHistory;
      case AccessLevel.standard:
        return ContentType.activities;
      case AccessLevel.premium:
        return ContentType.premiumContent;
    }
  }

  Widget _buildSectionTitle(String title) {
    final themeState = ref.watch(themeProviderEnhanced);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeState.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'すべて見る',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
