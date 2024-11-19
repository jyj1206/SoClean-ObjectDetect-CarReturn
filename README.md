 
# 카셰어링 깨끗 반납 인증 서비스

> + 허지은(팀장) : [https://github.com/Heo-jieun](https://github.com/Heo-jieun)
> + 박지성 : [https://github.com/jisungbb](https://github.com/jisungbb)
> + 임근웅 : [https://github.com/woongs9](https://github.com/woongs9)
> + 정영진 : [https://github.com/jyj1206](https://github.com/jyj1206)
> + 개발기간 : 2023.11.28 ~ 2024.01.17  

<img width="974" alt="model" src="https://github.com/user-attachments/assets/bb018afb-26be-4c1e-9e54-7746c7507316">

<br>

## Introduction

**깨끗 반납 인증은 카셰어링을 사용하는 모든 사람들이 깨끗한 차를 사용할 수 있도록, 반납시 차량 청소를 장려하는 서비스입니다.** 
<img width="974" alt="model" src="https://github.com/user-attachments/assets/1d86f1c1-df0c-49e1-b9ae-1b9e89411c77">
사용자가 차량을 반납하기 전 차량 내부를 청소하고 깨끗하게 반납하는 것을 인증하면 크레딧을 제공합니다.

**깨끗 반납 인증은 카셰어링 사용자에게 쾌적한 주행 서비스를 제공할 수 있습니다.**

해당 서비스는 사용자와 업체 모두에게 편의성을 제공합니다. 
1. 사용자는 크레딧을 얻기위해 차량을 깨끗하게 반납.
2. 다음 사용자는 깨끗한 차를 이용가능.
3. 업체 측은 사용자가 보낸 사진으로 차량 내부의 청결도를 파악하기 쉬움.  
<br>  

## 내부 청결도 측정 모델

**깨끗반납 인증 서비스를 위한 내부 청결도 측정 모델**   
<br>
<img width="974" alt="model" src="https://github.com/user-attachments/assets/3a3d5833-df22-4434-bc12-0734be053bd0">
<br>
내부 청결도 측정 모델은 사용자로부터 운전석 매트, 조수석 매트, 컵홀더, 뒷자석 사진을 받아 아래 프로세스를 따릅니다.
1. Rejection 모델로 분류가 애매한 이미지들을 1차로 정제.
2. Object detection모델을 통해 이미지에서 더러운 부분을 찾아냄 .  
3. 찾아낸 정보를 바탕으로 각 이미지별 청결도를 분류.
4. 최종적으로 4장의 사진을 종합하여 해당 차가 깨끗한 차인가를 분류.  
<br>


## 모델 추론 프로세스

<img width="974" alt="model" src="https://github.com/user-attachments/assets/d929ec82-eeb7-4a51-a51b-7a6266ac7a6b">
<br>

우리의 전체 추론 파이프라인은 크게 3 단계로 진행됩니다.
1. 먼저 rejection 모델로 이미지가 맞게 들어왔는지 확인.
    > Resnet50  
    > OpenMax  
2. object detection으로 차량내부의 쓰레기와 오염물, 이물질 등을 검출.
    > Two stage : Dino  
    > One stage : Yolov8l  
    > WBF Ensemble
3. 청결도 분류기로 최종 차량의 청결도를 평가.   

<br>


## 시작가이드 
### Enviroment

+ Python 3.9+
+ CUDA 9.2+
+ PyTorch 1.8+
  
### Installation 
```
$ git clone https://github.com/AIFFEL-SO-4th/SoClean.git
$ cd https://github.com/AIFFEL-SO-4th/SoClean.git
```

### Requirements
```
pip install -r requiremtns.txt
pip install -e mmdetection
mim install "mmengine>=0.7.0"
mim install "mmcv>=2.0.0rc4"
``` 
   

<br>  

## Reference
### paper
+ open max : https://arxiv.org/abs/1511.06233  
+ yolov8 : https://arxiv.org/abs/2305.09972 
+ dino : https://arxiv.org/abs/2203.03605   
+ ensemble : https://arxiv.org/abs/1910.13302  
  
### github
+ mmdetection : https://github.com/open-mmlab/mmdetection
+ ultralytics : https://github.com/ultralytics  
+ ensemble : https://github.com/ZFTurbo/Weighted-Boxes-Fusion
+ eigen cam : https://github.com/rigvedrs/YOLO-V8-CAM

<br>

## Stacks 🚘

<div align=center> 
<img src="https://img.shields.io/badge/python-3776AB?style=for-the-badge&logo=python&logoColor=white"> 
<img src="https://img.shields.io/badge/DART-339AF0?style=for-the-badge&logo=DART&logoColor=white">
<br>

<img src="https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white">
<img src="https://img.shields.io/badge/Android%20Studio-3DDC84.svg?style=for-the-badge&logo=android-studio&logoColor=white">
<img src="https://img.shields.io/badge/figma-%23F24E1E.svg?style=for-the-badge&logo=figma&logoColor=white">
<br>

<img src="https://img.shields.io/badge/pytorch-F80000?style=for-the-badge&logo=pytorch&logoColor=white"> 
<img src="https://img.shields.io/badge/flask-000000?style=for-the-badge&logo=flask&logoColor=white">
<img src="https://img.shields.io/badge/flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">
<br>

<img src="https://img.shields.io/badge/linux-FCC624?style=for-the-badge&logo=linux&logoColor=black"> 
<img src="https://img.shields.io/badge/DOCKER-1572B6?style=for-the-badge&logo=DOCKER&logoColor=white"> 
<img src="https://img.shields.io/badge/Google%20Drive-4285F4?style=for-the-badge&logo=googledrive&logoColor=white">
<img src="https://img.shields.io/badge/firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white">
<img src="https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white">
<br>

<img src="https://img.shields.io/badge/github-181717?style=for-the-badge&logo=github&logoColor=white">
<img src="https://img.shields.io/badge/git-F05032?style=for-the-badge&logo=git&logoColor=white">
<br>

<img src="https://img.shields.io/badge/Notion-%23000000.svg?style=for-the-badge&logo=notion&logoColor=white">
<img src="https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white">
<img src="https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white">
</div>

