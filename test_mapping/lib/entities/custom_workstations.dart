import 'package:objectbox/objectbox.dart';

@Entity()
class CustomWorkStation {
  int id;

  String name;
  String imagePath;
  String type;
  String status;
  double left;
  double top;

  CustomWorkStation({
    this.id = 0,
    required this.name,
    required this.imagePath,
    required this.type,
    required this.status,
    required this.left,
    required this.top,
  });
}