import time
from time import gmtime, strftime
import boto3 
import sagemaker
client = boto3.client('sagemaker')
iam_client = boto3.client('iam')

def lambda_handler(event, context):
    if "body" in event:
        # For API Gateway
        event = json.loads(event["body"])

    model_name = event.get('model_name', 'ml-infra-iris-predictor')
    model_package_arn = event.get('model_package_arn', '')
    role = event.get('role', 'ml-infra-pipelines-dev-sagemaker')
    instance_type = event.get('instance_type', "ml.c5.xlarge")
    instance_count = event.get('instance_count', 1)
    blue_green_deploy = event.get('blue_green_deploy', False)

    # Initialize clients and variables
    role_arn = iam_client.get_role(RoleName=role)['Role']['Arn']
    container_list = [{'ModelPackageName': model_package_arn}]

    try:
        endpoint_response = client.describe_endpoint(EndpointName=model_name)
        client.delete_endpoint(EndpointName=model_name)
        print("Endpoint Exists, updating...")
        endpoint_exists = True
    except Exception as e:
        print(f"Error: {e}. Creating New Endpoint")
        endpoint_exists = False
    new_config_name = model_name + '-' + strftime("%Y-%m-%d-%H-%M-%S", gmtime())
    
    # Model creation
    model_response = client.create_model(
        ModelName=new_config_name,
        ExecutionRoleArn=role_arn,
        Containers=container_list
    )

    # Endpoint config creation
    endpoint_config_response = client.create_endpoint_config(
        EndpointConfigName=new_config_name,
        ProductionVariants=[{
            'InstanceType': instance_type,
            'InitialInstanceCount': instance_count,
            'InitialVariantWeight': 1,
            'ModelName': new_config_name,
            'VariantName': 'sklearnvariant'
        }]
    )

    # Blue-green deployment
    if blue_green_deploy:
        deploy_config = {
            "BlueGreenUpdatePolicy": {
                "TrafficRoutingConfiguration": {
                    "Type": "LINEAR",
                    "LinearStepSize": {
                        "Type": "CAPACITY_PERCENT",
                        "Value": 20
                    },
                    "WaitIntervalInSeconds": 300
                },
                "TerminationWaitInSeconds": 300,
                "MaximumExecutionTimeoutInSeconds": 3600
            }
        }
    else:
        deploy_config = None

    # Endpoint creation
    if endpoint_exists:
        endpoint_response = client.update_endpoint(
            EndpointName=model_name,
            EndpointConfigName=new_config_name,
            DeploymentConfig=deploy_config
        )
    else:
        endpoint_create_response = client.create_endpoint(
            EndpointName=model_name,
            EndpointConfigName=new_config_name
        )

    # Print creation status
    print("Creating Endpoint")
    while True:
        endpoint_response = client.describe_endpoint(EndpointName=model_name)
        if endpoint_response["EndpointStatus"] != "Creating":
            print(endpoint_response["EndpointStatus"])
            print(f"Endpoint Arn: {endpoint_response['EndpointArn']}")
            break
        time.sleep(15)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({
            'Status': endpoint_response["EndpointStatus"],
            'Endpoint Arn' : endpoint_response['EndpointArn'],
        }),
    }