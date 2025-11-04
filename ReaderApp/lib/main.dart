import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/article.dart';
import 'services/news_api.dart';
import 'widgets/article_card.dart';

void main() {
  runApp(const NewsReaderApp());
}

class NewsReaderApp extends StatelessWidget {
  const NewsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B57D0);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'News Reader',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  String _country = 'us';
  String _category = 'general';
  late Future<List<Article>> _future;
  int _page = 1;

  static const _categories = <String>[
    'general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Article>> _load({bool resetPage = true}) {
    if (resetPage) _page = 1;
    return NewsApi.fetchTopHeadlines(
      country: _country,
      category: _category,
      query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      page: _page,
      pageSize: 20,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load(resetPage: true);
    });
  }

  Future<void> _openArticle(Article a) async {
    final uri = Uri.parse(a.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropdownStyle = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Reader'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                // Country (2-letter)
                SizedBox(
                  width: 88,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'us',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _country),
                    onSubmitted: (v) {
                      setState(() => _country = (v.trim().isEmpty ? 'us' : v.trim().toLowerCase()));
                      _refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Category
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _category,
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: dropdownStyle)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _category = v);
                        _refresh();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search box
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _refresh(),
                    decoration: InputDecoration(
                      hintText: 'Search keywords…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.search),
                        onPressed: _refresh,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorView(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                final articles = snapshot.data ?? const <Article>[];
                if (articles.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    itemCount: articles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == articles.length) {
                        // Simple pager "Load more"
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _page += 1;
                                  _future = NewsApi.fetchTopHeadlines(
                                    country: _country,
                                    category: _category,
                                    query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
                                    page: _page,
                                    pageSize: 20,
                                  ).then((more) => [...articles, ...more]);
                                });
                              },
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Load more'),
                            ),
                          ),
                        );
                      }
                      final a = articles[index];
                      return ArticleCard(article: a, onTap: () => _openArticle(a));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined, size: 64),
            const SizedBox(height: 12),
            Text('No articles', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Try a different keyword or category.'),
          ],
        ),
      ),
    );
  }
}
