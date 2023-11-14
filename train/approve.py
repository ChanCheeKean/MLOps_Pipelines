import argparse
import boto3

def train_model(args):
    try:
        client = boto3.client('sagemaker')
        model_package_arn = args.model_package_arn
        model_update_dict = {
            "ModelPackageArn" : model_package_arn,
            "ModelApprovalStatus" : "Approved"
        }
        model_update_response = client.update_model_package(**model_update_dict)
        print(model_update_response)
        return "Model Approved!"

    except Exception as e:
        return f"Error: {e}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train a SageMaker model")
    parser.add_argument("--model_package_arn", help="Model Arn to be approved")
    args = parser.parse_args()
    print("Received arguments:", args)
    result = train_model(args)
    print(f"Training {result}")