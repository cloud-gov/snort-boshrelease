ARG base_image

FROM ${base_image}

WORKDIR /opt

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    wget

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm LWP::UserAgent
RUN cpanm --force Crypt::SSLeay

RUN wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pulledpork/pulledpork-0.7.0.tar.gz
RUN tar xf pulledpork-0.7.0.tar.gz
