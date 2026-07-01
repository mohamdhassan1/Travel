import 'package:first_app/Data/place_model.dart';
import 'package:first_app/core/reposatories/plase_reposatory.dart';
import 'package:first_app/logic/Blocs/place/place_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaceBloc(PlaceRepository())..add(LoadPlaces()),
      child: const _HomeView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _tabIndex = 0;
  final _tabs = ['Location', 'Hotels', 'Food', 'Adventure'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Aspen',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  // Location chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Color(0xFF1565C0), size: 15),
                        SizedBox(width: 4),
                        Text('Aspen, USA', style: TextStyle(fontSize: 13)),
                        Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Find things to do',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Category tabs ────────────────────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                itemBuilder: (_, i) {
                  final active = i == _tabIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      child: Column(
                        children: [
                          Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.normal,
                              color: active
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                            ),
                          ),
                          if (active)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              height: 3,
                              width: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── BLoC content ─────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<PlaceBloc, PlaceState>(
                builder: (context, state) {
                  if (state is PlaceLoading || state is PlaceInitial) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1565C0)));
                  }
                  if (state is PlaceError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is PlaceLoaded) {
                    return _PlacesList(places: state.places);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable list: Popular + Recommended sections
// ─────────────────────────────────────────────────────────────────────────────

class _PlacesList extends StatelessWidget {
  final List<PlaceModel> places;
  const _PlacesList({required this.places});

  @override
  Widget build(BuildContext context) {
    // Split: first half → Popular, second half → Recommended
    // (or use an `isPopular` field in Firestore — see guide)
    final popular = places.take(2).toList();
    final recommended = places.skip(2).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Popular section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Popular',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all',
                      style: TextStyle(color: Color(0xFF1565C0))),
                ),
              ],
            ),
          ),

          // Popular cards — horizontal scroll
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: popular.length,
              itemBuilder: (_, i) => Padding(
                padding:
                    EdgeInsets.only(right: i < popular.length - 1 ? 14 : 0),
                child: _PopularCard(
                  place: popular[i],
                  wide: i == 1, // second card is wider (matches design)
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Recommended section ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Recommended',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 14),

          if (recommended.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No recommendations yet',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommended.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (_, i) => _RecommendedCard(place: recommended[i]),
              ),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popular card widget
// ─────────────────────────────────────────────────────────────────────────────

class _PopularCard extends StatelessWidget {
  final PlaceModel place;
  final bool wide;
  const _PopularCard({required this.place, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(place: place))),
      child: Container(
        width: wide ? 170 : 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Positioned.fill(child: _NetImage(url: place.image)),

              // Gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Title + rating
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(place.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFB300), size: 11),
                          const SizedBox(width: 2),
                          Text(place.rate.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Favourite icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite,
                      color: Color(0xFFE53935), size: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommended card widget
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  final PlaceModel place;
  const _RecommendedCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(place: place))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: _NetImage(url: place.image)),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xAA000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(place.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable network image with loading + error fallback
// ─────────────────────────────────────────────────────────────────────────────

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Container(color: Colors.grey.shade300);
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Container(color: Colors.grey.shade200),
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: const Icon(Icons.home_filled,
                  color: Color(0xFF1565C0), size: 26),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.grey, size: 24),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.favorite_border,
                  color: Colors.grey, size: 24),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.person_outline,
                  color: Colors.grey, size: 24),
              onPressed: () {}),
        ],
      ),
    );
  }
}
