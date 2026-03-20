class Noticia {
  final String id;
  final String title;
  final String url;
  final String summary;
  final String imageUrl;
  final String source;
  final String platform;
  final String categories;
  final String author;
  final String publishedAt;

  Noticia({
    required this.id,
    required this.title,
    required this.url,
    required this.summary,
    required this.imageUrl,
    required this.source,
    required this.platform,
    required this.categories,
    required this.author,
    required this.publishedAt,
  });

  factory Noticia.fromFirestore(Map<String, dynamic> data, String id) {
    return Noticia(
      id:          id,
      title:       data['title']       ?? '',
      url:         data['url']         ?? '',
      summary:     data['summary']     ?? '',
      imageUrl:    data['imageUrl']    ?? '',
      source:      data['source']      ?? '',
      platform:    data['platform']    ?? '',
      categories:  data['categories']  ?? '',
      author:      data['author']      ?? '',
      publishedAt: data['publishedAt'] ?? '',
    );
  }
}