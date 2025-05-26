func mutateCreate() admissioncontroller.AdmitFunc {
    return func(r *v1beta1.AdmissionRequest) (*admissioncontroller.Result, error) {
        var operations []admissioncontroller.PatchOperation
        pod, err := parsePod(r.Object.Raw)
        if err != nil {
            return &admissioncontroller.Result{Msg: err.Error()}, nil
        }

        // Very simple logic to inject a new "sidecar" container.
        if pod.Namespace == "special" {
            var containers []v1.Container
            containers = append(containers, pod.Spec.Containers...)
            sideC := v1.Container{
                Name:    "test-sidecar",
                Image:   "busybox:stable",
                Command: []string{"sh", "-c", "while true; do echo 'I am a container injected by mutating webhook'; sleep 2; done"},
            }
            containers = append(containers, sideC)
            operations = append(operations, admissioncontroller.ReplacePatchOperation("/spec/containers", containers))
        }

        return &admissioncontroller.Result{
            Allowed:  true,
            PatchOps: operations,
        }, nil
    }
}
