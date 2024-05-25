import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Method to format the timestamp
dateTimeFormatterTimeStamp(Timestamp dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime.toDate());
}

// Method to format the DateTime
dateTimeFormatter(DateTime dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime);
}
