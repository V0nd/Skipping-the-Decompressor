FROM aflplusplus/aflplusplus:latest

RUN apt-get update && apt-get install -y --no-install-recommends zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /skipd

COPY . /skipd

RUN make clean && make all

CMD ["/bin/bash"]
