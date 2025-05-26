// http/handlers.go

type admissionHandler struct {...}

// Serve returns a http.HandlerFunc for an admission webhook
func (h *admissionHandler) Serve(hook admissioncontroller.Hook) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // HTTP validations
        // ...
        body, err := io.ReadAll(r.Body)
        if err != nil {...}

        var review admission.AdmissionReview
        if _, _, err := h.decoder.Decode(body, nil, &review); err != nil {...}

        result, err := hook.Execute(review.Request)
        if err != nil {...}

        admissionResponse := v1beta1.AdmissionReview{
            Response: &v1beta1.AdmissionResponse{
                UID:     review.Request.UID,
                Allowed: result.Allowed,
                Result:  &meta.Status{Message: result.Msg},
            },
        }
        //...
        res, err := json.Marshal(admissionResponse)
        if err != nil {...}

        w.WriteHeader(http.StatusOK)
        w.Write(res)
    }
}
