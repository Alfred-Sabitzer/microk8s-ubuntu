// pods/pods.go
// NewValidationHook creates a new instance of pods validation hook
func NewValidationHook() admissioncontroller.Hook {
    return admissioncontroller.Hook{
        Create: validateCreate(),
    }
}

// validateImages validates that none of the containers use the `latest` tag.
func validateImages() admissioncontroller.AdmitFunc {
    return func(r *v1beta1.AdmissionRequest) (*admissioncontroller.Result, error) {
        pod, err := parsePod(r.Object.Raw)
        if err != nil {
            return &admissioncontroller.Result{Msg: err.Error()}, nil
        }

        for _, c := range pod.Spec.Containers {
            if strings.HasSuffix(c.Image, ":latest") {
                return &admissioncontroller.Result{Msg: "You cannot use the tag 'latest' in a container."}, nil
            }
        }

        return &admissioncontroller.Result{Allowed: true}, nil
    }
}
