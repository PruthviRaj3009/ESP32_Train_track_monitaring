import 'package:flutter/material.dart';

class ArmControlPanel extends StatefulWidget {
  const ArmControlPanel({super.key});

  @override
  State<ArmControlPanel> createState() => _ArmControlPanelState();
}

class _ArmControlPanelState extends State<ArmControlPanel> {
  double grip = 90;
  double wristPitch = 90;
  double wristRoll = 90;
  double elbow = 90;
  double shoulder = 90;
  double waist = 90;
  double speed = 50;

  Widget buildSlider(
    String label,
    double value,
    ValueChanged<double> onEnd, {
    Color color = Colors.orange,
    double max = 180,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          // LABEL
          SizedBox(
            width: 100, // fixed width for alignment
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          // SLIDER
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4, // slimmer slider
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8, // smaller thumb
                ),
              ),
              child: Slider(
                min: 0,
                max: max,
                value: value,
                activeColor: color,
                inactiveColor: Colors.grey.shade400,
                onChanged: (_) {}, // avoid continuous updates
                onChangeEnd: onEnd, // best for robotics
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TOP BAR
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text("Connect")),
            const Text(
              "Disconnected",
              style: TextStyle(color: Colors.red),
            ),
            ElevatedButton(onPressed: () {}, child: const Text("Disconnect")),
          ],
        ),

        const SizedBox(height: 5),

        // SLIDERS
        buildSlider("Grip", grip, (v) => setState(() => grip = v)),
        buildSlider(
            "Wrist Pitch", wristPitch, (v) => setState(() => wristPitch = v)),
        buildSlider(
            "Wrist Roll", wristRoll, (v) => setState(() => wristRoll = v)),
        buildSlider("Elbow", elbow, (v) => setState(() => elbow = v)),
        buildSlider("Shoulder", shoulder, (v) => setState(() => shoulder = v)),
        buildSlider("Waist", waist, (v) => setState(() => waist = v)),
        buildSlider(
          "Speed",
          speed,
          (v) => setState(() => speed = v),
          color: Colors.red,
        ),

        const SizedBox(height: 5),

        // BOTTOM BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text("SAVE")),
            ElevatedButton(onPressed: () {}, child: const Text("RUN")),
            ElevatedButton(onPressed: () {}, child: const Text("RESET")),
          ],
        ),

        const SizedBox(height: 5),
        const Text("Positions saved: 0"),
      ],
    );
  }
}
