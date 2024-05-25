// For calculating the reading time of a given content
int calculateReadingTime(String content) {
  final wordCount = content.split(RegExp(r'\s+')).length;

  final readingTime = wordCount / 225;

  return readingTime.ceil();
}
