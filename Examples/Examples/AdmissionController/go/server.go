// http/server.go
func NewServer(port string) *http.Server {
    // Instances hooks
    podsValidation := pods.NewValidationHook()
    // Routers
    ah := newAdmissionHandler()
    mux := http.NewServeMux()
    mux.Handle("/validate/pods", ah.Serve(podsValidation)) // The path of the webhook for Pod validation.
    return &http.Server{
        Addr:    fmt.Sprintf(":%s", port),
        Handler: mux,
    }
}

// cmd/main.go
func main() {
    // flags
    // ...
    server := http.NewServer(port)
    if err := server.ListenAndServeTLS(tlscert, tlskey); err != nil {
        log.Errorf("Failed to listen and serve: %v", err)
    }
}
