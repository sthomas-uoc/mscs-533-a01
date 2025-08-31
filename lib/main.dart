import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MeasuresConverterApp());

class MeasuresConverterApp extends StatelessWidget {
  const MeasuresConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Measures Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const ConverterPage(title: 'Measures Converter'),
    );
  }
}

class ConverterPage extends StatefulWidget {
  final String title;

  const ConverterPage({super.key, required this.title});

  @override
  State<ConverterPage> createState() => _ConverterPage();
}

class _ConverterPage extends State<ConverterPage> {
  final inputController = TextEditingController();

  // Default from unit
  String _fromUnit = 'meter';

  // Default matching to unit
  String _toUnit = 'feet';

  // List of from units and possible target units
  var _fromMeasures = [
    Measure('feet', ['meter']),
    Measure('meter', ['feet', 'yard', 'mile']),
    Measure('kelvin', ['fahrenheit']),
    Measure('fahrenheit', ['kelvin']),
    Measure('kilogram', ['pound']),
    Measure('pound', ['kilogram']),
    Measure('liter', ['gallon']),
    Measure('gallon', ['liter']),
    Measure('square meter', ['square foot']),
    Measure('square foot', ['square meter']),
  ];

  // Track conversion formulae for each source and targets
  // Additional targets and formulae can be added with ease
  var _conversions = {
    'feet': {'meter': MultiplyEvaluator(0.3048)},
    'meter': {
      'feet': MultiplyEvaluator(3.28084),
      'yard': MultiplyEvaluator(1.09361),
      'mile': MultiplyEvaluator(0.000621371),
    },
    'kelvin': {
      'fahrenheit': CustomEvaluator([
        SubtractEvaluator(273.15),
        MultiplyEvaluator(9.0 / 5.0),
        AddEvaluator(32),
      ]),
    },
    'fahrenheit': {
      'kelvin': CustomEvaluator([
        SubtractEvaluator(32),
        MultiplyEvaluator(5.0 / 9.0),
        AddEvaluator(273.15),
      ]),
    },
    'kilogram': {'pound': MultiplyEvaluator(2.20462)},
    'pound': {'kilogram': MultiplyEvaluator(0.453592)},
    'liter': {'gallon': MultiplyEvaluator(0.264172)},
    'gallon': {'liter': MultiplyEvaluator(3.78541)},
    'square meter': {'square foot': MultiplyEvaluator(10.7639)},
    'square foot': {'square meter': MultiplyEvaluator(0.092903)},
  };

  // List of to units for the selected from unit. Initially set to the possible targets for the default from unit
  var _toMeasures = ['feet', 'yard', 'mile'];

  // String to store the formatted display text for the conversion output
  String _convertedValueDisplay = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text(widget.title))),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                style: Theme.of(context).textTheme.headlineMedium,
                'Value',
              ), // The label for user provided input
              SizedBox(height: 8),
              TextField(
                // Capture user input
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter value',
                ),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ), // Keyboard type set to numbers with decimals
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[-+]?[0-9]*\.?[0-9]*'),
                  ), // Formatter to allow only numbers, decimal, and sign
                ],
                controller:
                    inputController, // A controller to retrieve the value from the text field
              ),
              SizedBox(height: 16),
              Text(
                style: Theme.of(context).textTheme.headlineMedium,
                'From',
              ), // The label for from unit selection
              SizedBox(height: 8),
              DropdownButton(
                // Show list of from units
                // Initial Value
                value: _fromUnit,
                icon: const Icon(Icons.keyboard_arrow_down),
                isExpanded: true,

                // Map the measures to dropdown values
                items: _fromMeasures.map((Measure measure) {
                  return DropdownMenuItem(
                    value: measure.name,
                    child: Text(measure.name),
                  );
                }).toList(),
                // On selection of from measure, update the to measures to valid targets
                onChanged: (String? newValue) {
                  setState(() {
                    _fromUnit = newValue!; // Track the user selection
                    _toMeasures = _fromMeasures
                        .firstWhere((m) => m.name == newValue)
                        .targets;
                    _toUnit =
                        _toMeasures[0]; // Set the default selected to unit
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                style: Theme.of(context).textTheme.headlineMedium,
                'To',
              ), // The label for to unit selection
              SizedBox(height: 8),
              DropdownButton(
                // Initial Value
                value: _toUnit,
                icon: const Icon(Icons.keyboard_arrow_down),
                isExpanded: true,

                // Map the to measures
                items: _toMeasures.map((String items) {
                  return DropdownMenuItem(value: items, child: Text(items));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _toUnit = newValue!; // Set the user selected to unit
                  });
                },
              ),
              SizedBox(height: 16),
              FilledButton(
                // Button to perform the conversion
                onPressed: () => {
                  setState(() {
                    // Check that the input is actually a valie double
                    var parsedInput = double.tryParse(inputController.text);
                    if (null != parsedInput && parsedInput.isFinite) {
                      // Convert and format the text to display to user
                      _convertedValueDisplay =
                          '${inputController.text} $_fromUnit are ${(_conversions[_fromUnit]![_toUnit]!.evaluate(parsedInput))} $_toUnit';
                    } else {
                      _convertedValueDisplay =
                          "Enter a number to convert!"; // If user has not provided an input value, show the error.
                    }
                  }),
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(),
                ),
                child: Text("Convert"), // Button text
              ),
              SizedBox(height: 16),
              Text(_convertedValueDisplay.toString()), // Conversion result text
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps source and target measures
class Measure {
  String name;

  List<String> targets;

  Measure(this.name, this.targets);
}

/// Type to perform conversions by evaluation
abstract class Evaluator {
  /// Performs the evaluation
  double evaluate(double input);
}

/// Basic evaluator that multiples input with a defined multiplier
class MultiplyEvaluator implements Evaluator {
  double value;

  MultiplyEvaluator(this.value);

  @override
  double evaluate(double input) {
    return input * value;
  }
}

/// Basic evaluator that adds input with a defined value
class AddEvaluator implements Evaluator {
  double value;

  AddEvaluator(this.value);

  @override
  double evaluate(double input) {
    return input + value;
  }
}

/// Basic evaluator that subtracts a defined value from the
class SubtractEvaluator implements Evaluator {
  double value;

  SubtractEvaluator(this.value);

  @override
  double evaluate(double input) {
    return input - value;
  }
}

/// Basic evaluator that divides input with a defined divisor
class DivideEvaluator implements Evaluator {
  double value;

  DivideEvaluator(this.value);

  @override
  double evaluate(double input) {
    // Not handling divide by 0 as all inputs to the app are controlled
    return input / value;
  }
}

/// Applies evaluations in the order specified in the list of evaluations, output of previous evaluation being the input for the next one
class CustomEvaluator implements Evaluator {
  List<Evaluator> evaluators;

  CustomEvaluator(this.evaluators);

  @override
  double evaluate(double input) {
    var result = input;
    for (Evaluator e in evaluators) {
      result = e.evaluate(result);
    }

    return result;
  }
}
