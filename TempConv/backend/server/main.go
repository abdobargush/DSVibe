package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"

	pb "TempConv/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"
)

type server struct {
	pb.UnimplementedTemperatureConverterServer
}

func (s *server) ConvertToCelsius(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	celsius := (req.Value - 32) * 5 / 9
	log.Printf("Converting %.2f°F to %.2f°C", req.Value, celsius)
	return &pb.TemperatureResponse{
		Value: celsius,
		Unit:  "Celsius",
	}, nil
}

func (s *server) ConvertToFahrenheit(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	fahrenheit := (req.Value * 9 / 5) + 32
	log.Printf("Converting %.2f°C to %.2f°F", req.Value, fahrenheit)
	return &pb.TemperatureResponse{
		Value: fahrenheit,
		Unit:  "Fahrenheit",
	}, nil
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "50051"
	}

	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterTemperatureConverterServer(s, &server{})

	// Register health service
	healthServer := health.NewServer()
	grpc_health_v1.RegisterHealthServer(s, healthServer)
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)

	reflection.Register(s)

	log.Printf("Server listening on port %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
