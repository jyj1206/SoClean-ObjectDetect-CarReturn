import 'package:aiffel_thone/check_image.dart';
import 'package:aiffel_thone/check_valuable.dart';
import 'package:aiffel_thone/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CleanDialog extends StatelessWidget {
  const CleanDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: <Widget>[
          Text(
            '깨끗 반납 인증 완료!! \n크레딧이 지급되었습니다.',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
          SizedBox(height: 20.h),
          Image.asset('assets/image/clean.png'),
          SizedBox(height: 20.h),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('????', style: TextStyle(color: Colors.white), textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: Colors.green),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.white),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DirtyDialog extends StatelessWidget {
  const DirtyDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return AlertDialog(
      title: Column(
        children: <Widget>[
          Text(
            '깨끗이 청소해주셔서 감사합니다.\n다음에 다시 도전해 봐요...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
          SizedBox(height: 20.h),
          Image.asset('assets/image/sad.png'),
          SizedBox(height: 20.h),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('확인하기', style: TextStyle(color: Colors.white),textScaleFactor: 1,
              ),
              onPressed: () async {
                bool success = await controller.sendDirtyImageRequestToServer();
                if(success){
                  Get.to(const CheckImage());
                }
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: Colors.green),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.green),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}


class FailDialog extends StatelessWidget {
  const FailDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: <Widget>[
          Text(
            '정상적인 사진이 아니에요.\n다음에 다시 도전해 봐요...',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
          SizedBox(height: 20.h),
          Image.asset('assets/image/sad.png'),
          SizedBox(height: 20.h),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: Colors.green),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.green),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NothingDialog extends StatelessWidget {
  const NothingDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: <Widget>[
          Text(
            '아직 나온 결과가 없어요.\n잠시 후 다시 확인해 주세요.',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
          SizedBox(height: 20.h),
          Image.asset('assets/image/sad.png'),
          SizedBox(height: 20.h),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: Colors.green),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.green),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UploadDialog extends StatelessWidget {
  const UploadDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: <Widget>[
          Image.asset('assets/image/check.png'),
          SizedBox(height: 20.h),
          Text(
            '접수가 완료되었습니다.',
            style: TextStyle(
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            '인증이 처리되는데까지 접수일 부터 2-3일이 걸릴 수 있습니다..\n인증은 인증과 동시에 자동으로 크레딧이 지급됩니다.',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.grey,
                fontSize: 9.sp
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.white),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.offAllNamed('/');
                controller.resetState();
              },
            ),
          ),
        ],
      ),

    );
  }
}

class FoundValuable extends StatelessWidget {
  const FoundValuable({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: <Widget>[
          Text(
            '귀중품이 발견되었습니다.',
            style: TextStyle(
              fontSize: 23.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textScaleFactor: 1,
          ),
          SizedBox(height: 10.h),
          Text(
            '놓고가신 물건이 맞는지 확인해주세요.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textScaleFactor: 1,
          ),
          SizedBox(height: 20.h),
          Image.asset('assets/image/gift.png'),
          SizedBox(height: 20.h),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('확인하기', style: TextStyle(color: Colors.white),textScaleFactor: 1,
              ),
              onPressed: () async {
                bool success = await controller.sendDirtyImageRequestToServer();
                if(success){
                  Get.to(const CheckValuable());
                }
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: Colors.green),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.green),textScaleFactor: 1,
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),

    );
  }
}


class ClaimSuccess extends StatelessWidget {
  const ClaimSuccess({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: <Widget>[
          const Text(
            '신고가 접수되었습니다.\n깨끗한 공유를 위해\n빠르게 처리하겠습니다.',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            '차량의 상태를 신고해 주셔서 감사합니다.\n감사의 의미로 5,000크레딧을 지급해 드립니다.',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.grey,
                fontSize: 12
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Image.asset('assets/image/broom.png'),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Get.offAllNamed('/');
                controller.resetState();
              },
            ),
          ),
        ],
      ),

    );
  }
}

class ClaimValuable extends StatelessWidget {
  const ClaimValuable({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UploadPageController>();
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: <Widget>[
          const Text(
            '분실물이 주인을 찾아 갔어요!\n신고해 주셔서 감사합니다~',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            '분실물을 신고해 주셔서 감사합니다.\n감사의 의미로 5,000크레딧을 지급해 드립니다.',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.grey,
                fontSize: 12
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Image.asset('assets/image/gift.png'),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text('닫기', style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Get.offAllNamed('/');
                controller.resetState();
              },
            ),
          ),
        ],
      ),

    );
  }
}