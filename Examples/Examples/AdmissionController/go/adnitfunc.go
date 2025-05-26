// AdmitFunc defines how to process an admission request
type AdmitFunc func(request *admission.AdmissionRequest) (*Result, error)

// Hook represents the set of functions for each operation in an admission webhook.
type Hook struct {
    Create  AdmitFunc
    Delete  AdmitFunc
    Update  AdmitFunc
    Connect AdmitFunc
}

// Execute evaluates the request and try to execute the function for operation specified in the request.
func (h *Hook) Execute(r *admission.AdmissionRequest) (*Result, error) {
    switch r.Operation {
    case admission.Create:
        return wrapperExecution(h.Create, r)
    .....
    }
    return &Result{Msg: fmt.Sprintf("Invalid operation: %s", r.Operation)}, nil
}
