import 'package:objectbox/objectbox.dart';

@Entity()
class WorkStation {
  @Id(assignable: true)
  int id;
  String? workStationId;
  double left;
  double top;

  WorkStation({
    required this.id,
    this.workStationId,
    required this.left,
    required this.top,
  });
}