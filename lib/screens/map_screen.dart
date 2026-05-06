import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchCtrl = TextEditingController();
  final _mapController = MapController();
  String _query = '';
  bool _showResults = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterReports(
      List<QueryDocumentSnapshot> reports) {
    if (_query.isEmpty) return reports;
    final q = _query.toLowerCase();
    return reports.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type = (data['type'] ?? '').toString().toLowerCase();
      final address =
          (data['location']?['address'] ?? '').toString().toLowerCase();
      final desc = (data['description'] ?? '').toString().toLowerCase();
      return type.contains(q) || address.contains(q) || desc.contains(q);
    }).toList();
  }

  void _flyTo(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 16);
    setState(() {
      _showResults = false;
      _searchCtrl.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'verified')
            .snapshots(),
        builder: (context, snapshot) {
          final allReports = snapshot.data?.docs ?? [];
          final filtered = _filterReports(allReports);

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(9.8500, 124.1435),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bantaydaan.app',
                  ),
                  MarkerLayer(
                    markers: allReports.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final lat = (data['location']?['lat'] ?? 0.0).toDouble();
                      final lng = (data['location']?['lng'] ?? 0.0).toDouble();
                      final type = data['type'] ?? '';
                      final color = AppColors.forType(type);

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: () => _showBottomSheet(context, data),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.warning_amber,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // ── Search Bar + Results ───────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 14,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Search input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.navySurface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search,
                                color: AppColors.muted, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search by type, address, description...',
                                  hintStyle: TextStyle(
                                      color: AppColors.inactive, fontSize: 12),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (val) => setState(() {
                                  _query = val;
                                  _showResults = val.isNotEmpty;
                                }),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _searchCtrl.clear();
                                  _query = '';
                                  _showResults = false;
                                }),
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.close,
                                      color: AppColors.inactive, size: 16),
                                ),
                              )
                            else
                              const SizedBox(width: 14),
                          ],
                        ),
                      ),

                      // Search results dropdown
                      if (_showResults) ...[
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: AppColors.navySurface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: filtered.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(children: [
                                    Icon(Icons.search_off,
                                        color: AppColors.inactive, size: 16),
                                    SizedBox(width: 8),
                                    Text('No reports found',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12)),
                                  ]),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: AppColors.navyElevated),
                                  itemBuilder: (_, i) {
                                    final data = filtered[i].data()
                                        as Map<String, dynamic>;
                                    final type = data['type'] ?? '';
                                    final address =
                                        data['location']?['address'] ?? '';
                                    final lat =
                                        (data['location']?['lat'] ?? 0.0)
                                            .toDouble();
                                    final lng =
                                        (data['location']?['lng'] ?? 0.0)
                                            .toDouble();
                                    final color = AppColors.forType(type);

                                    return ListTile(
                                      dense: true,
                                      leading: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.warning_amber,
                                            color: color, size: 16),
                                      ),
                                      title: Text(
                                        type,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white),
                                      ),
                                      subtitle: Text(
                                        address,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.my_location,
                                          color: AppColors.amber, size: 16),
                                      onTap: () {
                                        _flyTo(lat, lng);
                                        _showBottomSheet(context, data);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Report count badge ─────────────────────────────────
              if (allReports.isNotEmpty && !_showResults)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.navySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.navyElevated),
                      ),
                      child: Text(
                        '${allReports.length} verified report${allReports.length == 1 ? '' : 's'} on map',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.forType(data['type'] ?? ''),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data['type'] ?? '',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white),
              ),
              const Spacer(),
              StatusBadge(data['status'] ?? 'verified'),
            ]),
            const SizedBox(height: 6),
            Text(
              data['location']?['address'] ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              data['description'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.white, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
