
import 'package:expense_log/migrations/migration_2/expense_migration_1.dart';
import 'package:hive/hive.dart';


Future<void> hive_migrations_version_2() async{
  expense_data_type_migration2();
}

Future<void> checkAndRunMigration() async{
  final settingsBox = Hive.box('settingsBox');
  int  migrationVersion = settingsBox.get('migrationVersion',defaultValue: 1);

  //await Hive.boxExists('expenseBox')
  //migrationVersion < 2
  if(await Hive.boxExists('expenseBox') || migrationVersion < 2){
      await hive_migrations_version_2();
      await  settingsBox.put('migrationVersion' , 2);
  }
}