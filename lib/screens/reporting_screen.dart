import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

const List<Map<String, dynamic>> kIssueTypes = [
  {
    'label': 'Pothole',
    'icon': Icons.circle_outlined,
    'color': AppColors.pothole
  },
  {
    'label': 'Flooding',
    'icon': Icons.water_outlined,
    'color': AppColors.flooding
  },
  {
    'label': 'Obstruction',
    'icon': Icons.block_outlined,
    'color': AppColors.obstruction
  },
  {
    'label': 'Road Damage',
    'icon': Icons.broken_image_outlined,
    'color': AppColors.roadDamage
  },
  {
    'label': 'Accident',
    'icon': Icons.warning_amber_outlined,
    'color': AppColors.accident
  },
  {
    'label': 'Missing Signage',
    'icon': Icons.no_photography_outlined,
    'color': AppColors.signage
  },
];

// ─── Cloudinary config ───────────────────────────────────────────────────────
const _cloudName = 'dvi2bzbiz';
const _uploadPreset = 'bantay_daan';
// ─────────────────────────────────────────────────────────────────────────────

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  String? _selectedType;
  final _descCtrl = TextEditingController();
  File? _photo;
  Position? _position;
  String _address = 'Detecting location...';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _address = 'Location services disabled. Tap to enable.');
        await Geolocator.openLocationSettings();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        _position!.latitude,
        _position!.longitude,
      );
      if (mounted) {
        setState(() {
          _address = '${placemarks.first.street}, ${placemarks.first.locality}';
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _address = 'Could not detect location. Tap to retry.');
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode == 200) {
      return json['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed: ${json['error']['message']}');
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      _snack('Please select an issue type.');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a description.');
      return;
    }
    if (_photo == null) {
      _snack('Please take a photo of the issue.');
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Upload photo to Cloudinary
      final photoUrl = await _uploadToCloudinary(_photo!);

      // 2. Save report to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'type': _selectedType,
        'description': _descCtrl.text.trim(),
        'photoUrl': photoUrl,
        'location': {
          'lat': _position?.latitude,
          'lng': _position?.longitude,
          'address': _address,
        },
        'status': 'pending',
        'priority': 'low',
        'adminRemark': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.navySurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.resolved, size: 20),
              SizedBox(width: 8),
              Text('Submitted!',
                  style: TextStyle(color: AppColors.white, fontSize: 16)),
            ]),
            content: const Text(
              'Your report has been submitted. Authorities will review it shortly.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reset();
                },
                child:
                    const Text('OK', style: TextStyle(color: AppColors.amber)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedType = null;
      _descCtrl.clear();
      _photo = null;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.navyElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        elevation: 0,
        title: const Text(
          'New Report',
          style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('ISSUE TYPE'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: kIssueTypes.map((t) {
                final isSelected = _selectedType == t['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.amberMuted
                          : AppColors.navyElevated,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.amber : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t['icon'] as IconData,
                            color: t['color'] as Color, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          t['label'] as String,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _sectionLabel('DESCRIPTION'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _inputDecor('Describe the issue in detail...'),
            ),
            const SizedBox(height: 14),
            _sectionLabel('LOCATION'),
            GestureDetector(
              onTap: _detectLocation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.navyElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.location_pin,
                      color: AppColors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.refresh,
                      color: AppColors.inactive, size: 14),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _sectionLabel('PHOTO'),
            GestureDetector(
              onTap: _pickPhoto,
              child: _photo != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _photo!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _photo = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.amber, width: 1.5),
                        color: AppColors.amberMuted,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: AppColors.amber, size: 28),
                          SizedBox(height: 6),
                          Text(
                            'Tap to take a photo',
                            style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF1a0e00), strokeWidth: 2))
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                            color: Color(0xFF1a0e00),
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inactive),
        filled: true,
        fillColor: AppColors.navyElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}
