extension MapEntryIndex<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(int index, MapEntry<K, V> entry) f) sync* {
    int i = 0;
    for (final e in this) {
      yield f(i, e);
      i++;
    }
  }
}
