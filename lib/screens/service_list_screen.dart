// lib/screens/service_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceListScreen extends StatelessWidget {
  final List<String> categories = [
    'Santé',
    'Beauté',
    'Automobile',
    'Éducation',
    'Bien-être',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: ServiceSearchDelegate(categories),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de filtres
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(categories[index]),
                    onSelected: (selected) {
                      // Implémenter le filtrage
                    },
                  ),
                );
              },
            ),
          ),
          // Liste des services
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Une erreur est survenue'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final service = snapshot.data!.docs[index];
                    return ServiceCard(
                      title: service['name'],
                      category: service['category'],
                      price: service['price'],
                      imageUrl: service['imageUrl'],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/service-detail',
                        arguments: service.id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String category;
  final double price;
  final String? imageUrl;
  final VoidCallback onTap;

  const ServiceCard({
    required this.title,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${price.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceSearchDelegate extends SearchDelegate {
  final List<String> categories;

  ServiceSearchDelegate(this.categories);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('services')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Une erreur est survenue'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final service = snapshot.data!.docs[index];
            return ServiceCard(
              title: service['name'],
              category: service['category'],
              price: service['price'],
              imageUrl: service['imageUrl'],
              onTap: () {
                close(context, null);
                Navigator.pushNamed(
                  context,
                  '/service-detail',
                  arguments: service.id,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        if (category.toLowerCase().contains(query.toLowerCase())) {
          return ListTile(
            title: Text(category),
            onTap: () {
              query = category;
              showResults(context);
            },
          );
        }
        return Container();
      },
    );
  }
}