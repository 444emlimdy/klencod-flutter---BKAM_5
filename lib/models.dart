class MarketDef {
  final String id;
  final String ar;
  final String en;
  final IconData icon;
  const MarketDef(this.id, this.ar, this.en, this.icon);
}

class ProductItem {
  final String id;
  final String market;
  final String name;
  final String size;
  final double price;
  final double? wholesalePrice;
  final String image;
  final String ahash;
  final String dhash;
  final List<double> color;
  final DateTime createdAt;

  const ProductItem({
    required this.id, required this.market, required this.name,
    required this.size, required this.price, required this.wholesalePrice,
    required this.image, required this.ahash, required this.dhash,
    required this.color, required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'market': market, 'name': name, 'size': size,
    'price': price, 'wholesalePrice': wholesalePrice, 'image': image,
    'ahash': ahash, 'dhash': dhash, 'color': color,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
    id: j['id'] as String, market: j['market'] as String,
    name: j['name'] as String, size: j['size'] as String,
    price: (j['price'] as num).toDouble(),
    wholesalePrice: (j['wholesalePrice'] as num?)?.toDouble(),
    image: j['image'] as String, ahash: j['ahash'] as String,
    dhash: j['dhash'] as String,
    color: (j['color'] as List).map((e) => (e as num).toDouble()).toList(),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

const markets = <MarketDef>[
  MarketDef('grocery','سوق غذائية','Grocery Market', Icons.shopping_basket_outlined),
  MarketDef('livestock','سوق مواشي','Livestock Market', Icons.pets_outlined),
  MarketDef('cleaning','سوق تنظيف','Cleaning Market', Icons.cleaning_services_outlined),
  MarketDef('clothing','سوق ملابس','Clothing Market', Icons.checkroom_outlined),
  MarketDef('attar','سوق عطار','Spice & Herbs Market', Icons.spa_outlined),
  MarketDef('phones','سوق هواتف','Phones Market', Icons.phone_android),
  MarketDef('shoes','سوق أحذية','Shoes Market', Icons.directions_walk),
  MarketDef('legumes','سوق بقوليات','Legumes Market', Icons.grass),
  MarketDef('pharmacy','سوق صيدلية','Pharmacy Market', Icons.local_pharmacy_outlined),
  MarketDef('gold','سوق ذهب','Gold Market', Icons.diamond_outlined),
  MarketDef('home','سوق منزلية','Home Goods Market', Icons.chair_outlined),
  MarketDef('toys','سوق ألعاب','Toys Market', Icons.toys_outlined),
  MarketDef('electronics','سوق كهربائية','Electronics Market', Icons.electrical_services),
  MarketDef('wholesale','جملة','Wholesale', Icons.inventory_2_outlined),
];
