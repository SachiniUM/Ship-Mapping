import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ObjectBoxStore{
  static late Store _store;

  static Store get instance {
    if (_store == null) {
      throw Exception("Store has not been initialized");
    }
    return _store;
  }

  static Future<void> initStore() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = Store(
      getObjectBoxModel(),
      directory: dir.path + '/objectbox',
    );
  }

  static void closeStore() {
    _store.close();
  }
}


// import 'package:path_provider/path_provider.dart';
//
// import '../objectbox.g.dart';
//
// class ObjectBoxStore{
//   static late Store _store;
//
//   static Store get instance {
//     if (_store == null) {
//       throw Exception("Store has not been initialized");
//     }
//     return _store;
//   }
//
//   static Future<void> initStore() async {
//     print("initStore");
//     final dir = await getApplicationDocumentsDirectory();
//     _store = Store(
//       getObjectBoxModel(),
//       directory: dir.path + '/objectbox',
//     );
//   }
//
//   static void closeStore() {
//     _store.close();
//   }
// }