# Renders the architecture diagrams without installing anything on the host:
#   docker build -t mm-events-diagrams deploy/diagrams
#   docker run --rm -v "$PWD/deploy/diagrams:/work" mm-events-diagrams
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends graphviz fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir diagrams==0.25.1

WORKDIR /work
CMD ["sh", "-c", "for f in current_free_demo.py aws.py gcp.py azure.py; do python \"$f\" || exit 1; done"]
