import sys
sys.path.append('./mmdetection')

from mmdet.apis import DetInferencer
from ultralytics import YOLO
from ensemble_boxes import  weighted_boxes_fusion
import cv2
import matplotlib.pyplot as plt
from copy import deepcopy

# js import
import warnings
warnings.filterwarnings("ignore")

import os
import numpy as np
import cv2
from statistics import mean

import torch
import torchvision
import torchvision.transforms as transforms

from scipy import stats

def mmdetection_list_predict(mmdetection_imgs, config_file, checkpoint_file, device = 'cpu:0', pred_score_thr=0.4):

    inferencer = DetInferencer(config_file, checkpoint_file, device)
   
    images = []

    for image_path in mmdetection_imgs : 
        img = cv2.imread(image_path)
        images.append(cv2.resize(img, (1333, 800)))
    
    result = inferencer(images, pred_score_thr = pred_score_thr)
    
    mmdetection_predictions = []
    
    for idx in range(len(mmdetection_imgs)):
        prediction = result['predictions'][idx]
    
        label = prediction['labels']
        scores = prediction['scores']
        bboxe = prediction['bboxes']

        idx = next((i for i, score in enumerate(scores) if score < pred_score_thr), None)

        if idx is not None:
            labels = label[:idx]
            scores = scores[:idx]
            boxes = bboxe[:idx]

        mmdetection_prediction  = {
        'labels' : labels,
        'scores' : scores,
        'bboxes' : boxes
        }
        mmdetection_predictions.append(mmdetection_prediction)
    
    return mmdetection_predictions


def yolov8_list_predict(yolov8_imgs, checkpoint_file, conf = 0.4):
    
    model = YOLO(checkpoint_file)

    images = []

    for image_path in yolov8_imgs : 
        img = cv2.imread(image_path)
        images.append(cv2.resize(img, (640, 640)))
    
    yolov8_predictions = []
    result = model(images, conf = conf)
    
    for idx in range(len(result)):
        box_info = result[idx].boxes
    
        yolov8_prediction = {
            'labels': [int(label) for label in box_info.cls.tolist()],
            'scores': box_info.conf.tolist(),
            'bboxes': box_info.xyxy.tolist()
        }
        yolov8_predictions.append(yolov8_prediction)

    return yolov8_predictions


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


def ensemble_list_predict(mmdetection_predictions, yolov8_predictions, iou_thr = 0.45, skip_box_thr = 0.4, pred_score_thr = 0.4, conf_type= 'max'):
    normalize_mmdetection_predictions = deepcopy(mmdetection_predictions)
    normalize_yolov8_predictions = deepcopy(yolov8_predictions)
    
    wbf_predictions = []
    
    for idx in range(len(mmdetection_predictions)):
        normalize_mmdetection_predictions[idx]['bboxes'] = normalize_bboxes(mmdetection_predictions[idx]['bboxes'], 1333, 800)
        normalize_yolov8_predictions[idx]['bboxes'] = normalize_bboxes(yolov8_predictions[idx]['bboxes'], 640, 640)
    
        boxes_list = [normalize_mmdetection_predictions[idx]['bboxes'], normalize_yolov8_predictions[idx]['bboxes']]
        scores_list = [normalize_mmdetection_predictions[idx]['scores'], normalize_yolov8_predictions[idx]['scores']]
        labels_list = [normalize_mmdetection_predictions[idx]['labels'], normalize_yolov8_predictions[idx]['labels']]

        boxes, scores, labels = weighted_boxes_fusion(boxes_list, scores_list, labels_list, iou_thr=iou_thr, skip_box_thr=skip_box_thr, conf_type= conf_type)
    
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
        wbf_predictions.append(wbf_prediction)

    return wbf_predictions


def openmax_list_predict(img_list, classfire_checkpoint_file):
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
    openmax_list = []
    for img in img_list:
        img = cv2.imread(img)
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
                
            openmax_list.append(openmax_predetion)
        
    return openmax_list         
