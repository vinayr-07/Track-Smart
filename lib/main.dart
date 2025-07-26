import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/student_viewmodel.dart';
import 'repositories/student_repository.dart';
import 'screens/main_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudentViewModel(StudentRepository()),
      child: Consumer<StudentViewModel>(
        builder: (context, viewModel, child) {
          return MaterialApp(
            title: 'Track Smart',
            debugShowCheckedModeBanner: false,
            theme: ThemeService.getTheme(viewModel.themePreference),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
