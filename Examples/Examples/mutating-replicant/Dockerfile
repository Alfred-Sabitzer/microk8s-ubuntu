FROM golang:latest as builder

WORKDIR /app

COPY . .

RUN go get golang.org/x/exp/slog
RUN go get golang.org/x/exp/slog
RUN go get k8s.io/api/admission/v1
RUN go get k8s.io/api/apps/v1
RUN go get k8s.io/apimachinery/pkg/apis/meta/v1
RUN go get k8s.io/apimachinery/pkg/runtime
RUN go get k8s.io/apimachinery/pkg/runtime/serializer

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server main.go

FROM alpine

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/server /server

EXPOSE 9093

ENTRYPOINT ["/server"]