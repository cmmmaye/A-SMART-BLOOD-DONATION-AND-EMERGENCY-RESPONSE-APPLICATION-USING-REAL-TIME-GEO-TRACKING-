import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../data/lists/blood_banks.dart';
import '../data/lists/hospitals.dart';
import '../data/lists/lrc_centers.dart';
import '../data/lists/medical_centers.dart';
import '../data/medical_center.dart';

class MedicalCenterPicker extends StatefulWidget {
  final MedicalCenterCategory? initialCategory;
  
  const MedicalCenterPicker({Key? key, this.initialCategory}) : super(key: key);

  @override
  _MedicalCenterPickerState createState() => _MedicalCenterPickerState();
}

class _MedicalCenterPickerState extends State<MedicalCenterPicker> {
  final _searchController = TextEditingController();
  late MedicalCenterCategory _category;
  late List<MedicalCenter> _centers;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? MedicalCenterCategory.hospitals;
    _updateCenters();
  }

  void _updateCenters() {
    switch (_category) {
      case MedicalCenterCategory.hospitals:
        _centers = hospitals;
        break;
      case MedicalCenterCategory.lrcCenters:
        _centers = lrcCenters;
        break;
      case MedicalCenterCategory.bloodBanks:
        _centers = bloodBanks;
        break;
      case MedicalCenterCategory.medicalCenters:
        _centers = medicalCenters;
        break;
    }
  }

  Future<void> _openLocationOnMap(MedicalCenter center) async {
    final latitude = center.latitude;
    final longitude = center.longitude;
    final placeName = center.name.replaceAll(' ', '+');
    
    // Try to open Google Maps app first, fallback to web
    final googleMapsUrl = 'geo:$latitude,$longitude?q=$placeName';
    
    // Fallback: Google Maps web
    final webUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    
    try {
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl, forceWebView: false);
      } else if (await canLaunch(webUrl)) {
        await launch(webUrl);
      } else {
        Fluttertoast.showToast(msg: 'Could not open map application');
      }
    } catch (e) {
      debugPrint('Error opening map: $e');
      Fluttertoast.showToast(msg: 'Could not open map application');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filtered = _centers
        .where((c) =>
            c.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            c.location
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search',
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<MedicalCenterCategory>(
                      value: _category,
                      items: MedicalCenterCategory.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (cat) {
                        if (cat == _category) return;
                        setState(() {
                          _category = cat!;
                          _updateCenters();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text(
                    filtered[i].name ?? '',
                    style: textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    filtered[i].location ?? '',
                    style: textTheme.bodyMedium!
                        .copyWith(color: textTheme.bodySmall!.color),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.map, color: MainColors.primary),
                    onPressed: () {
                      _openLocationOnMap(filtered[i]);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context, filtered[i]);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum MedicalCenterCategory { hospitals, lrcCenters, bloodBanks, medicalCenters }

extension on MedicalCenterCategory {
  String get name {
    switch (this) {
      case MedicalCenterCategory.hospitals:
        return 'Hospitals';
      case MedicalCenterCategory.lrcCenters:
        return 'Red Cross';
      case MedicalCenterCategory.bloodBanks:
        return 'Blood Banks';
      case MedicalCenterCategory.medicalCenters:
        return 'Others';
      default:
        return '';
    }
  }
}
