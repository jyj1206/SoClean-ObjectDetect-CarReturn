import argparse
from cv2 import imread
import cv2
import os
from inference.predict import mmdetection_predict, yolov8_predict, ensemble_predict, denormalize_ensemble_prediction, openmax_predict
from inference.clean_rating import determine_clean_class, determine_vehicle_cleanlinesss
from inference.predict_list import mmdetection_list_predict, yolov8_list_predict, ensemble_list_predict, openmax_list_predict
import sys
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def image_pipeline(image_path, mmdetection_config_file, mmdetection_checkpoint_file, yolov8_checkpoint_file, classfire_checkpoint_file):
    # 이미지 불러오기
    img = imread(image_path)
    
    final_width = img.shape[1]
    final_height = img.shape[0]
    
    #open max
    openmax_predictions = openmax_predict(img, classfire_checkpoint_file)

    if openmax_predictions == 3:
        print(f"{image_path} This is not a suitable image for model inference. Please check the image again and set it.")
        sys.exit()
        
    #mmdetection, yolov8 모델 추론
    mmdetection_prediction = mmdetection_predict(img, mmdetection_config_file, mmdetection_checkpoint_file)
    yolov8_prediction = yolov8_predict(img, yolov8_checkpoint_file)
    
    #추론 결과 ensemble 
    wbf_prediction = ensemble_predict(mmdetection_prediction, yolov8_prediction)
    
    #정규화 해제
    final_result = denormalize_ensemble_prediction(wbf_prediction, final_width, final_height)
    
    #청결도 분류기 실행
    #0 : 'pending', 1 : 'clean', 2 : 'normal', 3 : 'dirty'
    class_result = determine_clean_class(final_result)
    
    return final_result, class_result
  
def draw_bounding_boxes_on_image(image, predictions):
    label_map = {
        0: '가방',
        1: '병',
        2: '카페 컵',
        3: '캔',
        4: '오염',
        5: '열쇠',
        6: '먼지',
        7: '클린 티슈',
        8: '얼룩',
        9: '쓰레기',
        10: '분실물'
    }

    # Convert the OpenCV image (BGR) to a PIL image (RGB)
    image_pil = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(image_pil)
    
    font_path = 'NanumGothic.ttf'
    
    if not os.path.exists(font_path):
        font_path = '../NanumGothic.ttf'

    if not os.path.exists(font_path):
        raise Exception(f"Font file not found: {font_path}")
    
    font = ImageFont.truetype(font_path, 30)

    for label, score, bbox in zip(predictions['labels'], predictions['scores'], predictions['bboxes']):
        xmin, ymin, xmax, ymax = bbox
        label_str = label_map.get(label, 'Unknown')

        # Draw the bounding box using PIL
        draw.rectangle([(xmin, ymin), (xmax, ymax)], outline=(0, 255, 0), width=2)

        # Draw the text
        text = label_str
        draw.text((xmin, ymin - 20), text, fill=(0, 255, 0), font=font)

    # Convert the PIL image back to an OpenCV image
    return cv2.cvtColor(np.array(image_pil), cv2.COLOR_RGB2BGR)

  
def four_image_list_pipeline(image_dir, user_num, mmdetection_config_file, mmdetection_checkpoint_file, yolov8_checkpoint_file, classfire_checkpoint_file):
    # 운전석 매트, 조수석 매트, 뒷자석, 컵홀더
    image_list = []
    file_names = ['driver_seat_mat', 'passenger_seat_mat', 'rear_seat', 'cup_holder']
    valid_extensions = ['.jpg', '.jpeg', '.png']
    
    for file_name in file_names:
        valid_file_found = False
        
        for ext in valid_extensions:
            file_path = os.path.join(image_dir, user_num, f"{file_name}{ext}")

            if os.path.isfile(file_path):
                image_list.append(file_path)
                valid_file_found = True
                break

        assert valid_file_found, f"Error: {file_name} not found with a valid extension in {os.path.join(image_dir, user_num)} directory."

    final_widths = []
    final_heights = []
    for image_path in image_list:
        img = imread(image_path)
        final_widths.append(img.shape[1])
        final_heights.append(img.shape[0])
    
    final_result_list = []  
    class_result_list = []
    processed_images = [] 
    
    ### openmax 
    openmax_predictions  = openmax_list_predict(image_list, classfire_checkpoint_file)
    y_labels = [2, 2, 0, 1]
    
    if openmax_predictions != y_labels:
        cls_mapping = {0: 'rear_seat', 1: 'cup_holder', 2: 'mat', 3: 'out'}
        file_names = ['driver_seat_mat', 'passenger_seat_mat', 'rear_seat', 'cup_holder']

        cls_results = {}

        for pred, true_label, file_name in zip(openmax_predictions, y_labels, file_names):
            predicted_class = cls_mapping.get(pred, 'Unknown')

            cls_results[file_name] = predicted_class
        
        print('openmax fail.....')
        
        return {
            'predictions': [{'labels': [], 'scores': [], 'bboxes': []} for _ in range(4)],
            'class_labels': cls_results,
            'cleanliness': 'error'
        }
    
    mmdetection_predictions = mmdetection_list_predict(image_list, mmdetection_config_file, mmdetection_checkpoint_file)
    yolov8_predictions = yolov8_list_predict(image_list, yolov8_checkpoint_file)
    wbf_predictions = ensemble_list_predict(mmdetection_predictions, yolov8_predictions)

    for wbf_prediction, final_width, final_height, image_path in zip(wbf_predictions, final_widths, final_heights, image_list):
        final_result = denormalize_ensemble_prediction(wbf_prediction, final_width, final_height)
        final_result_list.append(final_result)
        class_result_list.append(determine_clean_class(wbf_prediction))
       
        img = cv2.imread(image_path)
        processed_img = draw_bounding_boxes_on_image(img, final_result)
        processed_images.append(processed_img)
    
        saved_image_paths = []
    for i, processed_img in enumerate(processed_images):
        save_path = os.path.join(image_dir, user_num, f"processed_image_{i}.jpg")
        cv2.imwrite(save_path, processed_img)
        if not cv2.imwrite(save_path, processed_img):
            print("Error saving image")
        saved_image_paths.append(save_path)
	
    
    label_mapping = {0: 'pending', 1: 'clean', 2: 'normal', 3: 'dirty'}
    class_result_label_list = [label_mapping[result] for result in class_result_list]
    
    cleanliness_result = determine_vehicle_cleanlinesss(class_result_label_list)
    
    return {
        'predictions': final_result_list,
        'class_labels': dict(zip(file_names, class_result_label_list)),
        'cleanliness': cleanliness_result
    }
