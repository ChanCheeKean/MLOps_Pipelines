import boto3
runtime = boto3.client("sagemaker-runtime")

def handler(event, context):
    if "body" in event:
        # For API Gateway
        event = json.loads(event["body"])

    context =  event["context"]
    response = runtime.invoke_endpoint(
        EndpointName='ml-infra-iris-predictor',
        Body=context",
        ContentType="text/csv",
    )

    # For API Gateway
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(response),
    }