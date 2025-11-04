class Article {
  final String title;
  final String? description;
  final String? author;
  final String url;
  final String? urlToImage;
  final DateTime? publishedAt;
  final String? sourceName;
  final String? content;

  Article({
    required this.title,
    required this.url,
    this.description,
    this.author,
    this.urlToImage,
    this.publishedAt,
    this.sourceName,
    this.content,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>?;
    return Article(
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      author: json['author']?.toString(),
      url: (json['url'] ?? '').toString(),
      urlToImage: json['urlToImage']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      sourceName: source?['name']?.toString(),
      content: json['content']?.toString(),
    );
  }
}
