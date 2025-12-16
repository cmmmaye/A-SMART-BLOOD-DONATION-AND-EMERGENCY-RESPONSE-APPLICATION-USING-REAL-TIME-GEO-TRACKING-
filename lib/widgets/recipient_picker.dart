import 'package:flutter/material.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../utils/blood_types.dart';

class RecipientPicker extends StatefulWidget {
  final String? donorBloodType;
  
  const RecipientPicker({Key? key, this.donorBloodType}) : super(key: key);

  @override
  _RecipientPickerState createState() => _RecipientPickerState();
}

class _RecipientPickerState extends State<RecipientPicker> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    try {
      final allRecipients = await DatabaseHelper.instance.getUsersByRole('recipient');
      
      // Filter recipients by compatible blood types if donor blood type is provided
      List<Map<String, dynamic>> filteredRecipients;
      if (widget.donorBloodType != null) {
        try {
          // Convert donor blood type string to BloodType enum
          final donorBloodTypeEnum = BloodTypeUtils.fromName(widget.donorBloodType!);
          
          // Get list of compatible recipient blood types
          final compatibleBloodTypes = donorBloodTypeEnum.possibleRecipients;
          
          // Convert to list of strings for comparison
          final compatibleBloodTypeStrings = compatibleBloodTypes
              .map((bt) => bt.name)
              .toList();
          
          // Filter recipients to only show those with compatible blood types
          filteredRecipients = allRecipients.where((r) {
            final recipientBloodType = r['blood_type'] as String?;
            return recipientBloodType != null &&
                compatibleBloodTypeStrings.contains(recipientBloodType);
          }).toList();
        } catch (e) {
          debugPrint('Error processing blood type compatibility: $e');
          // Fallback to exact match if there's an error
          filteredRecipients = allRecipients.where((r) {
            final recipientBloodType = r['blood_type'] as String?;
            return recipientBloodType == widget.donorBloodType;
          }).toList();
        }
      } else {
        filteredRecipients = allRecipients;
      }
      
      setState(() {
        _recipients = filteredRecipients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recipients: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filtered = _recipients
        .where((r) {
          final name = r['name'] as String?;
          final email = r['email'] as String?;
          final searchText = _searchController.text.toLowerCase();
          return (name?.toLowerCase().contains(searchText) ?? false) ||
              (email?.toLowerCase().contains(searchText) ?? false);
        })
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
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search recipients',
                  isDense: true,
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bloodtype,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? widget.donorBloodType != null
                                          ? 'No compatible recipients found'
                                          : 'No recipients found'
                                      : 'No recipients match your search',
                                  style: textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                if (widget.donorBloodType != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Showing recipients with compatible blood types for ${widget.donorBloodType}',
                                      style: textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final recipient = filtered[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: MainColors.primary,
                                child: Text(
                                  (recipient['name'] as String? ?? 'R')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                recipient['name'] as String? ?? 'Unknown',
                                style: textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipient['email'] as String? ?? '',
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: textTheme.bodySmall!.color,
                                    ),
                                  ),
                                  if (recipient['blood_type'] != null)
                                    Text(
                                      'Blood Type: ${recipient['blood_type']}',
                                      style: textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, recipient);
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

