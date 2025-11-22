class Store {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
 
  final int count;

  Store({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
   
    required this.count,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      imageUrl: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? 'No description available.',
      category: json['category'] ?? 'Uncategorized',
      count: json['count']?? 0,
    );
  }
}
