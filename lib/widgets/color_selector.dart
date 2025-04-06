import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppColor {
  final String name;
  final Color color;

  AppColor(this.name, this.color);
}

class ColorSelector extends StatelessWidget {
  final List<AppColor> presetColors;  // List of AppColor objects
  final String selectedColor;  // Now it's a string (e.g., "Red")
  final ValueChanged<String> onColorSelected;  // Callback with string color name
  final bool smallSize;

  const ColorSelector({
    super.key,
    required this.presetColors,
    required this.selectedColor,
    required this.onColorSelected,
    this.smallSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final double circleSize = smallSize ? 16 : 24;
    final double spacing = smallSize ? 6 : 12;

    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: presetColors.map((appColor) {
            final isSelected = appColor.name == selectedColor;
            return GestureDetector(
              onTap: () => onColorSelected(appColor.name),  // Pass the color name (string) on tap
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                      color: settingsService.isDarkTheme()
                          ? Colors.white
                          : Colors.black,
                      width: 2)
                      : null,
                ),
                width: circleSize,
                height: circleSize,
                child: CircleAvatar(
                  backgroundColor: appColor.color,  // Use the color from AppColor
                  radius: circleSize / 2,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
