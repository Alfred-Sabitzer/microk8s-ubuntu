package main

import (
//	"bytes"
//	"fmt"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"sync"
	"regexp"
	"golang.org/x/exp/slog"

)

var (
	url  = regexp.MustCompile(`^\/[\/]*$`)
)

type encrypt struct {
	ID   int `json:"id"`
 	Title  string `json:"title"`
}

type status struct {
 	NoEncrypt   string `json:"noencrypt"`
 	NoDecrypt   string `json:"nodecrypt"`
 	Version   string `json:"version"`
 	Doku string `json:"doku"`
}

type datastore struct {
	m map[string]status
	*sync.RWMutex
}

type statusHandler struct {
	store *datastore
}

func (h *statusHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	slog.Info("Statushandler",r.Method," URL:",r.URL)
	switch {
	case r.Method == http.MethodGet && url.MatchString(r.URL.Path):
    	slog.Info("GET ServeHTTP")
		h.getRequest(w, r)
		return
	case r.Method == http.MethodPost && url.MatchString(r.URL.Path):
    	slog.Info("POST ServeHTTP")
		h.postRequest(w, r)
		return
	case r.Method == http.MethodPut && url.MatchString(r.URL.Path):
    	slog.Info("PUT ServeHTTP")
		h.putRequest(w, r)
		return
	default:
		notFound(w, r)
		return
	}
}

func (h *statusHandler) getRequest(w http.ResponseWriter, r *http.Request)  error {
    slog.Info("GET Request")
	url := "https://poetrydb.org/title/spring/title"
	response, err := http.Get(url)
	if err != nil {
		slog.Error("err %q\n", err)
		return err
	}
	defer response.Body.Close()

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		slog.Error("err %q\n", err)
	}

	text := string(body[:])
	//fmt.Println(text)
    //slog.Info("GetRequest:"+text)
    JsonBytes, err := json.Marshal(text)
	if err != nil {
		slog.Error("err %q\n", err)
		internalServerError(w, r)
		return err
	}
	w.WriteHeader(http.StatusOK)
	w.Write(JsonBytes)
	return nil
}

func (h *statusHandler) postRequest(w http.ResponseWriter, r *http.Request)  error {

    slog.Info("POST Request")

/*
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		slog.Error("err %q\n", err)
	}

	text := string(body[:])
	//fmt.Println(text)
    slog.Info("POST Request:"+text)
 */

    var e encrypt
    err := json.NewDecoder(r.Body).Decode(&e)
    slog.Info("POST:")
    slog.Info("Encrypt: ",slog.Any("Input :", &e))

    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return err
    }

	w.WriteHeader(http.StatusOK)
	return nil
}

func (h *statusHandler) putRequest(w http.ResponseWriter, r *http.Request)  error {
    slog.Info("PUT Request")

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		slog.Error("err %q\n", err)
	}

	text := string(body[:])
	//fmt.Println(text)
    slog.Info("PUT Request:"+text)

	w.WriteHeader(http.StatusOK)
	return nil
}

func internalServerError(w http.ResponseWriter, r *http.Request) {
    slog.Error("Internal Server Error")
	w.WriteHeader(http.StatusInternalServerError)
	w.Write([]byte("internal server error"))
}

func notFound(w http.ResponseWriter, r *http.Request) {
    slog.Error("Not Found")
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte("not found"))
}

func main() {
	mux := http.NewServeMux()
	statusH := &statusHandler{
		store: &datastore{
			m: map[string]status{  // Initial Status Record
				"1": status{NoEncrypt: "1", NoDecrypt: "5", Version: "1.17.12", Doku: "https://gitlab.com/Alfred-Sabitzer/microk8s-ubuntu/-/tree/master/gpgsecret?ref_type=heads"},
			},
			RWMutex: &sync.RWMutex{},
		},
	}

    slog.Info("Starting Server")
	mux.Handle("/", statusH)
    err := http.ListenAndServe(":8080", mux)
	if err != nil {
	    slog.Error("error starting the server: %q", err)
	}
    slog.Info("Server Started")
}

