

import 'package:flutter/material.dart';

class EatSetupPage extends StatelessWidget {
  const EatSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How you eat')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Collect veg / egg / non-veg, weekly chicken-paneer-egg frequency, daily budget, allergies. Then filter meal_nutrition.',
        ),
      ),
    );
  }
}