import 'dart:ui';
import 'package:aiffel_thone/dialogs.dart';
import 'package:aiffel_thone/firebase_options.dart';
import 'package:aiffel_thone/controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'upload_page.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("백그라운드 메시지 처리.. ${message.notification!.body!}");
  RemoteNotification? notification = message.notification;
  if (notification != null) {
    FlutterLocalNotificationsPlugin().show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'high_importance_notification',
          importance: Importance.max,
        ),
      ),
    );
  }
}

void initializeNotification() async {
  Get.put(UploadPageController());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
      const AndroidNotificationChannel(
      'high_importance_channel',
      'high_importance_notification',
      importance: Importance.max
  ));
  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_launcher"),
  ));
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );


  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      FlutterLocalNotificationsPlugin().show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'high_importance_notification',
            importance: Importance.max,
          ),
        ),
      );
    }
  });
  Get.put(Controller());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);  // Firebase 초기화
  initializeNotification();
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, context) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          home: const MyHomePage(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.white, //
                brightness: Brightness.light),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold), // 'titleLarge'로 변경
              bodyMedium: TextStyle(fontFamily: 'Pretendard',), //
            ),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});


  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return Scaffold(
      backgroundColor: const Color(0xFF373F44),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 2,
                child: Image.asset('assets/image/logo.png')),
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.9,
                    child: ListTile(
                      tileColor: Colors.green,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      title: Text('깨끗 반납 인증', style: TextStyle(color: Colors.white, fontSize: 15.sp), textScaleFactor:1 ),
                      trailing: Icon(Icons.arrow_forward_ios_sharp, color: Colors.white, size: 20.sp),
                      onTap: () => _showModalBottomSheetForReturn(context),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.9,
                    child: ListTile(
                      tileColor: Colors.green,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      title: Text('결과 보기', style: TextStyle(color: Colors.white, fontSize: 15.sp), textScaleFactor:1 ),
                      trailing: Icon(Icons.arrow_forward_ios_sharp, color: Colors.white, size: 20.sp, ),
                      onTap: () async {
                        bool success = await controller.sendRequestIdToServer();
                        if(success) {
                          if(controller.cleanliness.value == 'pass'){
                            Get.dialog(
                                const CleanDialog(),
                            );
                          }else if(controller.cleanliness.value == 'dirty' || controller.cleanliness.value == 'fail') {
                            Get.dialog(
                                const DirtyDialog(),
                            );
                          }else if(controller.cleanliness.value == 'valuable'){
                            Get.dialog(
                                const FoundValuable()
                            );
                          }else{
                            Get.dialog(
                                const FailDialog()
                            );
                          }
                        } else {
                          Get.dialog(
                              const NothingDialog()
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  void _showModalBottomSheetForReturn(BuildContext context) {
    final expandedController = Get.find<Controller>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 이를 true로 설정하여 전체 화면의 70%를 차지하도록 할 수 있습니다.
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9, // 바텀 시트의 높이를 전체 화면의 70%로 설정
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20).r,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                  ),
                  Text(
                    '깨끗 반납 인증하고',
                    style: TextStyle(
                      fontSize: 24.sp, // 글꼴 크기
                      fontWeight: FontWeight.w600, // 굵은 글씨
                    ),
                      textScaleFactor:1,
                  ),
                  Text(
                    '5,000 크레딧 받아가세요!',
                    style: TextStyle(
                      fontSize: 24.sp, // 글꼴 크기
                      fontWeight: FontWeight.w600, // 굵은 글씨
                    ),
                    textScaleFactor:1,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '깨끗 반납 인증이 처음이신가요?',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600
                    ),
                    textScaleFactor:1,
                  ),
                  SizedBox(height: 20.h),
                  buildListTile('차량을 반납하기 전, 간단한 촬영을 통해 크레딧을 받을 수 있습니다.'),
                  buildListTile('앱 화면에서 실시간으로 촬영된 사진만 인증가능합니다.', highlightText: '실시간으로 촬영된 사진만 인증가능',),
                  buildListTile('차량을 반납하기 전 내부를 청소하고 가이드에 맞게 사진을 찍어주세요.'),
                  buildListTile('인증이 완료되면 크레딧을 드립니다.'),
                  Obx(() =>
                  expandedController.isExpanded.value ? Column(
                    children: [
                      buildListTile('운전석 매트, 조수석 매트, 컵홀더, 뒷자석 전체가 보이게 촬영하여 업로드 해주세요.'),
                      buildListTile('4장의 사진의 부위가 올바르지 않은 경우, 크레딧이 제공되지 않습니다.'),
                      buildListTile('귀중품이 잡힌 경우, 분실물 담당 부서로 전달되어 크레딧이 제공되지않습니다.'),
                      buildListTile('인증이 처리되는데 까지 접수일부터 2-3일이 걸릴 수 있습니다.'),
                      buildListTile('인증은 인증과 동시에 자동으로 크레딧이 제공됩니다.'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.grey, fontSize: 10.sp),textScaleFactor:1, ),
                          Text('차량이 확인되지 않을 경우 깨끗 반납 인증이 불가능합니다.', style: TextStyle(color: Colors.red,fontSize: 10.sp),textScaleFactor:1, )
                        ],
                      ),
                    )
                    ],
                  ) : Container(),
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: expandedController.toggleExpanded,
                      child: Obx(() => Text(
                        expandedController.isExpanded.value ? '더 자세히 보기 -' : '더 자세히 보기 +',
                        // ... 기타 스타일 설정 ...
                      )),
                      ),
                    ),
                  SizedBox(height: 20.h),
                  const Divider(),
                  SizedBox(height: 20.h),
                  Text(
                    '청소 이후 깨끗한 차량의 모습을 남겨주세요.',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                    ),
                    textScaleFactor: 1,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '깨끗 반납 인증 후 1일 이내 크레딧이 자동 지급됩니다.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp
                    ),
                    textScaleFactor: 1,
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 100.h, // 리스트의 높이 설정
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4, // 사진의 개수
                      itemBuilder: (context, index) {
                        // 이미지 경로 배열
                        List<String> imagePaths = [
                          'assets/image/front_left_sheet.jpg',
                          'assets/image/front_right_sheet.jpg',
                          'assets/image/rear_sheet.jpg',
                          'assets/image/cup_holder.jpg',
                        ];
                        return Container(
                          decoration:BoxDecoration(
                            border: Border.all(width: 2)
                          ),
                          margin: const EdgeInsets.only(right: 10),
                          child: Image.asset(
                            imagePaths[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => const UploadPage());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.grey),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text('깨끗 반납 인증하기', style: TextStyle(fontSize: 13.sp), textScaleFactor: 1,),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // 바텀 시트가 닫힐 때 실행될 로직
      if (expandedController.isExpanded.value) {
        expandedController.isExpanded.value = false;
      }
    });
  }

  Widget buildListTile(String text, {String? highlightText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey, fontSize: 10.sp),textScaleFactor:1, ),
          Expanded(
            child: highlightText == null
                ? Text(text, style: TextStyle(color: Colors.grey,fontSize: 10.sp),textScaleFactor:1, )
                : RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey,fontSize: 10.sp),
                children: _buildHighlightedText(text, highlightText),
              ),
            ),
          ),
        ],
      ),
    );
  }
  List<TextSpan> _buildHighlightedText(String text, String highlightText) {
    List<TextSpan> spans = [];
    int start = text.indexOf(highlightText);
    if (start >= 0) {
      if (start > 0) {
        spans.add(TextSpan(text: text.substring(0, start)));
      }
      spans.add(TextSpan(
        text: highlightText,
        style: const TextStyle(color: Colors.green),
      ));
      spans.add(TextSpan(text: text.substring(start + highlightText.length)));
    } else {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }

}


