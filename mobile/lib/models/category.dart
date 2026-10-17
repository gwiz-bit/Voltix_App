class Category {
  final int id;
  final String name;
  final String slug; // cpu, mainboard, ram, vga, ssd, psu, case, cooler

  const Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}
