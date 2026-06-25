import '../providers/colleges_provider.dart';
import '../models/college.dart';

class CollegesRepository {
  final CollegesProvider provider;

  CollegesRepository(this.provider);

  Stream<List<College>> watchColleges() => provider.watchColleges();
}
