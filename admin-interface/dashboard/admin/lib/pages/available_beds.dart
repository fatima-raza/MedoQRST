import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/pages/patient_identification.dart';

class AvailableBeds extends StatefulWidget {
  final void Function(String route, bool fromBedPage) onNext;

  const AvailableBeds({Key? key, required this.onNext}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AvailableBedsState createState() => _AvailableBedsState();
}

class _AvailableBedsState extends State<AvailableBeds> {
  bool isHovered = false;
  final ApiService apiService = ApiService();

  List<Map<String, dynamic>> wards = [];
  List<int> availableBeds = [];
  String? selectedWardName;
  String? selectedWardNo;
  bool isLoadingWards = true;
  bool isLoadingBeds = false;

  @override
  void initState() {
    super.initState();
    fetchWards();
  }

  // Fetch wards from API
  void fetchWards() async {
    setState(() => isLoadingWards = true);
    try {
      final fetchedWards = await apiService.getAllWards();
      if (fetchedWards != null) {
        setState(() {
          wards = fetchedWards;
        });
      }
    } catch (e) {
      print("Error fetching wards: $e");
    }
    setState(() => isLoadingWards = false);
  }

  // Fetch beds when a ward is selected
  void fetchBeds(String wardNo, String wardName) async {
    setState(() {
      selectedWardNo = wardNo;
      selectedWardName = wardName;
      isLoadingBeds = true;
      availableBeds = [];
    });

    final result = await apiService.getAvailableBeds(wardNo);
    if (result != null && result['status'] == 'success') {
      setState(() {
        availableBeds = List<int>.from(result['availableBeds']);
      });
    }
    setState(() => isLoadingBeds = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Align(
            alignment: Alignment.center, // Center the text
            child: Text(
              "Patient Registration",
              style: GoogleFonts.roboto(
                fontSize: 24,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            width: 400,
            height: 500,
            child: selectedWardNo == null ? buildWardsList() : buildBedsList(),
          ),
        ),
      ],
    ));
  }

  Widget buildWardsList() {
    if (isLoadingWards) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wards.isEmpty) {
      return const Center(child: Text('No Wards Available'));
    }

    // Create a map to track hover states for each ward
    final hoverStates = <String, ValueNotifier<bool>>{};
    for (final ward in wards) {
      hoverStates[ward['wardNo']] = ValueNotifier(false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Select a Ward',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF103783),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: wards.map((ward) {
                final hoverNotifier = hoverStates[ward['wardNo']]!;

                return ValueListenableBuilder<bool>(
                  valueListenable: hoverNotifier,
                  builder: (context, isHovered, child) {
                    return MouseRegion(
                      onEnter: (_) => hoverNotifier.value = true,
                      onExit: (_) => hoverNotifier.value = false,
                      child: GestureDetector(
                        onTap: () =>
                            fetchBeds(ward['wardNo'], ward['wardName']),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? const Color(0xFF123b63)
                                : Color.fromRGBO(56, 80, 128, 0.1),
                            border: Border.all(color: Colors.brown.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              ward['wardName'] ?? 'Unknown Ward',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBedsList() {
    if (isLoadingBeds) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              availableBeds.isEmpty
                  ? Text(
                      "No available beds in the '$selectedWardName'.",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Following beds available in the '$selectedWardName': ",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableBeds
                              .map((bed) => Chip(label: Text('Bed $bed')))
                              .toList(),
                        ),
                      ],
                    ),
              const SizedBox(height: 60),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => selectedWardNo = null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF103783),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: availableBeds.isEmpty
                    ? null
                    : () {
                        widget.onNext('/patient_identification', true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 71, 233, 77),
                ),
                child: Text(
                  'Proceed',
                  style: GoogleFonts.roboto(
                      color: const Color.fromARGB(255, 5, 4, 4)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
