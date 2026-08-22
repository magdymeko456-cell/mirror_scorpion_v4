import 'package:flutter/material.dart';

import '../feature_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  static const _features = <_FeatureSpec>[
    _FeatureSpec(FeatureKind.translation, 'ترجمة نصية', '100 لغة + مايك', Icons.translate, Colors.blueAccent),
    _FeatureSpec(FeatureKind.dialogue, 'حوار مترجم', 'محادثة ثنائية فورية', Icons.forum, Colors.cyanAccent),
    _FeatureSpec(FeatureKind.documents, 'مستندات وعدسة', 'ترجمة صور وملفات', Icons.document_scanner, Colors.tealAccent),
    _FeatureSpec(FeatureKind.stories, 'قصص وإلهام', 'مكتبة ذكية متكاملة', Icons.auto_stories, Colors.orangeAccent),
    _FeatureSpec(FeatureKind.games, 'ألعاب 3D', 'شطرنج + روبيك', Icons.sports_esports, Colors.purpleAccent),
    _FeatureSpec(FeatureKind.settings, 'الإعدادات', 'تخصيص وترقية برو', Icons.settings, Colors.blueGrey),
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _bubbleRequested = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleBubble(bool requested) {
    setState(() => _bubbleRequested = requested);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requested
              ? 'سيطلب التطبيق إذن الظهور فوق التطبيقات عند اكتمال خدمة Android الأصلية.'
              : 'تم إيقاف طلب الفقاعة العائمة.',
        ),
      ),
    );
  }

  void _showInspirationPreview() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: const Text('إلهام ميرور سكربيون', style: TextStyle(color: Colors.amber, fontSize: 18)),
        content: const Text('تُربط رسالة الإلهام بخدمة ذكاء حقيقية بعد تثبيت مسارها الخادمي؛ لا يولّد التطبيق رسالة افتراضية هنا.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسناً'))],
      ),
    );
  }

  void _openFeature(FeatureKind kind) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FeatureHubScreen(kind: kind)));
  }

  void _showGamesSelection() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر اللعبة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.grid_view, color: Colors.purpleAccent, size: 32),
                title: const Text('مكعب روبيك 3D'),
                subtitle: const Text('جميع طرق الحل', style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openFeature(FeatureKind.games);
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.castle, color: Colors.purpleAccent, size: 32),
                title: const Text('شطرنج 3D'),
                subtitle: const Text('لعبة شطرنج ثلاثية الأبعاد', style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openFeature(FeatureKind.games);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FeatureCard(
                        feature: _features[index],
                        onTap: _features[index].kind == FeatureKind.games ? _showGamesSelection : () => _openFeature(_features[index].kind),
                      ),
                      childCount: _features.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _Footer()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: 0.25,
                child: Transform.translate(
                  offset: const Offset(0, 110),
                  child: Transform.scale(
                    scaleX: 1.2,
                    scaleY: -1.0,
                    child: Transform(
                      transform: Matrix4.rotationX(1.4),
                      alignment: Alignment.center,
                      child: _buildScorpionLogo(isReflection: true),
                    ),
                  ),
                ),
              ),
              GestureDetector(onTap: _showInspirationPreview, child: _buildScorpionLogo()),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'ميرور سكربيون',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF00B0FF),
              shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10), Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          const Text('حيث تُصنع البدايات', style: TextStyle(fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _bubbleRequested ? Colors.blueAccent : Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_bubbleRequested ? Icons.bubble_chart : Icons.bubble_chart_outlined, color: _bubbleRequested ? Colors.blueAccent : Colors.grey),
                const SizedBox(width: 12),
                Text(_bubbleRequested ? 'طلب الفقاعة نشط' : 'تفعيل الفقاعة العائمة', style: TextStyle(color: _bubbleRequested ? Colors.blueAccent : Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Switch(value: _bubbleRequested, onChanged: _toggleBubble, activeThumbColor: Colors.blueAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorpionLogo({bool isReflection = false}) {
    final logo = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.withValues(alpha: isReflection ? 0.2 : 0.5), width: 2),
        boxShadow: isReflection ? null : [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2)],
        image: const DecorationImage(image: AssetImage('assets/images/scorpion_bg.jpeg'), fit: BoxFit.cover),
      ),
    );
    if (isReflection) return logo;
    return AnimatedBuilder(animation: _pulseAnimation, child: logo, builder: (_, child) => Transform.scale(scale: _pulseAnimation.value, child: child));
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final _FeatureSpec feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: feature.color.withValues(alpha: 0.35))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature.icon, color: feature.color, size: 42),
              const SizedBox(height: 14),
              Text(feature.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(feature.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Opacity(opacity: 0.3, child: Center(child: Text('Mirror Scorpion\nv4 Flutter Foundation', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)))),
    );
  }
}

class _FeatureSpec {
  const _FeatureSpec(this.kind, this.title, this.subtitle, this.icon, this.color);

  final FeatureKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
