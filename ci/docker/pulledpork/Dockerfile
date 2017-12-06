FROM perl:latest

WORKDIR /opt

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm LWP::UserAgent
RUN cpanm --force Crypt::SSLeay

RUN wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pulledpork/pulledpork-0.7.0.tar.gz
RUN tar xf pulledpork-0.7.0.tar.gz
