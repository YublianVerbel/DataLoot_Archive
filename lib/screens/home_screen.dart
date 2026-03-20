import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/noticia.dart';
import '../widgets/noticia_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroFuente = 'Todas';
  final List<String> _fuentes = ['Todas', 'Vandal', 'Eurogamer', 'Gamespot', 'Kotaku', 'PCGamer'];

  Stream<List<Noticia>> _getNoticias() {
    Query query = FirebaseFirestore.instance
        .collection('noticias')
        .orderBy('publishedAt', descending: true)
        .limit(50);

    if (_filtroFuente != 'Todas') {
      query = query.where('source', isEqualTo: _filtroFuente);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) =>
            Noticia.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
        ).toList()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Text('🎮', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'DataLoot Archive',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros por fuente
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _fuentes.length,
              itemBuilder: (context, index) {
                final fuente = _fuentes[index];
                final isSelected = fuente == _filtroFuente;
                return GestureDetector(
                  onTap: () => setState(() => _filtroFuente = fuente),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        fuente,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de noticias
          Expanded(
            child: StreamBuilder<List<Noticia>>(
              stream: _getNoticias(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final noticias = snapshot.data ?? [];
                if (noticias.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay noticias aún',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: noticias.length,
                  itemBuilder: (context, index) =>
                      NoticiaCard(noticia: noticias[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}