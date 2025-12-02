import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:starlist_app/services/image_url_builder.dart';

import '../widgets/media_gate.dart';
import '../utils/visibility_rules.dart';
import '../src/features/star_data/presentation/star_data_paywall_dialog.dart';

const bool kUsePixelationMask = false;

class StarDataPage extends StatefulWidget {
  const StarDataPage({super.key});

  @override
  State<StarDataPage> createState() => _StarDataPageState();
}

class _StarDataPageState extends State<StarDataPage> {
  String viewMode = 'fan';
  String fanTier = 'free';
  String query = '';
  final Set<String> selectedCats = <String>{};
  bool matchAllCats = false;
  String dateRange = 'all'; // all|7d|30d

  late final List<Post> data;
  final now = DateTime(2025, 10, 2);

  @override
  void initState() {
    super.initState();
    data = sampleData();
  }

  bool _dateKeep(DateTime d) {
    if (dateRange == 'all') return true;
    final diff = now.difference(d).inDays;
    return dateRange == '7d' ? diff <= 7 : diff <= 30;
  }

  bool _matchesQuery(Post p) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    final inPost = p.postTitle.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q);
    final inItems = p.items.any((it) => [it.title, it.channel, it.artist]
        .whereType<String>()
        .any((t) => t.toLowerCase().contains(q)));
    return inPost || inItems;
  }

  @override
  Widget build(BuildContext context) {
    final pre =
        data.where((p) => _matchesQuery(p) && _dateKeep(p.date)).toList();

    final counts = <String, int>{};
    for (final p in pre) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }

    final filtered = selectedCats.isEmpty
        ? pre
        : pre.where((p) {
            if (matchAllCats) {
              return selectedCats.length == 1 &&
                  selectedCats.contains(p.category);
            }
            return selectedCats.contains(p.category);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title:
            const Text('スターリスト', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              isSelected: [viewMode == 'fan', viewMode == 'star'],
              onPressed: (i) =>
                  setState(() => viewMode = i == 0 ? 'fan' : 'star'),
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('ファン視点')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('スター視点')),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '検索: タイトル / アイテム名 / チャンネル',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RangeDropdown(
                      value: dateRange,
                      onChanged: (v) => setState(() => dateRange = v),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('全て  ${pre.length}',
                              style: const TextStyle(fontSize: 12)),
                          selected: selectedCats.isEmpty,
                          onSelected: (_) => setState(selectedCats.clear),
                        ),
                      ),
                      ..._cats.where((c) => c.id != 'all').map((c) {
                        final sel = selectedCats.contains(c.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('${c.name}  ${(counts[c.id] ?? 0)}',
                                style: const TextStyle(fontSize: 12)),
                            selected: sel,
                            onSelected: (_) => setState(() {
                              sel
                                  ? selectedCats.remove(c.id)
                                  : selectedCats.add(c.id);
                            }),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Row(children: [
                          const Text('ALL一致', style: TextStyle(fontSize: 12)),
                          Switch(
                            value: matchAllCats,
                            onChanged: (v) => setState(() => matchAllCats = v),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  if (viewMode == 'fan')
                    Row(children: [
                      const Text('プラン:',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(width: 6),
                      Wrap(spacing: 6, children: [
                        _planBtn('無料', 'free'),
                        _planBtn('ライト', 'light'),
                        _planBtn('スタンダード', 'standard'),
                        _planBtn('プレミアム', 'premium'),
                      ]),
                      const Spacer(),
                      Text('${filtered.length} 件',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ]),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final post = filtered[i];
                final canViewPostResult = canViewPost(
                  viewMode: viewMode,
                  category: post.category,
                  fanTier: fanTier,
                  postVisibility: post.visibility,
                );

                final bool fullAccess = viewMode == 'star' ||
                    post.category == 'youtube' ||
                    canViewPostResult;
                final plan = _buildVisibilityPlan(
                  post: post,
                  fullAccess: fullAccess,
                  canViewPostResult: canViewPostResult,
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        _PostHeader(post: post),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(builder: (context, c) {
                            final cross = _gridCrossAxisCount(c.maxWidth);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: post.items.length,
                              itemBuilder: (context, idx) {
                                final it = post.items[idx];
                                final isVisible =
                                    plan.visibleIds.contains(it.id);
                                return _ItemCard(
                                  item: it,
                                  isVisible: isVisible,
                                  isPeek: !plan.fullAccess && isVisible,
                                );
                              },
                            );
                          }),
                        ),
                        if (!plan.fullAccess && plan.hiddenCount > 0)
                          _TeaserBanner(
                            hiddenCount: plan.hiddenCount,
                            bestHidden: plan.bestHiddenCount,
                            badgeText: _badgeText(post.visibility),
                          ),
                        if (plan.fullAccess && post.starComment.isNotEmpty)
                          _StarComment(text: post.starComment),
                        _ActionBar(
                          likes: post.likes,
                          comments: post.comments,
                          ctaLabel: plan.fullAccess
                              ? (viewMode == 'star' ? 'もっと見る' : '詳細を見る')
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planBtn(String label, String value) {
    final selected = fanTier == value;
    return OutlinedButton(
      onPressed: () => setState(() => fanTier = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.purple : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        side: BorderSide(color: selected ? Colors.purple : Colors.black26),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  _PostVisibilityPlan _buildVisibilityPlan({
    required Post post,
    required bool fullAccess,
    required bool canViewPostResult,
  }) {
    if (fullAccess) {
      final visibleIds = post.items.map((it) => it.id).toSet();
      final hiddenCount = math.max(0, post.totalItems - visibleIds.length);
      return _PostVisibilityPlan(
        fullAccess: true,
        visibleIds: visibleIds,
        hiddenCount: hiddenCount,
        bestHiddenCount: 0,
      );
    }

    final flaggedVisible = post.items.where((it) => it.visible).length;
    final peekLimit = peekLimitFor(
      totalItems: post.totalItems,
      flaggedVisible: flaggedVisible,
    );

    int peekUsed = 0;
    final visibleIds = <int>{};

    for (final item in post.items) {
      final allow = canViewItem(
        itemVisible: item.visible,
        canViewPostResult: canViewPostResult,
        totalVisibleItems: peekUsed,
        peekLimit: peekLimit,
      );
      if (allow) {
        if (item.visible && peekUsed < peekLimit) {
          peekUsed++;
        }
        visibleIds.add(item.id);
      }
    }

    final hiddenCount = math.max(0, post.totalItems - visibleIds.length);
    final bestHidden = post.items
        .where((it) => it.isBest && !visibleIds.contains(it.id))
        .length;

    return _PostVisibilityPlan(
      fullAccess: false,
      visibleIds: visibleIds,
      hiddenCount: hiddenCount,
      bestHiddenCount: bestHidden,
    );
  }
}

// ---- Widgets / Models ----

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final badge = _badge(post.visibility);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4EBFF), Color(0xFFEAF2FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
      ),
      child: Row(
        children: [
          Icon(_catIcon(post.category), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.postTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${post.totalItems}件',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Text('${_fmt(post.date)} ${post.time}',
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: badge.color, borderRadius: BorderRadius.circular(999)),
            child: Text(badge.text,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          if (post.category == 'youtube') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF0000), // YouTube Red
                  borderRadius: BorderRadius.circular(999)),
              child: const Text('YouTube',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(
      {required this.item, required this.isVisible, required this.isPeek});
  final Item item;
  final bool isVisible;
  final bool isPeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticsLabel = isVisible ? item.title : '非公開アイテム';
    final semanticsHint = isVisible ? null : 'アップグレードで閲覧可能です';

    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      readOnly: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                    child: MediaGate(
                      child: CachedNetworkImage(
                        imageUrl: ImageUrlBuilder.thumbnail(
                          item.thumbnail,
                          width: 640,
                        ),
                        fit: BoxFit.cover,
                        memCacheHeight: 480,
                        fadeInDuration: const Duration(milliseconds: 120),
                        placeholder: (_, __) =>
                            Container(color: const Color(0xFFF3F4F6)),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  if (!isVisible) ...[
                    const Positioned.fill(child: _ObscuredLayer()),
                    Center(
                      child: Icon(Icons.lock_outline,
                          color: Colors.white.withOpacity(.95), size: 28),
                    ),
                  ],
                  if (item.isBest && isVisible)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('★ベスト',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  if (isPeek && !item.isBest)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('PREVIEW',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isVisible ? item.title : '非公開アイテム',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    if (isVisible && item.price != null)
                      Text(item.price!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold)),
                    if (isVisible && item.channel != null)
                      Text(item.channel!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (isVisible && item.artist != null)
                      Text(item.artist!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (isVisible && item.duration != null)
                      Text(item.duration!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObscuredLayer extends StatelessWidget {
  const _ObscuredLayer();

  @override
  Widget build(BuildContext context) {
    if (kUsePixelationMask) {
      return const _PixelatedOverlay();
    }
    return const _BlurOverlay();
  }
}

class _BlurOverlay extends StatelessWidget {
  const _BlurOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(decoration: BoxDecoration(color: Color(0x80FFFFFF))),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: SizedBox.expand(),
        ),
        CustomPaint(painter: _HatchPainter()),
      ],
    );
  }
}

class _PixelatedOverlay extends StatelessWidget {
  const _PixelatedOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelatedPainter(),
    );
  }
}

class _PixelatedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double block = 12;
    final base = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawRect(Offset.zero & size, base);

    final accent = Paint()..color = const Color(0x22000000);
    for (double y = 0; y < size.height; y += block) {
      for (double x = 0; x < size.width; x += block) {
        if (((x + y) / block).floor().isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, block, block), accent);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TeaserBanner extends StatelessWidget {
  const _TeaserBanner(
      {required this.hiddenCount,
      required this.bestHidden,
      required this.badgeText});
  final int hiddenCount;
  final int bestHidden;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF3CD), Color(0xFFFFE8A1)]),
        border: Border.all(color: const Color(0xFFF4C84D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF4C84D),
              borderRadius: BorderRadius.circular(999)),
          child: const Icon(Icons.auto_awesome, color: Color(0xFF7A5200)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '残り$hiddenCount件が非公開${bestHidden > 0 ? '（うち★ベスト $bestHidden件）' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('$badgeTextにアップグレードで見ることができます',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const PaywallPlansDialog(),
              );
            },
            icon: const Icon(Icons.lock),
            label: const Text('アップグレード')),
      ]),
    );
  }
}

class _StarComment extends StatelessWidget {
  const _StarComment({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDFF),
        border:
            Border(left: BorderSide(color: Colors.purple.shade400, width: 3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💬 スターのコメント',
            style: TextStyle(
                fontSize: 12,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(text),
      ]),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar(
      {required this.likes, required this.comments, this.ctaLabel});
  final int likes;
  final int comments;
  final String? ctaLabel;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE9E9E9)))),
      child: Row(children: [
        Row(children: [
          const Icon(Icons.favorite_border, size: 18, color: Colors.black54),
          const SizedBox(width: 4),
          Text('$likes'),
        ]),
        const SizedBox(width: 14),
        Row(children: [
          const Icon(Icons.mode_comment_outlined,
              size: 18, color: Colors.black54),
          const SizedBox(width: 4),
          Text('$comments'),
        ]),
        const Spacer(),
        if (ctaLabel != null)
          FilledButton(
              onPressed: () {
                if (!ctaLabel!.contains('もっと見る') && !ctaLabel!.contains('詳細')) {
                  // 通常の遷移
                } else {
                  // Paywall
                  showDialog(
                    context: context,
                    builder: (_) => const PaywallPlansDialog(),
                  );
                }
              },
              child: Text(ctaLabel!, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0x80FFFFFF);
    canvas.drawRect(Offset.zero & size, bg);
    final p1 = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.2;
    final p2 = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.2;

    const step = 8.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p1);
    }
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), p2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---- helpers / models ----
String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
IconData _catIcon(String c) => switch (c) {
      'youtube' => Icons.play_circle_filled, // Changed to resemble YouTube play button more
      'music' => Icons.music_note, // Explicitly music note
      'shopping' => Icons.shopping_bag,
      'books' => Icons.menu_book,
      'apps' => Icons.smartphone,
      'food' => Icons.restaurant,
      _ => Icons.trending_up,
    };
_Badge _badge(String v) => switch (v) {
      'light' => const _Badge('ライト+', Colors.blue),
      'standard' => const _Badge('スタンダード+', Colors.purple),
      'premium' => const _Badge('プレミアム限定', Color(0xFFFFC107)),
      _ => const _Badge('無料公開', Colors.grey),
    };
String _badgeText(String v) => _badge(v).text;

class _Badge {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
}

class Category {
  const Category(this.id, this.name);
  final String id;
  final String name;
}

const _cats = [
  Category('all', '全て'),
  Category('youtube', 'YouTube'),
  Category('music', '音楽'),
  Category('shopping', '買い物'),
  Category('books', '書籍'),
  Category('apps', 'アプリ'),
  Category('food', '食事'),
];

int _gridCrossAxisCount(double w) => w < 360
    ? 2
    : w < 540
        ? 3
        : w < 720
            ? 4
            : 5;

class _PostVisibilityPlan {
  const _PostVisibilityPlan({
    required this.fullAccess,
    required this.visibleIds,
    required this.hiddenCount,
    required this.bestHiddenCount,
  });

  final bool fullAccess;
  final Set<int> visibleIds;
  final int hiddenCount;
  final int bestHiddenCount;
}

// ---- Data
class Post {
  Post({
    required this.id,
    required this.category,
    required this.postTitle,
    required this.date,
    required this.time,
    required this.totalItems,
    required this.items,
    required this.visibility,
    required this.likes,
    required this.comments,
    required this.starComment,
  });
  final int id;
  final String category;
  final String postTitle;
  final DateTime date;
  final String time;
  final int totalItems;
  final List<Item> items;
  final String visibility;
  final int likes;
  final int comments;
  final String starComment;
}

class Item {
  Item({
    required this.id,
    required this.title,
    this.price,
    this.channel,
    this.artist,
    this.duration,
    required this.visible,
    required this.isBest,
    required this.thumbnail,
  });
  final int id;
  final String title;
  final String? price, channel, artist, duration;
  final bool visible, isBest;
  final String thumbnail;
}

List<Post> sampleData() => [
      Post(
        id: 1,
        category: 'food',
        postTitle: 'セブンイレブンで夜食購入',
        date: DateTime(2025, 10, 1),
        time: '22:30',
        totalItems: 5,
        items: [
          Item(
              id: 1,
              title: 'おにぎり ツナマヨ',
              price: '¥138',
              visible: true,
              isBest: false,
              thumbnail:
                  'https://img-afd.7api-01.dp1.sej.co.jp/item-image/047786/BC434201E3FE7C32240B5ABC20A6789A.jpg'),
          Item(
            id: 2,
            title: '金のハンバーグ',
            price: '¥598',
            visible: false,
            isBest: true,
            thumbnail:
                'https://www.7andi.com/var/rev0/0000/3115/11948162553.jpg',
          ),
          Item(
              id: 3,
              title: 'ななチキ',
              price: '¥238',
              visible: false,
              isBest: false,
              thumbnail:
                  'https://via.placeholder.com/80x80/ffcc00/ffffff?text=からあげ'),
          Item(
              id: 4,
              title: 'セブンカフェ アイスコーヒー L',
              price: '¥150',
              visible: false,
              isBest: true,
              thumbnail:
                  'https://img-afd.7api-01.dp1.sej.co.jp/item-image/140472/EB6F99982458E96014BBE654173C4A62.jpg'),
          Item(
              id: 5,
              title: 'ポテトチップス うすしお',
              price: '¥128',
              visible: false,
              isBest: false,
              thumbnail:
                  'https://www.calbee.co.jp/common/utility/binout.php?db=products&f=5221'),
        ],
        visibility: 'premium',
        likes: 432,
        comments: 78,
        starComment: '編集作業のお供に！',
      ),
      Post(
        id: 2,
        category: 'youtube',
        postTitle: '今日観たゲーム実況動画',
        date: DateTime(2025, 10, 1),
        time: '18:45',
        totalItems: 8,
        items: [
          Item(
            id: 1,
            title: '【マイクラ】最新アップデート解説',
            channel: 'GameChannel A',
            duration: '24:15',
            visible: true,
            isBest: false,
            thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          ),
          Item(
            id: 2,
            title: '【モンハン】神プレイ集',
            channel: 'HunterPro',
            duration: '15:42',
            visible: true,
            isBest: true,
            thumbnail: 'https://img.youtube.com/vi/6_b7RDuLwcI/hqdefault.jpg',
          ),
          Item(
            id: 3,
            title: 'ポケモン対戦環境解説',
            channel: 'PokeMaster',
            duration: '18:30',
            visible: true,
            isBest: false,
            thumbnail: 'https://img.youtube.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
          ),
          Item(
            id: 4,
            title: 'FPS上達テクニック',
            channel: 'FPS_God',
            duration: '20:05',
            visible: true,
            isBest: true,
            thumbnail: 'https://img.youtube.com/vi/9bZkp7q19f0/hqdefault.jpg',
          ),
          Item(
            id: 5,
            title: 'ホラーゲーム実況',
            channel: 'ScaryGamer',
            duration: '45:20',
            visible: true,
            isBest: false,
            thumbnail: 'https://img.youtube.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
          ),
          Item(
            id: 6,
            title: 'レトロゲーム特集',
            channel: 'RetroGame',
            duration: '32:10',
            visible: true,
            isBest: true,
            thumbnail: 'https://img.youtube.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
          ),
          Item(
            id: 7,
            title: '最新ゲームニュース',
            channel: 'GameNews',
            duration: '12:30',
            visible: true,
            isBest: false,
            thumbnail: 'https://img.youtube.com/vi/L_jWHffIx5E/hqdefault.jpg',
          ),
          Item(
            id: 8,
            title: 'ゲーム音楽メドレー',
            channel: 'MusicGame',
            duration: '60:00',
            visible: true,
            isBest: false,
            thumbnail: 'https://img.youtube.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
          ),
        ],
        visibility: 'standard',
        likes: 567,
        comments: 123,
        starComment: 'モンハンとFPSの動画が特に参考になりました！',
      ),
    ];
