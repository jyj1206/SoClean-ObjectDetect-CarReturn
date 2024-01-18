# -*- coding: utf-8 -*-
# app.py
import os
import json
import uuid
import threading
from flask import Flask, request, jsonify, abort
import firebase_admin
from firebase_admin import credentials, messaging
import glob
from inference.pipeline import four_image_list_pipeline
from datetime import datetime
import base64

app = Flask(__name__)

processing_status = {'count': 0, 'total': 4, 'lock': threading.Lock()}

UPLOAD_FOLDER = 'data'
RESULTS_FOLDER = 'results'

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
if not os.path.exists(RESULTS_FOLDER):
    os.makedirs(RESULTS_FOLDER)


cred_path = "soclean-3e797-firebase-adminsdk-xth93-32fd73808c.json"
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)


@app.route('/message', methods=['GET'])
def send_fcm_message(token):
    print(token)
    title = '사진 분석이 완료되었습니다.'
    body = '앱내의 결과 보기를 클릭해 확인해 주세요.'

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        token=token,
    )
    try:
        response = messaging.send(message)
        return {'message': 'Successfully sent message', 'response': response}, 200
    except Exception as e:
        return {'error': str(e)}, 500

mmdetection_config_file = "./mmdetection/configs/dino/dino-4scale_r50_8xb2-60e_coco_all_v2.py"
mmdetection_checkpoint_file = "./project/model/weights/mmdetection_dino_weights.pth"
yolov8_checkpoint_file = "./project/model/weights/yolov8_weights.pt"
classfire_checkpoint_file = "./project/model/weights/classifier_weights.pth"

@app.route('/uploadrequestid', methods=['POST'])
def upload_files_request_id():
    files = request.files.getlist('file')
    token = request.form.get('token')
    
    if not files:
        return jsonify({'error': 'No files provided'}), 400
    file_contents = [file.read() for file in files]
    filenames = [file.filename for file in files]
    request_id = str(uuid.uuid4())
    thread = threading.Thread(target=save_and_process_images, args=(file_contents, filenames, request_id, token))
    thread.start()
    return jsonify({'request_id': request_id})


def save_and_process_images(file_contents, filenames, request_id, token):
    request_folder = os.path.join(UPLOAD_FOLDER, request_id)
    if not os.path.exists(request_folder):
        os.makedirs(request_folder)

    predefined_filenames = ['driver_seat_mat.jpg', 'passenger_seat_mat.jpg', 'rear_seat.jpg', 'cup_holder.jpg']
    saved_files = []
    
    for file_content, predefined_filename in zip(file_contents, predefined_filenames):
        file_path = os.path.join(request_folder, predefined_filename)
        with open(file_path, 'wb') as f:
            f.write(file_content)
        saved_files.append(file_path)

    if len(saved_files) == len(predefined_filenames):
        process_and_save_results(saved_files, request_id, token)

def process_and_save_results(file_path, request_id, token):
    try:
        final_result = four_image_list_pipeline(UPLOAD_FOLDER, request_id, 
                                                mmdetection_config_file, 
                                                mmdetection_checkpoint_file, 
                                                yolov8_checkpoint_file,
                                                classfire_checkpoint_file)

        print(final_result) 
        
        if final_result.get('cleanliness') == 'error':
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_message = f"Time: {current_time}, Request ID: {request_id}, Result: {final_result}\n"
            
            # 로그 파일에 직접 기록
            with open('errorLog/error_log.log', 'a') as log_file:
                log_file.write(log_message)

        result_folder = os.path.join(RESULTS_FOLDER, request_id)
        if not os.path.exists(result_folder):
            os.makedirs(result_folder)

        result_json_path = os.path.join(result_folder, f'{request_id}.json')
        with open(result_json_path, 'w') as f:
            json.dump(final_result, f)
        send_fcm_message(token)
        print('sent the message')
    except Exception as e:
        print(f"Error processing images: {e}")

        
@app.route('/requestresult', methods=['POST'])
def request_result():
    request_id = request.form.get('request_id')
    if not request_id:
        return jsonify({'error': 'No request ID provided'}), 400

    file_path = os.path.join(RESULTS_FOLDER, request_id, f'{request_id}.json')

    if os.path.exists(file_path):
        with open(file_path, 'r') as file:
            data = json.load(file)
            return jsonify(data)
    else:
        return jsonify({'error': 'File not found'}), 404


@app.route('/get_images', methods=['POST'])
def get_images():
    request_id = request.form.get('request_id')
    print(request_id)
    if not request_id:
        abort(400, 'Request ID not provided')

    image_folder = f"data/{request_id}/"
    print(image_folder)
    image_paths = glob.glob(os.path.join(image_folder, 'processed_image_*.jpg'))
    print(image_paths)
    
    image_paths = sorted(image_paths, key=lambda x: os.path.basename(x))

    if not image_paths:
        abort(404, 'Images not found')

    images = []
    for image_path in image_paths:
        with open(image_path, "rb") as image_file:
            encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
            images.append(encoded_image)
	
    return jsonify(images)
    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=True)


