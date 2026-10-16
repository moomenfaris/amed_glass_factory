class MovementImages {
  final int count;
  final List<String> images;
  final String? message;

  const MovementImages({
    required this.count,
    required this.images,
    this.message,
  });

  factory MovementImages.fromApi(Map<String, dynamic> j) {
    final rawImages = (j['images'] as List?) ?? const [];
    final images = rawImages
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return MovementImages(
      count: (j['count'] as num?)?.toInt() ?? images.length,
      images: images,
      message: (j['message'] as String?)?.trim(),
    );
  }
}
