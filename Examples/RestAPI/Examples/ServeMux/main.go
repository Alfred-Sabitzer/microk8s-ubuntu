package main

import (
	"encoding/json"
	"net/http"
	"regexp"
	"sync"

	"golang.org/x/exp/slog"
 //   "github.com/gorilla/mux"
)

var (
	listUserRe   = regexp.MustCompile(`^\/users[\/]*$`)
	getUserRe    = regexp.MustCompile(`^\/users\/(\d+)$`)
	createUserRe = regexp.MustCompile(`^\/users[\/]*$`)
)

type user struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type datastore struct {
	m map[string]user
	*sync.RWMutex
}

type userHandler struct {
	store *datastore
}

func (h *userHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	switch {
	case r.Method == http.MethodGet && listUserRe.MatchString(r.URL.Path):
		h.List(w, r)
		return
	case r.Method == http.MethodGet && getUserRe.MatchString(r.URL.Path):
		h.Get(w, r)
		return
	case r.Method == http.MethodPost && createUserRe.MatchString(r.URL.Path):
		h.Create(w, r)
		return
	default:
		notFound(w, r)
		return
	}
}

func (h *userHandler) List(w http.ResponseWriter, r *http.Request) {
	h.store.RLock()
	users := make([]user, 0, len(h.store.m))
	for _, v := range h.store.m {
		users = append(users, v)
	}
	h.store.RUnlock()
	jsonBytes, err := json.Marshal(users)
	if err != nil {
		internalServerError(w, r)
		return
	}
    slog.Info("List OK")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonBytes)
}

func (h *userHandler) Get(w http.ResponseWriter, r *http.Request) {
	matches := getUserRe.FindStringSubmatch(r.URL.Path)
	if len(matches) < 2 {
		notFound(w, r)
		return
	}
	h.store.RLock()
	u, ok := h.store.m[matches[1]]
	h.store.RUnlock()
	if !ok {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte("user not found"))
		return
	}
	jsonBytes, err := json.Marshal(u)
	if err != nil {
		internalServerError(w, r)
		return
	}
    slog.Info("Get OK")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonBytes)
}

func (h *userHandler) Create(w http.ResponseWriter, r *http.Request) {
	var u user
	if err := json.NewDecoder(r.Body).Decode(&u); err != nil {
		internalServerError(w, r)
		return
	}
	h.store.Lock()
	h.store.m[u.ID] = u
	h.store.Unlock()
	jsonBytes, err := json.Marshal(u)
	if err != nil {
		internalServerError(w, r)
		return
	}
    slog.Info("Create OK")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonBytes)
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
	userH := &userHandler{
		store: &datastore{
			m: map[string]user{
				"1": user{ID: "1", Name: "bob"},
			},
			RWMutex: &sync.RWMutex{},
		},
	}
	mux.Handle("/users", userH)
	mux.Handle("/users/", userH)
    slog.Info("Starting Server")
	http.ListenAndServe(":80", mux)
    slog.Info("End Service")
}
