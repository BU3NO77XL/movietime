class MyListState {
  MyListState._();

  static const defaultName = 'Must watch ✨';

  static bool hasCreatedList = false;
  static String listName = defaultName;

  static void createList(String name) {
    final normalized = name.trim();
    listName = normalized.isEmpty ? defaultName : normalized;
    hasCreatedList = true;
  }
}
