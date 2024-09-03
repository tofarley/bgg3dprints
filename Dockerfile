FROM public.ecr.aws/lambda/python:3.10

# Copy function code
COPY app/lambda_function.py ${LAMBDA_TASK_ROOT}
COPY lambda-entrypoint.sh /lambda-entrypoint.sh
# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
# CMD [ "lambda_function.lambda_handler" ]

ENTRYPOINT [""]