import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import 'login_screen.dart';

const _filters = ['All', 'Pending', 'Verified', 'In Progress', 'Resolved'];
const _filterValues = {
  'All': null,
  'Pending': 'pending',
  'Verified': 'verified',
  'In Progress': 'in_progress',
  'Resolved': 'resolved',
};

const _filterColors = {
  'All': AppColors.amber,
  'Pending': Color(0xFFF4C261),
  'Verified': Color(0xFF61B4F4),
  'In Progress': Color(0xFF9B8CF4),
  'Resolved': Color(0xFF61F4A2),
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeFilter = 'All';

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout, color: Color(0xFFD94F4F), size: 18),
          SizedBox(width: 8),
          Text('Log Out',
              style: TextStyle(color: AppColors.white, fontSize: 16)),
        ]),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(
                    color: Color(0xFFD94F4F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFD94F4F), size: 20),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final name = userData?['name'] ?? user.displayName ?? 'Citizen';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Card ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.navyElevated),
                ),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.navyElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amber, width: 2),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.amber, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white)),
                        const SizedBox(height: 2),
                        Text(user.email ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Citizen Reporter',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Section Header ────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('MY REPORTS',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ),

              const SizedBox(height: 10),

              // ── Filter Chips ──────────────────────────────────────────
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _filters.length,
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final isActive = _activeFilter == f;
                    final color = _filterColors[f] ?? AppColors.amber;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withValues(alpha: 0.15)
                              : AppColors.navySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? color : AppColors.navyElevated,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (f != 'All') ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? color : AppColors.inactive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(f,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive ? color : AppColors.inactive,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Reports List ──────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.amber, strokeWidth: 2));
                    }
                    if (snap.hasError) {
                      return const Center(
                          child: Text('Error loading reports.',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)));
                    }

                    var docs = snap.data?.docs ?? [];
                    final filterVal = _filterValues[_activeFilter];
                    if (filterVal != null) {
                      docs = docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['status'] ==
                              filterVal)
                          .toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _activeFilter == 'All'
                                    ? Icons.inbox_outlined
                                    : Icons.filter_list_off,
                                color: AppColors.inactive,
                                size: 36),
                            const SizedBox(height: 10),
                            Text(
                                _activeFilter == 'All'
                                    ? 'No reports yet'
                                    : 'No $_activeFilter reports',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted)),
                            const SizedBox(height: 4),
                            Text(
                                _activeFilter == 'All'
                                    ? 'Tap Report to submit your first issue'
                                    : 'Try a different filter',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.inactive)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return ReportCard(report: data);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
