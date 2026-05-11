/// Shared package metadata and privacy defaults for the OpenSpent workspace.
final class OpenSpentInfo {
  const OpenSpentInfo._();

  static const String productName = 'OpenSpent';
  static const bool isLocalOnly = true;

  static const List<String> persistedMetadataAllowlist = <String>[
    'modelName',
    'inputTokens',
    'outputTokens',
    'totalCostUsd',
    'createdAt',
    'subagentCategory',
  ];

  static const List<String> sensitiveFieldsDenylist = <String>[
    'prompt',
    'state.input',
    'state.output',
    'state.error',
  ];

  static const List<String> ingestedSessionFieldAllowlist = <String>[
    'id',
    'modelName',
    'inputTokens',
    'outputTokens',
    'totalCostUsd',
    'createdAt',
    'subagentCategory',
  ];

  static const List<String> supportedSubagentCategories = <String>[
    'visual-engineering',
    'artistry',
    'ultrabrain',
    'deep',
    'quick',
    'unspecified-low',
    'unspecified-high',
    'writing',
  ];
}
