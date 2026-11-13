import 'package:firebase_core/firebase_core.dart';
import 'app/bujji_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const BujjiAIApp());
}
