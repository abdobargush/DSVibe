import 'package:flutter/material.dart';
import '../models/poker_models.dart';
import '../services/api_service.dart';

class EvaluateScreen extends StatefulWidget {
  final ApiService apiService;

  const EvaluateScreen({super.key, required this.apiService});

  @override
  State<EvaluateScreen> createState() => _EvaluateScreenState();
}

class _EvaluateScreenState extends State<EvaluateScreen> {
  final _holeCardsController = TextEditingController(text: "HA, HK");
  final _communityCardsController = TextEditingController(text: "HQ, HJ, HT, D2, C3");
  EvaluateResponse? _response;
  bool _isLoading = false;

  Future<void> _evaluateHand() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final holeCards = _holeCardsController.text.split(',').map((s) => s.trim()).toList();
      final communityCards = _communityCardsController.text.split(',').map((s) => s.trim()).toList();

      final response = await widget.apiService.evaluateHand(holeCards, communityCards);
      setState(() {
        _response = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _holeCardsController,
            decoration: const InputDecoration(
              labelText: 'Hole Cards (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _communityCardsController,
            decoration: const InputDecoration(
              labelText: 'Community Cards (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _evaluateHand,
              child: const Text('Evaluate Hand'),
            ),
          const SizedBox(height: 16),
          if (_response != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best Hand: ${_response!.bestHand}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Hand Value: ${_response!.handValue}'),
                    const SizedBox(height: 8),
                    Text('Cards: ${_response!.cards.join(', ')}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
