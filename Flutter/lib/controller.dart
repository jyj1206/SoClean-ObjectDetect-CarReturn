import 'dart:io';
import 'dart:typed_data';
import 'package:aiffel_thone/upload_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class Controller extends GetxController{
  var isExpanded = false.obs;

  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }
}


class UploadPageController extends GetxController {
  var selectedImages = <int, XFile?>{}.obs;
  var imageSizes = <int, Size>{}.obs;
  var imageFilePath = <int, File?>{}.obs;
  var selectedSectionIndex = 0.obs;
  var isSectionSelectedByUser = true.obs;
  var detectionsPerImage = <int, List<Map<String, dynamic>>>{}.obs;
  var classLabels = <String, String>{}.obs;
  var cleanliness = ''.obs;
  var token = "".obs;
  var images = <Image>[].obs;
  RxString korValue = ''.obs; // 추가된 코드
  final serverUrl = ''; //your url address

  void updateIndexToKey(int index) {
    String? key = indexToKey[index];
    updateKorValue(key!);
  }


  void updateKorValue(String key) {
    korValue.value = engToKor[classLabels[key]] ?? '오류가 발생했습니다.';
  }

  final Map<String, String> engToKor = {
    'normal': '보통',
    'clean': '깨끗',
    'dirty': '지저분',
    'pending': '귀중품'
  };

  final Map<int, String> indexToKey = {
    0: 'driver_seat_mat',
    1: 'passenger_seat_mat',
    2: 'rear_seat',
    3: 'cup_holder',
  };


  final ScrollController scrollController = ScrollController();

  final List<String> sections = [
    '운전석 매트',
    '조수석 매트',
    '뒷 좌석',
    '컵홀더',
  ];

  void getMyDeviceToken() async {
    token.value = (await FirebaseMessaging.instance.getToken())!;
  }

  String getImagePath(int index) {
    const imagePaths = [
      'assets/image/front_left_sheet.jpg',
      'assets/image/front_right_sheet.jpg',
      'assets/image/rear_sheet.jpg',
      'assets/image/cup_holder.jpg',
    ];
    return imagePaths[index];
  }

  void clearImages() {
    selectedImages.clear();
  }

  @override
  void onInit() {
    getMyDeviceToken();
    requestPermission();
    super.onInit();
  }
  @override
  void onClose() {
    clearImages();
    super.onClose();
  }

