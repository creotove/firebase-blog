import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

dateTimeFormatterTimeStamp(Timestamp dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime.toDate());
}

dateTimeFormatter(DateTime dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime);
}
