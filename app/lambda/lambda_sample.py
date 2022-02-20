import logging
import os

logger = logging.getLogger('lambda_logger')
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info('function = %s, version = %s, request_id = %s', context.function_name, context.function_version, context.aws_request_id)
    logger.info('event = %s', event)

    base_message = os.environ['BASE_MESSAGE']

    last_name = event['last_name']
    first_name = event['first_name']

    return { 'message': f'{base_message}, {first_name} {last_name}!!' }