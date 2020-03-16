FROM python:3.7
COPY templates ./templates
COPY mysql_operator.py ./mysql_operator.py
RUN pip install kopf kubernetes pyyaml jinja2
CMD kopf run /mysql_operator.py
