import 'package:flutter/material.dart';
import '../models/poker_models.dart';
import '../services/api_service.dart';

class ProbabilityScreen extends StatefulWidget {
  final ApiService apiService;

  const ProbabilityScreen({super.key, required this.apiService});

  @override
  State<ProbabilityScreen> createState() => _ProbabilityScreenState();
}

class _ProbabilityScreenState extends State<ProbabilityScreen> {
  final _holeCardsController = TextEditingController(text: "HA, HK");
  final _communityCardsController = TextEditingController(text: "HQ, HJ");
  final _numPlayersController = TextEditingController(text: "3");
  final _numSimulationsController = TextEditingController(text: "1000");
  ProbabilityResponse? _response;
  bool _isLoading = false;

  Future<void> _calculateProbability() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final holeCards = _holeCardsController.text.split(',').map((s) => s.trim()).toList();
      final communityCards = _communityCardsController.text.split(',').map((s) => s.trim()).toList();
      final numPlayers = int.parse(_numPlayersController.text);
      final numSimulations = int.parse(_numSimulationsController.text);

      final response = await widget.apiService.calculateProbability(holeCards, communityCards, numPlayers, numSimulations);
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
          TextField(
            controller: _numPlayersController,
            decoration: const InputDecoration(
              labelText: 'Number of Players',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numSimulationsController,
            decoration: const InputDecoration(
              labelText: 'Number of Simulations',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _calculateProbability,
              child: const Text('Calculate Probability'),
            ),
          const SizedBox(height: 16),
          if (_response != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulations: ${_response!.simulations}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Win Probability: ${_response!.winProbability.toStringAsFixed(2)}%'),
                    const SizedBox(height: 8),
                    Text('Tie Probability: ${_response!.tieProbability.toStringAsFixed(2)}%'),
                    const SizedBox(height: 8),
                    Text('Lose Probability: ${_response!.loseProbability.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
