import 'package:objectbox/objectbox.dart';

@Entity()
class WorkStation {
  @Id(assignable: true)
  int workStationId;
  double left;
  double top;

  WorkStation({
    required this.workStationId,
    required this.left,
    required this.top,
  });
}