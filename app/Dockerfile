FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Deliberately copies everything including .env — this is the security challenge.
# The .env secrets get baked into this image layer. See the README.
COPY . .

RUN pip3 install -r requirements.txt

EXPOSE 5000

CMD ["python3", "app.py"]
