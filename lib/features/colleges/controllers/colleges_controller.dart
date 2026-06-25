import 'package:get/get.dart';
import '../models/college.dart';
import '../repositories/colleges_repository.dart';

class CollegesController extends GetxController {
  final CollegesRepository repo;

  CollegesController(this.repo);

  Stream<List<College>> watchColleges() => repo.watchColleges();
}
