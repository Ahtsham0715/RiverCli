final files = {
  // api request representable
  'lib/data/repositories/authentication_repository.dart': '''
class ProfileRepository{
  // late APIProvider apiClient;

  // ProfileRepository() {
  //   apiClient = APIProvider();
  // }

}
''',
  // api request representable
  'lib/data/provider/network/api_request_representable.dart': '''
enum HTTPMethod { get, post, delete, put, patch }

extension HTTPMethodString on HTTPMethod {
  String get string {
    switch (this) {
      case HTTPMethod.get:
        return "get";
      case HTTPMethod.post:
        return "post";
      case HTTPMethod.delete:
        return "delete";
      case HTTPMethod.patch:
        return "patch";
      case HTTPMethod.put:
        return "put";
    }
  }
}

abstract class APIRequestRepresentable {
  String get url;
  String get endpoint;
  String get path;
  HTTPMethod get method;
  Map<String, String>? get headers;
  Map<String, String>? get query;
  dynamic get body;
  Future request();
}
''',
  // api provider
  'lib/data/provider/network/api_provider.dart': '''
''',
  // api endpoints
  'lib/data/provider/network/api_endpoints.dart': '''
class ApiEndPoints {

    static String baseUrl = ""; // your base url here
     static String get login => "login/";
     static String get register => "register/";

}
''',

  // models file
  'lib/data/models/user_model.dart': '''
// class User {
//   final String id;
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String phoneNumber;
//   final String avatarUrl;
//   final bool isActive;

//   User({
//     this.id = '',
//     this.firstName = '',
//     this.lastName = '',
//     this.email = '',
//     this.phoneNumber = '',
//     this.avatarUrl = '',
//     this.isActive = true,
//   });

//   // Method to convert the User object into a JSON map
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'firstName': firstName,
//       'lastName': lastName,
//       'email': email,
//       'phoneNumber': phoneNumber,
//       'avatarUrl': avatarUrl,
//       'isActive': isActive,
//     };
//   }

//   // Factory constructor to create a User object from a JSON map
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'] ?? '',
//       firstName: json['firstName'] ?? '',
//       lastName: json['lastName'] ?? '',
//       email: json['email'] ?? '',
//       phoneNumber: json['phoneNumber'] ?? '',
//       avatarUrl: json['avatarUrl'] ?? '',
//       isActive: json['isActive'] ?? true,
//     );
//   }

 
// }

''',
  // utils file
  'lib/app/utils.dart': '''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {

 static DateTime convertDateStingToDateTime(dateString){
    DateFormat format = DateFormat('d-M-yyyy');
    DateTime date = format.parse(dateString);
    return date;
  }

  // static showToast({required String message, int time = 2}) {
  //   Fluttertoast.showToast(
  //       msg: message,
  //       timeInSecForIosWeb: time,
  //       backgroundColor: AppColors.black,
  //       textColor: Colors.white,

  //       gravity: ToastGravity.BOTTOM,
  //       toastLength: Toast.LENGTH_SHORT);
  // }

}
''',

  // extensions file
  'lib/app/extensions/extensions.dart': '''

import 'package:flutter/cupertino.dart';

extension SizeBox on num
{
  SizedBox get height => SizedBox(height: toDouble(),);
  SizedBox get width => SizedBox(width: toDouble(),);
}
''',

  // Global variables files
  'lib/app/config/global_vars.dart': '''
class Globals {
  static String authToken = "";
  static String fcmToken = "";
  static String? deviceId;
  static String? deviceName;
  static String? loginDevice;
  // static UserModel? user;
  static String? language;
  static String? appVersion;
  static String? buildNumber;
  static String dummyImage = '';
}
''',
  // text styles files
  'lib/app/config/app_text_styles.dart': '''
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle regular = const TextStyle();
  static TextStyle headingExtraLarge = TextStyle(
      fontSize: 26.sp,
      fontFamily: 'Poppins-800',
      color: AppColors.primary,
      overflow: TextOverflow.ellipsis);
  static TextStyle primaryClrHeading = TextStyle(
      fontSize: 15.sp,
      fontFamily: 'Poppins-600',
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      overflow: TextOverflow.ellipsis);
  static TextStyle heading = TextStyle(
      fontSize: 17.sp,
      fontFamily: 'Poppins-600',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);

  static TextStyle semiBold = TextStyle(
      fontSize: 12.sp,
      fontFamily: 'Poppins-600',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);

  static TextStyle bodyText = TextStyle(
      fontSize: 12.sp,
      fontFamily: 'Poppins-400',
      color: AppColors.white,
      overflow: TextOverflow.ellipsis);
  static const TextStyle bodyTextBold = TextStyle(
      fontSize: 16,
      fontFamily: 'Poppins-500',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);
  static TextStyle mediumHeading = TextStyle(
      fontSize: 16.sp,
      fontFamily: 'Poppins-500',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);
  static TextStyle twentySemiBoldText = TextStyle(
    fontSize: 15.sp,
    fontFamily: 'Poppins-600',
    color: AppColors.black,
    overflow: TextOverflow.ellipsis,
  );
  static TextStyle twentyNormalText = TextStyle(
      fontSize: 15.sp,
      fontFamily: 'Poppins-400',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);
  static const TextStyle hintText = TextStyle(
      fontSize: 14,
      fontFamily: 'Poppins-400',
      color: AppColors.hint,
      overflow: TextOverflow.ellipsis);
  static TextStyle normalText = const TextStyle(
      fontSize: 14,
      fontFamily: 'Poppins-400',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);
  static TextStyle small = TextStyle(
      fontSize: 9.sp,
      fontFamily: 'Poppins-500',
      color: AppColors.white,
      overflow: TextOverflow.ellipsis);
  static TextStyle dashboardHeading = TextStyle(
      fontSize: 13.sp,
      fontFamily: 'Poppins-700',
      color: AppColors.black,
      overflow: TextOverflow.ellipsis);
}
''',
  // constants file
  'lib/app/config/app_constants.dart': '''''',

  // colors file
  'lib/app/config/app_colors.dart': '''
import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black05 = Color(0xFF050505);
  static const Color grey6B = Color(0xFF65676B);
  static const Color trans = Colors.transparent;
  static const Color primary = Color(0xFF0866FF);
  static const Color primary5FF = Color(0xFFEBF5FF);
  static const Color secondary = Color(0xFF65676B);
 
  static const Color tertiary = Color(0xFF27C4F4);
  static const Color inputfield = Color(0xFFF5F5FA);
  static const Color inputBorder = Color(0xFFE9EAF0);
  static const Color backgroundShadow = Color(0xFFF7F7FB);
  static const Color hint = Color(0xFF6C6C6C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xffFFED8F), // Start color
      Color(0xff1E61FF), // End color
    ],
    begin: Alignment.centerRight, // Gradient direction
    end: Alignment.centerLeft,
  );

}
''',
  // HomeController file
  'lib/presentation/home/controllers/home_controller.dart': '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeController extends StateNotifier<int> {
  HomeController() : super(0){
  onInit();
  }

  void onInit() {
    // Perform initialization logic here
    print('Controller initialized');
  }
  void increment() => state++;
  void decrement() {
    if (state > 0) state--;
  }
}
''',

  // Updated HomeView file
  'lib/presentation/home/views/home_view.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bindings/home_binding.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home View')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Counter display
            Consumer(
              builder: (context, ref, _) {
                final counter = ref.watch(homeControllerProvider);
                return Text(
                  'Counter: \$counter',
                  style: Theme.of(context).textTheme.headline4,
                );
              },
            ),
            const SizedBox(height: 16),
            // Buttons to update the counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final controller = ref.read(homeControllerProvider.notifier);
                    return ElevatedButton(
                      onPressed: controller.decrement,
                      child: const Text('-'),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final controller = ref.read(homeControllerProvider.notifier);
                    return ElevatedButton(
                      onPressed: controller.increment,
                      child: const Text('+'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
''',

  // HomeBinding file
  'lib/presentation/home/bindings/home_binding.dart': '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/home_controller.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, int>((ref) {
  return HomeController();
});
''',

  // AppRoutes file
  'lib/app/routes/app_routes.dart': '''
class AppRoutes {
  static const String home = '/home';
}
''',

  // RoutePage file
  'lib/app/routes/route_page.dart': '''
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../presentation/home/views/home_view.dart';

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      name: AppRoutes.home,
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
  ],
);
''',

  // Main file
  'lib/main.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/route_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: router,
    );
  }
}
''',
};
