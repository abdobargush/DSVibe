import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'generated/temperature.pbgrpc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _controller = TextEditingController();
  String _result = '';
  bool _isCelsiusToFahrenheit = true;
  late TemperatureConverterClient _client;

  @override
  void initState() {
    super.initState();
    _initGrpcClient();
  }

  void _initGrpcClient() {
    // Get envoy host from environment or use default
    final host = const String.fromEnvironment('ENVOY_HOST', defaultValue: 'localhost');
    final port = const int.fromEnvironment('ENVOY_PORT', defaultValue: 8080);

    final channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );

    _client = TemperatureConverterClient(channel);
  }

  Future<void> _convert() async {
    final value = double.tryParse(_controller.text);
    if (value == null) {
      setState(() {
        _result = 'Please enter a valid number';
      });
      return;
    }

    try {
      final request = TemperatureRequest()..value = value;
      final response = _isCelsiusToFahrenheit
          ? await _client.convertToFahrenheit(request)
          : await _client.convertToCelsius(request);

      setState(() {
        _result = '${response.value.toStringAsFixed(2)} °${response.unit[0]}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Converter'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Temperature',
                          suffixText: _isCelsiusToFahrenheit ? '°C' : '°F',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('°C to °F'),
                          Switch(
                            value: !_isCelsiusToFahrenheit,
                            onChanged: (value) {
                              setState(() {
                                _isCelsiusToFahrenheit = !value;
                              });
                            },
                          ),
                          const Text('°F to °C'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _convert,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          child: Text('Convert'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _result,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}