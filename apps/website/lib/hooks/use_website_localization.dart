import 'package:jaspr_hooks/jaspr_hooks.dart';

import '../localization.dart';

/// Owns component-local language state with the same initial locale on the
/// server and browser so static rendering and hydration stay compatible.
({Loc loc, void Function() toggleLanguage}) useWebsiteLocalization() {
  final locale = useState(Loc.en);

  return (
    loc: locale.value,
    toggleLanguage: () {
      locale.value = locale.value == Loc.en ? Loc.cs : Loc.en;
    },
  );
}
