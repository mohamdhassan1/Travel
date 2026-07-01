import 'package:firebase_core/firebase_core.dart';
import 'package:first_app/core/reposatories/plase_reposatory.dart';
import 'package:first_app/logic/Blocs/Login/login_bloc.dart';
import 'package:first_app/logic/Blocs/Register/register_bloc.dart';
import 'package:first_app/logic/Blocs/place/place_bloc.dart';
import 'package:first_app/presntation/screans/splashscrean.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => RegisterBloc()),
      BlocProvider(create: (_) => LoginBloc()),
      BlocProvider(create: (_) => PlaceBloc(PlaceRepository())),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
