import os
import json
import pandas as pd

def model_fn(model_dir):
    with open(os.path.join(model_dir, "decision-tree-model.pkl"), "rb") as inp:
        model = pickle.load(inp)
        return model

def input_fn(request_body, request_content_type):
    if request_content_type == 'application/json':
        request_body = json.loads(request_body)
        inpVar = request_body['Input']
        return inpVar
    elif content_type == "text/csv":
        data = pd.read_csv(request_body)
    else:
        raise ValueError("This model only supports application/json input")

def predict_fn(input_data, model):
    return model.predict(input_data)

def output_fn(prediction, content_type):
    res = int(prediction[0])
    respJSON = {'results': res}
    return respJSON