void main() {
  dynamic x = 'false';
  try {
    bool y = x as bool;
  } catch (e) {
    print(e.toString());
  }
}
