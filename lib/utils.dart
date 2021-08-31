List<String> StringSort(List<String> input) {
  input.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return input;
}
