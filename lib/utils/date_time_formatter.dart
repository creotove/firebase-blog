import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

dateTimeFormatter(Timestamp dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime.toDate());
}
