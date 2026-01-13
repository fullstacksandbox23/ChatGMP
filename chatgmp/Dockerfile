FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

WORKDIR /app/interface

EXPOSE 80

CMD ["gunicorn", "--bind", "0.0.0.0:80", "main:app"]