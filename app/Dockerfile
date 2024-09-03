FROM public.ecr.aws/lambda/python:3.10

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

RUN pip install requests \
  && pip install lxml \
  && pip install markupsafe

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.lambda_handler" ]