const List<String> _verbs = [
  'Review',
  'Plan',
  'Draft',
  'Update',
  'Finalize',
  'Schedule',
  'Organize',
  'Prepare',
  'Research',
  'Analyze',
  'Design',
  'Test',
  'Deploy',
  'Archive',
  'Summarize',
];

const List<String> _nouns = [
  'budget',
  'roadmap',
  'presentation',
  'invoice',
  'itinerary',
  'backlog',
  'proposal',
  'report',
  'meeting notes',
  'contract',
  'design mockups',
  'onboarding docs',
  'marketing plan',
  'sprint tasks',
  'client feedback',
  'vendor list',
  'expense report',
  'product spec',
  'user research',
  'release notes',
];

const List<String> _qualifiers = [
  'Q1',
  'Q2',
  'Q3',
  'Q4',
  'team',
  'client',
  'personal',
  'annual',
  'weekly',
  'quarterly',
  'North region',
  'EU launch',
  'mobile app',
  'website redesign',
  'holiday',
  'onboarding',
  'renewal',
  'follow-up',
  'kickoff',
  'retro',
];

const List<String> _categories = [
  'Work',
  'Personal',
  'Finance',
  'Health',
  'Travel',
  'Shopping',
  'Ideas',
  'Reference',
];

/// Deterministically enumerates every verb/noun/qualifier combination
/// (15 * 20 * 20 = 6,000 rows) instead of drawing from a seeded [Random] —
/// stronger reproducibility guarantee since there's no PRNG algorithm to
/// keep stable across Dart/Flutter versions.
List<Map<String, Object?>> generateMockSearchRows() {
  final rows = <Map<String, Object?>>[];
  for (var vi = 0; vi < _verbs.length; vi++) {
    for (var ni = 0; ni < _nouns.length; ni++) {
      for (var qi = 0; qi < _qualifiers.length; qi++) {
        final category = _categories[(vi + ni + qi) % _categories.length];
        rows.add({
          'title': '${_verbs[vi]} ${_nouns[ni]}',
          'subtitle': '${_qualifiers[qi]} · $category',
          'category': category,
        });
      }
    }
  }
  return rows;
}
