import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  runApp(ProfileApp(themeController: themeController));
}

class ThemeController extends ChangeNotifier {
  static const _key = 'isDarkMode';
  bool _isDark = false;

  bool get isDark => _isDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}

class ProfileApp extends StatefulWidget {
  final ThemeController themeController;
  const ProfileApp({super.key, required this.themeController});

  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6750A4);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Profile',
      themeMode: widget.themeController.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
      ),
      home: HomePage(themeController: widget.themeController),
    );
  }
}

class HomePage extends StatelessWidget {
  final ThemeController themeController;
  const HomePage({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          Row(
            children: [
              const Icon(Icons.light_mode),
              Switch(
                value: themeController.isDark,
                onChanged: (_) => themeController.toggle(),
              ),
              const Icon(Icons.dark_mode),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final content = _buildSections(context);
          if (!isWide) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: content,
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ListView(
                    children: [
                      content[0],
                      const SizedBox(height: 16),
                      content[1],
                      const SizedBox(height: 16),
                      content[2],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: ListView(
                    children: [
                      content[3],
                      const SizedBox(height: 16),
                      content[4],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    return [
      _HeaderCard(),
      _AboutCard(),
      _SkillsCard(skills: const [
        'Flutter',
        'Dart',
        'Firebase',
        'REST APIs',
        'Git',
        'UI/UX',
        'Problem Solving',
      ]),
      _LinksCard(links: const [
        SocialLink(name: 'GitHub', icon: Icons.code, url: 'https://github.com/your-handle'),
        SocialLink(name: 'LinkedIn', icon: Icons.work, url: 'https://www.linkedin.com/in/your-handle'),
        SocialLink(name: 'Website', icon: Icons.public, url: 'https://example.com'),
      ]),
      const _ContactCard(email: 'you@example.com', phone: '+84 912 345 678'),
    ];
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Min – Flutter Learner', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Beginner dev building clean, responsive UIs and learning Flutter fundamentals.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _StatChip(icon: Icons.apps, label: '2 Apps'),
                      _StatChip(icon: Icons.school, label: 'Learning Daily'),
                      _StatChip(icon: Icons.timer, label: 'Week 1 Goals'),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Me', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Xin chào! Mình là Min. Tuần 1 mình tập trung học bố cục cơ bản, quản lý trạng thái đơn giản, '
                  'và điều hướng trong Flutter. Ứng dụng hồ sơ này giúp mình luyện Column, ListTile, CircleAvatar, Card, '
                  'và responsive layout + dark mode.',
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.flag),
              title: Text('Goal'),
              subtitle: Text('Build a clean, responsive portfolio screen with a theme toggle.'),
            ),
            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Outcome'),
              subtitle: Text('A simple personal profile you can expand later with navigation & state.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final List<String> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLink {
  final String name;
  final IconData icon;
  final String url;
  const SocialLink({required this.name, required this.icon, required this.url});
}

class _LinksCard extends StatelessWidget {
  final List<SocialLink> links;
  const _LinksCard({required this.links});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social & Projects', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...links.map((l) => ListTile(
              leading: Icon(l.icon),
              title: Text(l.name),
              subtitle: Text(l.url),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _safeLaunch(l.url),
            )),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String email;
  final String phone;
  const _ContactCard({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(email),
              onTap: () => _safeLaunch('mailto:$email'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(phone),
              onTap: () => _safeLaunch('tel:$phone'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _safeLaunch(String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
