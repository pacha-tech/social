import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTimestamp(Timestamp timestamp) {
    return DateFormat('HH:mm').format(timestamp.toDate());
  }
}