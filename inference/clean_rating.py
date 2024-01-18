from collections import Counter

def count_obj(label_list, max_count):
    count_dict = Counter(label_list)
    result = {key: value for key, value in count_dict.items() if value >= max_count}
    return result


def determine_clean_class(prediction, threshold=0.4):
    # 0 : 'pending', 1 : 'clean', 2 : 'normal', 3 : 'dirty'
    # Filter labels based on a score threshold
    scores = prediction.get('scores', [])
    labels = prediction.get('labels', [])
    idx = next((i for i, score in enumerate(scores) if score < threshold), None)
    if idx is not None:
        labels = labels[:idx]

    # Determine clean class
    # pending (if labels are bag, keys, valuable)
    if any(label in [0, 5, 10] for label in labels):
        clean_cls = 0
    # clean
    elif len(labels) == 0 or (next(iter(set(labels))) == 7):
        clean_cls = 1
    # dirty (if labels are bottle, cafe-cup, can, trash, or more than 3 unique labels or any label occurs 4 or more times)
    elif any(label in [1, 2, 3, 9] for label in labels) or len(set(labels)) > 3 or len(count_obj(labels, 4)) >= 1:
        clean_cls = 3
    # normal
    else:
        clean_cls = 2

    return clean_cls


def determine_vehicle_cleanlinesss(class_result_label_list):
    result_counter = Counter(class_result_label_list)
    
    # 귀중품이 나온 경우
    if result_counter['pending'] >= 1:
        return 'valuable'
    # 차량이 더러운 경우
    elif result_counter['dirty'] >= 1:
        return 'dirty'
    # 크레딧 기준 통과
    elif result_counter['clean'] >= 3:
        return 'pass'
    # 크레딧 기준 실패
    else:
        return 'fail'
