import logging
import os
import json

logger = logging.getLogger('lambda_logger')
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info('function = %s, version = %s, request_id = %s', context.function_name, context.function_version, context.aws_request_id)
    logger.info('event = %s', event)

    base_message = os.environ['BASE_MESSAGE']

    last_name = event.get("queryStringParameters").get("last_name")
    first_name = event.get("queryStringParameters").get("first_name")

    return {
        'statusCode': 200,
        'body': json.dumps({ 'message': f'{base_message}, {first_name} {last_name}!!' })
    }