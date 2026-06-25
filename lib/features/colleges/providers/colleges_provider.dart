import '../models/college.dart';
import '../services/colleges_service.dart';

class CollegesProvider {
  final CollegesService _service = CollegesService();

  Stream<List<College>> watchColleges() => _service.watchColleges();
}
