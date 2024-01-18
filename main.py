import argparse
from cv2 import imread
import warnings
from inference.predict import mmdetection_predict, yolov8_predict, ensemble_predict, denormalize_ensemble_prediction, openmax_predict
from inference.clean_rating import determine_clean_class
import sys

def parse_args():
    parser = argparse.ArgumentParser(description='main file')
    parser.add_argument('--image_path', help='image file path')
    parser.add_argument('--mmdet_cf_path', help='mmdetection config file path')
    parser.add_argument('--mmdet_path', help='mmdetection model path')
    parser.add_argument('--yolov8_path', help='yolov8 model path')
    parser.add_argument('--openmax_path', help='classfire model path')
    
    args = parser.parse_args()
    
    return args


def main():
    args = parse_args()
    
    # 이미지 불러오기
    img = imread(args.image_path)
    
    final_width = img.shape[1]
    final_height = img.shape[0]
    
    # openmax
    openmax_predictions = openmax_predict(img, args.openmax_path)
    if openmax_predictions == 3:
        print(f"{args.image_path} This is not a suitable image for model inference. Please check the image again and set it.")
        sys.exit()
    
    # mmdetection, yolov8 모델 추론
    mmdetection_prediction = mmdetection_predict(img, args.mmdet_cf_path, args.mmdet_path)
    yolov8_prediction = yolov8_predict(img, args.yolov8_path)
    
    # 추론 결과 ensemble 
    wbf_prediction = ensemble_predict(mmdetection_prediction, yolov8_prediction)
    
    # 정규화 해제
    final_result = denormalize_ensemble_prediction(wbf_prediction, final_width, final_height)
    
    # 청결도 분류기 실행
    # 0 : 'pending', 1 : 'clean', 2 : 'normal', 3 : 'dirty'
    class_result = determine_clean_class(final_result)
    
    print(final_result)
    print(class_result)
    

if __name__ == '__main__':
    warnings.filterwarnings("ignore")
    main()