import 'package:aiffel_thone/controller.dart';
import 'package:aiffel_thone/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';


class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UploadPageController controller = Get.put(UploadPageController(), permanent: false);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Get.offAllNamed('/');
                  controller.resetState();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 8, right: 30, bottom: 8).r,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('깨끗 반납 인증', style: TextStyle(fontFamily: 'Pretendard', fontSize: 23.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('가이드에 맞춰 깨끗한 차량 내부 사진을 남겨 주세요.', style: TextStyle(fontSize: 11.sp), textScaleFactor: 1,)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('사진 전송 후에는 수정할 수 없습니다.', style: TextStyle(fontSize: 11.sp), textScaleFactor: 1,)
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('촬영 예시', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),textScaleFactor: 1,)
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            const SectionSelector(),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  controller.handleScrollNotification(notification);
                  return true;
                },
              child: ListView.builder(
                controller: controller.scrollController,
                itemCount: controller.sections.length,
                itemBuilder: (context, index) {
                  return ImageSection(
                    sectionTitle: controller.sections[index],
                    imagePath: controller.getImagePath(index),
                    imageIndex: index,
                  );
                },
              ),
            ),
            ),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final localContext = context;
                    if (controller.selectedImages.length != 4) {
                      showDialog(
                        context: localContext,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('알림', style: TextStyle(fontSize: 15.sp),textScaleFactor: 1,),
                            content: Text('사진을 모두 촬영해 주세요.', style: TextStyle(fontSize: 11.sp),textScaleFactor: 1,),
                            actions: <Widget>[
                              TextButton(
                                child: Text('확인', style: TextStyle(fontSize: 11.sp),textScaleFactor: 1,),
                                onPressed: () {
                                  Get.back();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      bool success = await controller.uploadImagesRequestId();
                      if(success){
                        Get.dialog(
                            const UploadDialog(),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                    ),
                  ),
                  child: Text('깨끗 반납 인증 요청하기', style: TextStyle(fontSize: 12.sp),textScaleFactor: 1,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  final String sectionTitle;
  final String imagePath;
  final int imageIndex;

  const ImageSection({
    Key? key,
    required this.sectionTitle,
    required this.imagePath,
    required this.imageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return Container(
      height: 300,
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textScaleFactor: 1,
            ),

          ),
          Expanded(
            child: Center(
              child: Obx(() {
                final selectedImage = controller.selectedImages[imageIndex];
                return selectedImage == null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImagePlaceholder(imagePath: imagePath, imageIndex: imageIndex))
                    : Stack(
                  alignment: Alignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: 200, // 예시로 설정한 최대 높이
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(selectedImage.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(58, 69, 82, 1),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: (){
                              controller.selectedImages.remove(imageIndex);
                            },
                            icon: const Icon(Icons.delete, color: Colors.white),
                            iconSize: 20,
                          ),
                        )
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  final String imagePath;
  final int imageIndex;

  const ImagePlaceholder({
    Key? key,
    required this.imagePath,
    required this.imageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.black87,
              )
            ),
          ),
        ),
        IconButton(
          onPressed: () => controller.pickImage(imageIndex),
          icon: Image.asset('assets/image/camera.png',width: 50),
        )
      ],
    );
  }
}
class SectionSelector extends StatelessWidget {

  const SectionSelector({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controller.sections.asMap().entries.map((entry) {
            int idx = entry.key;
            bool isSelected = idx == controller.selectedSectionIndex.value;
            return GestureDetector(
              onTap: () => controller.scrollToIndex(idx),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.5),
                height: 50,
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.5,
                  child: AspectRatio(
                    aspectRatio: 5 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        controller.getImagePath(idx),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
class ImageSourceDialog extends StatelessWidget {
  final String sectionName;
  final String imagePath;

  const ImageSourceDialog({
    Key? key,
    required this.sectionName,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("$sectionName 사진 업로드", textAlign: TextAlign.center, style: TextStyle(fontSize: 18.sp),textScaleFactor: 1,),
      children: <Widget>[
        Column(
          children: [
            const Text('(예시)', textScaleFactor: 1,),
            SizedBox(height: 10.h),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(imagePath, height: 150)),
          ],
        ),
        const SizedBox(height: 10,),
        Center(child: Text('$sectionName${sectionName == "뒷 좌석" ? "이" : "가"} 정확히 보일 수 있도록 촬영해 주세요.', style: TextStyle(fontSize: 12.sp), textScaleFactor: 1,)),
        const SizedBox(height: 10,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SimpleDialogOption(
                onPressed: () => Get.back(result: ImageSource.camera),
                child: const Column(
                  children: [
                    Icon(Icons.camera_alt_outlined),
                    Text('직접 촬영')
                  ],
                )
            ),
            SimpleDialogOption(
                onPressed: () => Get.back(result: ImageSource.gallery),
                child: const Column(
                  children: [
                    Icon(Icons.image),
                    Text('사진 선택')
                  ],
                )
            ),
          ],
        )
      ],
    );
  }
}
