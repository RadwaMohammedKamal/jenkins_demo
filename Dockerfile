FROM alpine:latest
COPY test.txt /test.txt
CMD ["cat", "/test.txt"]

