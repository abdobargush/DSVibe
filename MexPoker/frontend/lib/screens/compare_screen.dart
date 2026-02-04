import 'package:flutter/material.dart';
import '../models/poker_models.dart';
import '../services/api_service.dart';

class CompareScreen extends StatefulWidget {
  final ApiService apiService;

  const CompareScreen({super.key, required this.apiService});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _p1HoleCardsController = TextEditingController(text: "HA, HK");
  final _p1CommunityCardsController = TextEditingController(text: "HQ, HJ, HT, D2, C3");
  final _p2HoleCardsController = TextEditingController(text: "SA, SK");
  final _p2CommunityCardsController = TextEditingController(text: "HQ, HJ, HT, D2, C3");
  CompareResponse? _response;
  bool _isLoading = false;

  Future<void> _compareHands() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final p1Hole = _p1HoleCardsController.text.split(',').map((s) => s.trim()).toList();
      final p1Community = _p1CommunityCardsController.text.split(',').map((s) => s.trim()).toList();
      final p2Hole = _p2HoleCardsController.text.split(',').map((s) => s.trim()).toList();
      final p2Community = _p2CommunityCardsController.text.split(',').map((s) => s.trim()).toList();

      final response = await widget.apiService.compareHands(p1Hole, p1Community, p2Hole, p2Community);
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
          const Text('Player 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _p1HoleCardsController,
            decoration: const InputDecoration(
              labelText: 'Hole Cards (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _p1CommunityCardsController,
            decoration: const InputDecoration(
              labelText: 'Community Cards (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Player 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _p2HoleCardsController,
            decoration: const InputDecoration(
              labelText: 'Hole Cards (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _p2CommunityCardsController,
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
              onPressed: _compareHands,
              child: const Text('Compare Hands'),
            ),
          const SizedBox(height: 16),
          if (_response != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Winner: ${_response!.winner}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Reason: ${_response!.winnerReason}'),
                    const SizedBox(height: 16),
                    const Text('Player 1 Hand:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Best Hand: ${_response!.player1Hand.bestHand}'),
                    Text('Cards: ${_response!.player1Hand.cards.join(', ')}'),
                    const SizedBox(height: 16),
                    const Text('Player 2 Hand:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Best Hand: ${_response!.player2Hand.bestHand}'),
                    Text('Cards: ${_response!.player2Hand.cards.join(', ')}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
