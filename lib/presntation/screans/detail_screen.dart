import 'package:first_app/Data/place_model.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final PlaceModel place;
  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _expanded = false;
  bool _favourite = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.place;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable body ──────────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ─────────────────────────────────────────────
                Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: p.image.isNotEmpty
                          ? Image.network(p.image, fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade300),
                    ),

                    // Back button
                    Positioned(
                      top: 50,
                      left: 16,
                      child: _IconBtn(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16),
                      ),
                    ),

                    // Favourite button
                    Positioned(
                      top: 50,
                      right: 16,
                      child: _IconBtn(
                        onTap: () => setState(() => _favourite = !_favourite),
                        child: Icon(
                          _favourite ? Icons.favorite : Icons.favorite_border,
                          color: _favourite
                              ? const Color(0xFFE53935)
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Content ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Show map
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.title,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Show map',
                                style: TextStyle(
                                    color: Color(0xFF1565C0), fontSize: 13)),
                          ),
                        ],
                      ),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFB300), size: 17),
                          const SizedBox(width: 4),
                          Text(p.rate.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(Reviews)',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description (collapsible)
                      Text(
                        p.description,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.6),
                      ),

                      // Read more toggle
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Row(
                          children: [
                            Text(
                              _expanded ? 'Read less' : 'Read more',
                              style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF1565C0),
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Facilities
                      const Text('Facilities',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 16),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Facility(
                              icon: Icons.whatshot_outlined, label: '1 Heater'),
                          _Facility(icon: Icons.restaurant, label: 'Dinner'),
                          _Facility(
                              icon: Icons.bathtub_outlined, label: '1 Tub'),
                          _Facility(icon: Icons.pool, label: 'Pool'),
                        ],
                      ),

                      // Padding so content isn't hidden behind the fixed bar
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed bottom bar ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -3))
                ],
              ),
              child: Row(
                children: [
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Price',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        p.price > 0 ? '\$${p.price.toStringAsFixed(0)}' : '\$—',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Book Now button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Text('Book Now',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        label: const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _Facility extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Facility({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