  Future<void> pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final source = await Get.dialog<ImageSource>(
      ImageSourceDialog(sectionName: sections[index], imagePath: getImagePath(index)),
    );
    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final File imageFile = File(image.path);
        imageFilePath[index] = imageFile;
        final decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
        imageSizes[index] = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      }
      selectedImages[index] = image;
    }
  }

  void resetState() {
    selectedImages.clear();
    selectedSectionIndex.value = 0;
  }

  void scrollToIndex(int index) {
    selectedSectionIndex.value = index;
    isSectionSelectedByUser.value = false;
    final position = index * 300.0;
    // GetX를 사용하여 스크롤 컨트롤러에 접근
    scrollController.animateTo(
      position,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  void handleScrollNotification(ScrollNotification notification) {
    if (isSectionSelectedByUser.value) {
      if (notification is ScrollUpdateNotification) {
        int currentIndex = (notification.metrics.pixels / 300.0).round();
        bool isAtEnd = notification.metrics.pixels == notification.metrics.maxScrollExtent;
        if (isAtEnd) {
          currentIndex = sections.length - 1;
        }
        if (currentIndex != selectedSectionIndex.value && currentIndex < sections.length) {
          selectedSectionIndex.value = currentIndex;
        }
      }
    } else {
      if (notification is ScrollEndNotification) {
        isSectionSelectedByUser.value = true;
      }
    }
  }

  Future<bool> uploadImagesRequestId() async {
    var uri = Uri.parse('$serverUrl/uploadrequestid');
    print(uri);
    var request = http.MultipartRequest('POST', uri);

    if (token.isNotEmpty) {
      request.fields['token'] = token.value;
    }

    var orderedKeys = selectedImages.keys.toList()..sort();
    for (var index in orderedKeys) {
      var image = selectedImages[index];
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      print(response.body);
      Map<String, dynamic> responseBody = json.decode(response.body);
      String requestId = responseBody['request_id'];
      saveRequestId(requestId);
      return true;
    } else {
      print('Image upload failed');
      return false;
    }
  }


  Future<void> saveRequestId(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('check_clean_Id', requestId);
    checkAllSavedData();
  }


  Future<void> checkAllSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // SharedPreferences에 저장된 모든 키를 가져옵니다.
    Set<String> keys = prefs.getKeys();

    // 각 키에 대한 값을 검색하고 출력합니다.
    for (String key in keys) {
      Object? value = prefs.get(key);
      print('$key: $value');
    }
  }

  Future<bool> sendRequestIdToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final requestId = prefs.getString('check_clean_Id') ?? '';
    checkAllSavedData();
    if (requestId.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$serverUrl/requestresult'),
          body: {'request_id': requestId},
        );

        if (response.statusCode == 200) {
          print('Request ID sent successfully');
          var data = json.decode(response.body);
          if (data != null) {
            // class_labels 처리
            if (data['class_labels'] != null) {
              classLabels.value = Map<String, String>.from(data['class_labels']);
            }

            // cleanliness 처리
            if (data['cleanliness'] != null) {
              cleanliness.value = data['cleanliness'];
            }

            // predictions 처리
            if (data['predictions'] != null) {
              List<dynamic> predictions = data['predictions'];

              for (int i = 0; i < predictions.length; i++) {
                var prediction = predictions[i];

                List<Map<String, dynamic>> detectionData = [];

                if (prediction['bboxes'] != null) {
                  for (int j = 0; j < prediction['bboxes'].length; j++) {
                    var bbox = prediction['bboxes'][j];
                    var label = prediction['labels'][j];
                    var score = prediction['scores'][j];

                    detectionData.add({
                      'bbox': bbox,
                      'label': label,
                      'score': score,
                    });
                  }
                }

                detectionsPerImage[i] = detectionData;
              }
            }
          }

          return true;
        } else {
          print('Failed to send request ID. Status code: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        print('Error sending request ID: $e');
        return false;
      }
    } else {
      print('No request ID found');
      return false;
    }
  }

  Map<String, String> reorderLabels() {
    return {
      'driver_seat_mat': classLabels['driver_seat_mat']!,
      'passenger_seat_mat': classLabels['passenger_seat_mat']!,
      'rear_seat': classLabels['rear_seat']!,
      'cup_holder': classLabels['cup_holder']!,
    };
  }

  var imageData = Rx<Uint8List?>(null);

  Future<bool> sendValuableImageRequestToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final requestId = prefs.getString('check_clean_Id') ?? '';
    if (requestId.isEmpty) {
      print('No request ID found');
      return false;
    }

    final reorderedLabels = reorderLabels(); // reorderLabels 함수의 정의가 필요
    final pendingIndex = reorderedLabels.keys.toList().indexWhere((key) => reorderedLabels[key] == 'pending');
    print(classLabels);
    if (pendingIndex == -1) {
      print('No pending item found');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/get_image'),
        body: {
          'request_id': requestId,
          'number': pendingIndex.toString(),
        },
      );

      if (response.statusCode == 200) {
        imageData.value = response.bodyBytes;
        return true;
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending request: $e');
      return false;
    }
  }

  Future<bool> sendDirtyImageRequestToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final requestId = prefs.getString('check_clean_Id') ?? '';
    print(requestId);
    if (requestId.isEmpty) {
      print('No request ID found');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/get_images'),
        body: {
          'request_id': requestId,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> imageStrings = jsonDecode(response.body);
        images.value = imageStrings.map((imageString) {
          return Image.memory(base64Decode(imageString));
        }).toList();
        print(images);
        return true;
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending request: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

}


class ImageViewerController extends GetxController {
  var currentIndex = 0.obs;

  void setCurrentIndex(int index) {
    currentIndex.value = index;
    Get.find<UploadPageController>().updateIndexToKey(index);
  }
}