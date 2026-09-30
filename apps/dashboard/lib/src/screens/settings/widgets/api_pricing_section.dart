import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';
import '../../../../l10n/app_localizations.dart';

class ApiPricingSection extends StatefulWidget {
  const ApiPricingSection({
    super.key,
    required this.repository,
    required this.sessions,
    required this.onChanged,
  });
  final PricingRepository repository;
  final OpenCodeSessionRepository sessions;
  final VoidCallback onChanged;
  @override
  State<ApiPricingSection> createState() => _ApiPricingSectionState();
}

class _ApiPricingSectionState extends State<ApiPricingSection> {
  PricingConfig _config = PricingConfig();
  List<String> _models = [];
  String? _selected, _mapping;
  final _fields = List.generate(5, (_) => TextEditingController());
  bool _invalid = false, _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final config = await widget.repository.readPricing();
    final sessions = await widget.sessions.readSessions();
    final models = <String>{
      ...ApiPriceCatalog.rates.keys,
      ...config.overrides.keys,
      ...config.mappings.keys,
    };
    for (final session in sessions) {
      for (final event in usageEventsForPricing(session)) {
        if (event.model != null) {
          models.add(PricingConfig.key(event.provider, event.model!));
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _config = config;
      _models = models.toList()..sort();
      _busy = false;
    });
    if (_selected == null && _models.isNotEmpty) _choose(_models.first);
  }

  void _choose(String key) {
    _selected = key;
    _mapping = _config.mappings[key];
    _invalid = false;
    final rate =
        _config.overrides[key] ?? ApiPriceCatalog.rates[_mapping ?? key];
    final values = [
      rate?.input,
      rate?.output,
      rate?.cachedInput,
      rate?.cacheWrite,
      rate?.cacheWrite1h,
    ];
    for (var i = 0; i < values.length; i++) {
      _fields[i].text = values[i]?.toString() ?? '';
    }
    setState(() {});
  }

  Future<void> _save({bool reset = false, bool mappingOnly = false}) async {
    final key = _selected;
    if (key == null) return;
    final overrides = Map<String, ApiRates>.of(_config.overrides);
    final mappings = Map<String, String>.of(_config.mappings);
    if (reset) {
      overrides.remove(key);
      mappings.remove(key);
    } else if (mappingOnly) {
      overrides.remove(key);
      if (_mapping == null) {
        mappings.remove(key);
      } else {
        mappings[key] = _mapping!;
      }
    } else {
      final values = _fields
          .map(
            (c) =>
                c.text.trim().isEmpty ? null : double.tryParse(c.text.trim()),
          )
          .toList();
      if (values[0] == null ||
          values[1] == null ||
          List.generate(5, (i) => i).any(
            (i) =>
                (_fields[i].text.trim().isNotEmpty && values[i] == null) ||
                (values[i] != null && (!values[i]!.isFinite || values[i]! < 0)),
          )) {
        setState(() => _invalid = true);
        return;
      }
      overrides[key] = ApiRates(
        input: values[0]!,
        output: values[1]!,
        cachedInput: values[2],
        cacheWrite: values[3],
        cacheWrite1h: values[4],
      );
      mappings.remove(key);
    }
    setState(() => _busy = true);
    try {
      final config = PricingConfig(overrides: overrides, mappings: mappings);
      await widget.repository.writePricing(config);
      if (!mounted) return;
      _config = config;
      _choose(key);
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = [
      l.usageInput,
      l.usageOutput,
      l.usageCacheRead,
      l.usageCacheWrite,
      l.usageCacheWrite1h,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.usagePricingTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l.usagePricingHelp),
        Text(l.usagePricingSnapshot(ApiPriceCatalog.version)),
        const SizedBox(height: 12),
        if (_models.isEmpty) Text(l.usagePricingNoModels),
        if (_models.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.usagePricingModel),
            items: _models
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(key, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _busy
                ? null
                : (key) {
                    if (key != null) _choose(key);
                  },
          ),
          const SizedBox(height: 12),
          Text(
            _config.overrides.containsKey(_selected) ||
                    _config.mappings.containsKey(_selected)
                ? l.usageCustomPrice
                : l.usagePricingPublished,
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('mapping-$_selected-$_mapping'),
            initialValue: _mapping ?? '',
            isExpanded: true,
            decoration: InputDecoration(labelText: l.usagePricingMapping),
            items: [
              DropdownMenuItem(value: '', child: Text(l.usageNoMapping)),
              ...ApiPriceCatalog.rates.keys
                  .where(
                    (k) => k.split('/').first == _selected?.split('/').first,
                  )
                  .map(
                    (key) => DropdownMenuItem(
                      value: key,
                      child: Text(key, overflow: TextOverflow.ellipsis),
                    ),
                  ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    _mapping = value == '' ? null : value;
                    _save(mappingOnly: true);
                  },
          ),
          const SizedBox(height: 12),
          Text(l.usagePricingRatesHelp),
          for (var i = 0; i < _fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: Key('api-rate-$i'),
                controller: _fields[i],
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: labels[i]),
              ),
            ),
          if (_invalid)
            Text(
              l.usagePricingInvalid,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => _save(),
                child: Text(l.usagePricingSave),
              ),
              TextButton(
                onPressed: _busy ? null : () => _save(reset: true),
                child: Text(l.usagePricingReset),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
