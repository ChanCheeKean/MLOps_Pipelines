import argparse
import boto3
import sagemaker

def train_model(args):
    try:
        TARGET_IMG = args.target_img
        OUTPUT_PATH = args.output_path
        role = args.role
        file_location = args.file_location
        package_group = args.model_package_group_name
        instance_type = args.instance_type

        sess = sagemaker.Session()
        client = boto3.client('sagemaker')
        account = sess.boto_session.client('sts').get_caller_identity()['Account']
        region = sess.boto_session.region_name
        image_uri = f'{account}.dkr.ecr.{region}.amazonaws.com/{TARGET_IMG}:latest'

        ### model training ###
        model = sagemaker.estimator.Estimator(
            image_uri,
            role,
            instance_count=1,
            instance_type=instance_type,
            output_path=OUTPUT_PATH,
            sagemaker_session=sess,
            enable_cloudwatch_metrics=True,
        )
        model.set_hyperparameters(
            max_leaf_nodes=5
        )
        model.fit(file_location)

        ### model register ###
        exist_group = client.list_model_package_groups(
            NameContains=package_group)['ModelPackageGroupSummaryList']

        if not any(group['ModelPackageGroupName'] == package_group for group in exist_group):
            package_group_dict = {
                "ModelPackageGroupName" : package_group,
                "ModelPackageGroupDescription" : "Model package group for DecisionTree Classifier for Iris dataset"
            }
            group_response = client.create_model_package_group(**package_group_dict)
            print(f"ModelPackageGroup Arn: {group_response['ModelPackageGroupArn']}")
        else:
            group_response = exist_group[0]
            print(f'ModelPackageGroup exists. Arn: {group_response["ModelPackageGroupArn"]}')

        # updating trained model information
        image_uri = sagemaker.image_uris.retrieve(
            framework="sklearn",
            region=region,
            version="0.23-1",
            py_version="py3",
            instance_type='ml.m4.xlarge',
        )

        model_dict = {
            "ModelPackageGroupName" : group_response['ModelPackageGroupArn'],
            "ModelPackageDescription" : "Model package group for DecisionTree Classifier for Iris dataset",
            "ModelApprovalStatus" : "PendingManualApproval",
            "InferenceSpecification": {
                "Containers": [{
                    "Image": image_uri, 
                    "ModelDataUrl": model.model_data,
                    # "Mode": "SingleModel",
                    "Environment": {
                        'SAGEMAKER_SUBMIT_DIRECTORY': model.model_data, 
                        'SAGEMAKER_PROGRAM': 'inference.py'
                    } 
                }],
                "SupportedContentTypes": ["text/csv", "application/json"],
                "SupportedResponseMIMETypes": ["text/csv", "application/json"],
            }
        }

        # Create cross-account model package
        package_response = client.create_model_package(**model_dict)
        model_package_arn = package_response["ModelPackageArn"]
        print(f'Model Package Version ARN : {model_package_arn}')
        model_package_arn_list = client.list_model_packages(
            ModelPackageGroupName=package_group)['ModelPackageSummaryList']
        print(
            f"All Model Package Version ARN : \
                {[a['ModelPackageArn'].split(':')[-1] for a in model_package_arn_list]}"
            )

        # describe latest model
        res = client.describe_model_package(ModelPackageName=model_package_arn)
        for key in ['ModelPackageArn', 'ModelApprovalStatus']:
            print(key, ": ", res[key])

        return 'Success'

    except Exception as e:
        print(f"Error: {e}")
        return 'Failed'

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train a SageMaker model")
    parser.add_argument(
        "--target_img", help="Target image name", default='ml-infra-pipelines-train-dev'
        )
    parser.add_argument(
        "--output_path", help="S3 output path", default="s3://ml-infra-pipelines-dev/output/"
        )
    parser.add_argument(
        "--role", help="SageMaker role", default='ml-infra-pipelines-dev-sagemaker'
        )
    parser.add_argument(
        "--model_package_group_name", 
        help="Model Group contains a set of versioned models", 
        default='ml-infra-iris-predictor'
        )
    parser.add_argument(
        "--file_location", 
        help="S3 file location for training data", 
        default="s3://ml-infra-pipelines-dev/sample/training/iris.csv"
        )
    parser.add_argument(
        "--instance_type", 
        help="Instance type for Training at Sagemaker", 
        default="ml.m4.xlarge"
        )
    
    args = parser.parse_args()
    print("Received arguments:", args)
    result = train_model(args)
    print(f"Training {result}")