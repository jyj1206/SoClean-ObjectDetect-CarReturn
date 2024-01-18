import sys
sys.path.append('./mmdetection')
# sys.path.append('./openmax')

from cv2 import resize
from mmdet.apis import DetInferencer
from ultralytics import YOLO
from ensemble_boxes import weighted_boxes_fusion

import warnings
warnings.filterwarnings("ignore")

# js import
import os
import numpy as np
import cv2
from statistics import mean

import torch
import torchvision
import torchvision.transforms as transforms

from scipy import stats

def mmdetection_predict(img, config_file, checkpoint_file, device = 'cpu:0', pred_score_thr=0.4):
    mmdetection_img = resize(img, (1333, 800))
    
    inferencer = DetInferencer(config_file, checkpoint_file, device)
    
    result = inferencer(mmdetection_img, pred_score_thr = pred_score_thr)

    prediction = result['predictions'][0]
    
    labels = prediction['labels']
    scores = prediction['scores']
    boxes = prediction['bboxes']

    idx = next((i for i, score in enumerate(scores) if score < pred_score_thr), None)

    if idx is not None:
        labels = labels[:idx]
        scores = scores[:idx]
        boxes = boxes[:idx]
        
    mmdetection_prediction  = {
    'labels' : labels,
    'scores' : scores,
    'bboxes' : boxes
    }
    
    return mmdetection_prediction


def yolov8_predict(img, checkpoint_file, conf = 0.4):
    yolov8_img = resize(img, (640, 640))
    
    model = YOLO(checkpoint_file)

    result = model(yolov8_img, conf = conf)
    box_info = result[0].boxes
    
    yolov8_prediction = {
        'labels': [int(label) for label in box_info.cls.tolist()],
        'scores': box_info.conf.tolist(),
        'bboxes': box_info.xyxy.tolist()
    }

    return yolov8_prediction


def normalize_bboxes(bboxes, img_width, img_height):
    normalized_bboxes = []

    for bbox in bboxes:
        xmin, ymin, xmax, ymax = bbox

        # 가로, 세로 크기에 따른 비율 계산
        x_scale = 1.0 / img_width
        y_scale = 1.0 / img_height

        # 좌표를 0에서 1 사이의 값으로 정규화
        normalized_xmin = xmin * x_scale
        normalized_ymin = ymin * y_scale
        normalized_xmax = xmax * x_scale
        normalized_ymax = ymax * y_scale

        normalized_bboxes.append([normalized_xmin, normalized_ymin, normalized_xmax, normalized_ymax])

    return normalized_bboxes


def ensemble_predict(mmdetection_prediction, yolov8_prediction, iou_thr = 0.5, skip_box_thr = 0.4, pred_score_thr=0.4):
    normalize_mmdetection_prediction = mmdetection_prediction.copy()
    normalize_mmdetection_prediction['bboxes'] = normalize_bboxes(mmdetection_prediction['bboxes'], 1333, 800)

    normalize_yolov8_prediction = yolov8_prediction.copy()
    normalize_yolov8_prediction['bboxes'] = normalize_bboxes(yolov8_prediction['bboxes'], 640, 640)
    
    boxes_list = [normalize_mmdetection_prediction['bboxes'], normalize_yolov8_prediction['bboxes']]
    scores_list = [normalize_mmdetection_prediction['scores'], normalize_yolov8_prediction['scores']]
    labels_list = [normalize_mmdetection_prediction['labels'], normalize_yolov8_prediction['labels']]

    boxes, scores, labels = weighted_boxes_fusion(boxes_list, scores_list, labels_list, iou_thr=iou_thr, skip_box_thr=skip_box_thr)
    
    idx = next((i for i, score in enumerate(scores) if score < pred_score_thr), None)

    if idx is not None:
        labels = labels[:idx]
        scores = scores[:idx]
        boxes = boxes[:idx]
        
    wbf_prediction = {
        'labels': labels.astype(int).tolist(),
        'scores': scores.tolist(),
        'bboxes': boxes.tolist()
    }
    
    return wbf_prediction


def denormalize_ensemble_prediction(detection_result, img_width, img_height):
    denormalized_wbf_prediction = {'labels': [], 'scores': [], 'bboxes': []}

    for label, score, bbox in zip(detection_result['labels'], detection_result['scores'], detection_result['bboxes']):
        normalized_xmin, normalized_ymin, normalized_xmax, normalized_ymax = bbox

        # 원래 이미지 크기에 따른 비율 계산
        x_scale = img_width
        y_scale = img_height

        # 좌표를 원래 크기로 되돌리기
        denormalized_xmin = normalized_xmin * x_scale
        denormalized_ymin = normalized_ymin * y_scale
        denormalized_xmax = normalized_xmax * x_scale
        denormalized_ymax = normalized_ymax * y_scale

        denormalized_wbf_prediction['labels'].append(label)
        denormalized_wbf_prediction['scores'].append(score)
        denormalized_wbf_prediction['bboxes'].append([denormalized_xmin, denormalized_ymin, denormalized_xmax, denormalized_ymax])

    return denormalized_wbf_prediction


def openmax_predict(img, classfire_checkpoint_file):
    mr_models = {'0': {'shape': 0.2282404094722424, 'loc': 86.7123260498047, 'scale': 1.5792422367356975},
                 '1': {'shape': 0.2000000207674168, 'loc': 145.67910766601565, 'scale': 1.5831391332087397},
                 '2': {'shape': 0.3281392444013167, 'loc': 27.361701965332035, 'scale': 1.6509341996249693}}

    class_means = np.array([[7.8386683, -4.309099, -4.6433406],
                       [-6.781459, 5.112835, -0.46414238],
                       [-2.4918842, -1.6917051, 3.207502]], dtype=np.float32)
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    target_class_num = 3
    net = torchvision.models.resnet50(pretrained=True)
    net.fc = torch.nn.Linear(
        net.fc.in_features,
        target_class_num
    )
    net.load_state_dict(torch.load(classfire_checkpoint_file, map_location=device))
    net.eval()
    net.to(device)
    
    normalize = torchvision.transforms.Normalize(
        mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
    )
    
    test_transformer = transforms.Compose([
        transforms.ToTensor(),
        normalize
    ])
                        
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)            
    img = cv2.resize(img, (224, 224))
    input_data = test_transformer(img).unsqueeze(0)                    
                  
    threshold = 0.455
    
    with torch.no_grad():
        out = input_data.to(device)
        out = net(out)
        actvec = out.cpu().detach().numpy()[0]
        out_softmax = torch.softmax(out, 1).cpu().detach().numpy()[0]
        
        dist_to_mean = np.square(actvec - class_means).sum(axis=1)

        scores = list()
        for class_idx in range(len(class_means)):
            params = mr_models[str(class_idx)]
            score = stats.weibull_max.cdf(
                dist_to_mean[class_idx],
                params['shape'],
                params['loc'],
                params['scale']
            )
            scores.append(score)
        scores = np.asarray(scores)

        weight_on_actvec = 1 - scores # 각 class별 가중치

        rev_actvec = np.concatenate([
            weight_on_actvec * actvec, # known class에 대한 가중치 곱
            [((1-weight_on_actvec) * actvec).sum()] # unknown class에 새로운 계산식
        ])

        openmax_prob = np.exp(rev_actvec) / np.exp(rev_actvec).sum()        
        openmax_softmax = np.exp(openmax_prob)/sum(np.exp(openmax_prob))
        
        openmax_predetion = np.argmax(openmax_softmax)
        
        if np.max(openmax_softmax) < threshold:
            openmax_predetion = target_class_num
        
    return openmax_predetion
