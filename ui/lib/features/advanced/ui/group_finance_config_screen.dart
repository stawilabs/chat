import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/group_finance_config.dart';
import 'widgets/calendar_step.dart';
import 'widgets/currency_step.dart';
import 'widgets/finance_summary_step.dart';
import 'widgets/group_type_step.dart';
import 'widgets/periodicity_step.dart';
import 'widgets/saving_amount_step.dart';

/// Stepper wizard for configuring financial group settings.
///
/// Returns a [GroupFinanceConfig] via Navigator.pop on save, or null on cancel.
class GroupFinanceConfigScreen extends StatefulWidget {
  const GroupFinanceConfigScreen({this.initialConfig, super.key});

  final GroupFinanceConfig? initialConfig;

  @override
  State<GroupFinanceConfigScreen> createState() =>
      _GroupFinanceConfigScreenState();
}

class _GroupFinanceConfigScreenState extends State<GroupFinanceConfigScreen> {
  int _currentStep = 0;

  GroupType? _groupType;
  String? _currency;
  PeriodType? _periodType;
  DateTime? _savingsStartDate;
  DateTime? _terminationDate;
  final _savingAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig;
    if (c != null) {
      _groupType = c.groupType;
      _currency = c.groupCurrency;
      _periodType = c.periodType;
      _savingsStartDate = c.groupSavingsDay;
      _terminationDate = c.terminationDate;
      if (c.periodicSaving != null) {
        _savingAmountController.text = c.periodicSaving!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _savingAmountController.dispose();
    super.dispose();
  }

  /// Build the dynamic list of steps based on selected group type
  List<Step> _buildSteps() {
    final steps = <Step>[];

    // Step 0: Group Type (always)
    steps.add(
      Step(
        title: const Text('Group Type'),
        content: GroupTypeStep(
          selected: _groupType,
          onChanged: (type) => setState(() {
            _groupType = type;
            // Reset periodicity fields when switching types
            if (!type.requiresPeriodicity) {
              _periodType = null;
              _savingsStartDate = null;
              _savingAmountController.clear();
            }
            if (!type.requiresTerminationDate) {
              _terminationDate = null;
            }
          }),
        ),
        isActive: _currentStep >= steps.length,
      ),
    );

    // Step 1: Currency (always)
    steps.add(
      Step(
        title: const Text('Currency'),
        content: CurrencyStep(
          selected: _currency,
          onChanged: (c) => setState(() => _currency = c),
        ),
        isActive: _currentStep >= steps.length,
      ),
    );

    // Conditional steps based on group type
    if (_groupType != null && _groupType!.requiresPeriodicity) {
      steps.add(
        Step(
          title: const Text('Periodicity'),
          content: PeriodicityStep(
            selected: _periodType,
            onChanged: (p) => setState(() => _periodType = p),
          ),
          isActive: _currentStep >= steps.length,
        ),
      );

      steps.add(
        Step(
          title: const Text('Start Date'),
          content: CalendarStep(
            label: 'Savings start date',
            subtitle: 'When should the first savings cycle begin?',
            selected: _savingsStartDate,
            onChanged: (d) => setState(() => _savingsStartDate = d),
          ),
          isActive: _currentStep >= steps.length,
        ),
      );

      steps.add(
        Step(
          title: const Text('Saving Amount'),
          content: SavingAmountStep(
            currency: _currency ?? '',
            controller: _savingAmountController,
          ),
          isActive: _currentStep >= steps.length,
        ),
      );
    }

    if (_groupType != null && _groupType!.requiresTerminationDate) {
      steps.add(
        Step(
          title: const Text('Termination Date'),
          content: CalendarStep(
            label: 'Termination date',
            subtitle: 'When should this group end?',
            selected: _terminationDate,
            onChanged: (d) => setState(() => _terminationDate = d),
          ),
          isActive: _currentStep >= steps.length,
        ),
      );
    }

    // Summary (always last)
    steps.add(
      Step(
        title: const Text('Summary'),
        content: FinanceSummaryStep(config: _buildConfig()),
        isActive: _currentStep >= steps.length,
      ),
    );

    return steps;
  }

  GroupFinanceConfig _buildConfig() => GroupFinanceConfig(
    groupType: _groupType ?? GroupType.voluntary,
    groupCurrency: _currency ?? '',
    periodType: _periodType,
    periodicSaving: double.tryParse(_savingAmountController.text),
    groupSavingsDay: _savingsStartDate,
    terminationDate: _terminationDate,
  );

  bool _canContinue() {
    if (_currentStep == 0) return _groupType != null;
    if (_currentStep == 1) return _currency != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    // Clamp current step to valid range when steps change
    if (_currentStep >= steps.length) {
      _currentStep = steps.length - 1;
    }

    final isLastStep = _currentStep == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialConfig != null
              ? 'Edit Finance Settings'
              : 'Finance Settings',
        ),
      ),
      body: Stepper(
        // Key forces rebuild when step count changes (Stepper asserts fixed length)
        key: ValueKey(steps.length),
        steps: steps,
        currentStep: _currentStep,
        onStepContinue: _canContinue()
            ? () {
                if (isLastStep) {
                  final config = _buildConfig();
                  if (config.isValid) {
                    Navigator.of(context).pop(config);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(config.validate().first),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                } else {
                  setState(() => _currentStep++);
                }
              }
            : null,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.of(context).pop();
          }
        },
        onStepTapped: (step) {
          if (step <= _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              FilledButton(
                onPressed: details.onStepContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: Text(isLastStep ? 'Save' : 'Continue'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: details.onStepCancel,
                child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
