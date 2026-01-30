import 'package:flutter/material.dart';
import 'package:grpc/grpc_web.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String _result = '';
  bool _isCelsiusToFahrenheit = true;
  TemperatureConverterClient? _client;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initGrpcClient();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initGrpcClient() {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    final envoyUrl = 'http://$host:8080';
    
    print('Connecting to Envoy at: $envoyUrl');
    
    final channel = GrpcWebClientChannel.xhr(
      Uri.parse(envoyUrl),
    );

    _client = TemperatureConverterClient(channel);
  }

  Future<void> _convert() async {
    if (_client == null) {
      setState(() {
        _result = 'Client not initialized';
      });
      return;
    }

    final value = double.tryParse(_controller.text);
    if (value == null) {
      setState(() {
        _result = 'Please enter a valid number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _animationController.forward().then((_) => _animationController.reverse());

    try {
      final request = TemperatureRequest()..value = value;
      
      final response = _isCelsiusToFahrenheit
          ? await _client!.convertToFahrenheit(request)
          : await _client!.convertToCelsius(request);

      setState(() {
        _result = '${response.value.toStringAsFixed(1)}°';
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _result = 'Error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
              colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thermostat,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Temperature\nConverter',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Main conversion card
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Card(
                        elevation: 8,
                        shadowColor: colorScheme.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.surface,
                                colorScheme.surface.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Input field
                                TextField(
                                  controller: _controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Temperature',
                                    labelStyle: TextStyle(color: colorScheme.primary),
                                    suffixText: _isCelsiusToFahrenheit ? '°C' : '°F',
                                    suffixStyle: theme.textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Conversion toggle with animated icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '°C',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: _isCelsiusToFahrenheit 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: _isCelsiusToFahrenheit 
                                              ? colorScheme.primary 
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      AnimatedRotation(
                                        turns: _isCelsiusToFahrenheit ? 0 : 0.5,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.swap_horiz,
                                          color: colorScheme.primary,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '°F',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: !_isCelsiusToFahrenheit 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: !_isCelsiusToFahrenheit 
                                              ? colorScheme.primary 
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Switch
                                Switch(
                                  value: !_isCelsiusToFahrenheit,
                                  onChanged: (value) {
                                    setState(() {
                                      _isCelsiusToFahrenheit = !value;
                                      _result = '';
                                    });
                                  },
                                  activeColor: colorScheme.primary,
                                ),
                                const SizedBox(height: 32),
                                
                                // Convert button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _convert,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.calculate,
                                                color: colorScheme.onPrimary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Convert',
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  color: colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                
                                // Result display
                                if (_result.isNotEmpty) ...[
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primaryContainer,
                                          colorScheme.secondaryContainer,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Result',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _result,
                                          style: theme.textTheme.displayLarge?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _isCelsiusToFahrenheit ? 'Fahrenheit' : 'Celsius',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Footer
                    const SizedBox(height: 32),
                    Text(
                      'Powered by gRPC & Flutter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}