import 'package:flutter/material.dart';

class BedCounter extends StatefulWidget {
  final Function(int) onBedCountChanged;
  final VoidCallback onReset;

  const BedCounter({
    Key? key,
    required this.onBedCountChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  _BedCounterState createState() => _BedCounterState();
}

class _BedCounterState extends State<BedCounter> {
  int bedCount = 2;
  final int minBedCount = 2;
  final int maxBedCount = 20;
  bool isError = false;
  TextEditingController bedCountController = TextEditingController(text: '2');
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    bedCountController.text = bedCount.toString();
  }

  @override
  void dispose() {
    bedCountController.dispose();
    super.dispose();
  }

  Widget showErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  void setErrorMessage(String message) {
    setState(() {
      isError = true;
      errorMessage = message;
    });
  }

  void clearErrorMessage() {
    setState(() {
      isError = false;
      errorMessage = null;
    });
  }

  void resetStepper() {
    setState(() {
      bedCount = 2;
      bedCountController.text = "2";
      clearErrorMessage();
    });
  }

  void updateBedCount(int value) {
    if (value >= minBedCount && value <= maxBedCount) {
      setState(() {
        bedCount = value;
        bedCountController.text = value.toString();
        clearErrorMessage();
      });
      widget.onBedCountChanged(bedCount);
    } else if (value > maxBedCount) {
      setState(() {
        bedCount = maxBedCount;
        bedCountController.text = maxBedCount.toString();
        setErrorMessage("Max 20 beds can be added at a time!");
      });
    } else if (value < minBedCount) {
      setState(() {
        bedCount = minBedCount;
        bedCountController.text = minBedCount.toString();
        setErrorMessage("Min 2 beds can be added!");
      });
    }
  }

  void onEditingComplete() {
    int? enteredValue = int.tryParse(bedCountController.text);

    if (enteredValue != null) {
      if (enteredValue < minBedCount) {
        updateBedCount(minBedCount);
      } else if (enteredValue > maxBedCount) {
        updateBedCount(maxBedCount);
      } else {
        updateBedCount(enteredValue);
      }
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevents unnecessary expansion
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(
              color: isError ? Colors.red : Colors.grey.shade400,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Left-aligned number input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.number,
                    controller: bedCountController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true, // Reduces the default padding
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onEditingComplete: onEditingComplete,
                  ),
                ),
              ),

              // Vertical Stepper Buttons
              Container(
                width: 48,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  children: [
                    _stepperButton(
                      Icons.keyboard_arrow_up,
                      () => updateBedCount(bedCount + 1)),
                    Divider(height: 1, color: Colors.grey.shade400),
                    _stepperButton(
                      Icons.keyboard_arrow_down,
                      () => updateBedCount(bedCount - 1)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Error Message with proper spacing
        if (isError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: showErrorMessage(errorMessage!),
          ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Icon(icon, size: 24, color: Colors.black54),
        ),
      ),
    );
  }
}
