import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';

void main() {
  test('al cambiar de usuario, pedidos simultáneos comparten una sola base',
      () async {
    // Regresión (12.08): sync y el tema del negocio pedían la base a la vez
    // tras el login de otro usuario; cada uno abría su `AppDatabase` sobre el
    // mismo archivo y SQLite respondía "database is locked".
    var user = 'owner';
    final opened = <String>[];
    final holder = LocalDatabaseHolder(
      currentUserId: () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return user;
      },
      open: (id) {
        opened.add(id);
        return NativeDatabase.memory();
      },
    );

    final first = await holder.require();
    user = 'employee';
    final results = await Future.wait<AppDatabase>(
        [for (var i = 0; i < 5; i++) holder.require()]);

    expect(opened, ['owner', 'employee']);
    expect(results.toSet(), hasLength(1));
    expect(identical(results.first, first), isFalse);
    await holder.close();
  });

  test('un error al leer la sesión no bloquea los pedidos siguientes',
      () async {
    var fail = true;
    final holder = LocalDatabaseHolder(
      currentUserId: () async {
        if (fail) throw StateError('sin almacenamiento');
        return 'owner';
      },
      open: (_) => NativeDatabase.memory(),
    );

    await expectLater(holder.current(), throwsStateError);
    fail = false;
    expect(await holder.current(), isNotNull);
    await holder.close();
  });
}
