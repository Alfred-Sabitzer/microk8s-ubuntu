package main

import (
//	"errors"
//	"path/filepath"
//	"compress/gzip"
    "fmt"
	"io"
    "io/ioutil"
	"os"
    "encoding/base64"
	"time"
    "bytes"
	"net/http"
	"encoding/json"
	"sync"
	"regexp"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	_ "crypto/sha256"
	_ "golang.org/x/crypto/ripemd160"
	"golang.org/x/crypto/openpgp"
	"golang.org/x/crypto/openpgp/armor"
	"golang.org/x/crypto/openpgp/packet"

	"golang.org/x/exp/slog"

)

const fname = "./data/gpgservice"
var to *openpgp.Entity

// Check if filename exists
func Exists(name string) (bool, error) {
  //fmt.Println(name)
  _, err := os.Stat(name)
  //fmt.Println(err)
  if os.IsNotExist(err) {
    slog.Error("%s does not exists %s\n",name,err)
    return false, nil
  }
  return err == nil, err
}

func encodePrivateKey(out io.Writer, key *rsa.PrivateKey) {
	w, err := armor.Encode(out, openpgp.PrivateKeyType, make(map[string]string))
	if err != nil {
        slog.Error("Encode not possible \n",err)
	}

	pgpKey := packet.NewRSAPrivateKey(time.Now(), key)
    err = pgpKey.Serialize(w)
	if err != nil {
        slog.Error("pgpKey.Serialize \n",err)
	}
    w.Close()
}

func encodePublicKey(out io.Writer, key *rsa.PrivateKey) {
	w, err := armor.Encode(out, openpgp.PublicKeyType, make(map[string]string))
	if err != nil {
        slog.Error("armor.Encode \n",err)
	}

	pgpKey := packet.NewRSAPublicKey(time.Now(), &key.PublicKey)
    err = pgpKey.Serialize(w)
	if err != nil {
        slog.Error("pgpKey.Serialize \n",err)
	}
    w.Close()
}

func decodePrivateKey(filename string) *packet.PrivateKey {

	// open ascii armored private key
	in, err := os.Open(filename)
	if err != nil {
        slog.Error("os.Open %s %s \n",filename,err)
	}
	defer in.Close()

	block, err := armor.Decode(in)
	if err != nil {
        slog.Error("armor.Decode %s \n",err)
	}

	if block.Type != openpgp.PrivateKeyType {
        slog.Error("Invalid private key file")
	}
	reader := packet.NewReader(block.Body)
	pkt, err := reader.Next()
	if err != nil {
        slog.Error("reader.Next %s \n",err)
	}

	key, ok := pkt.(*packet.PrivateKey)
	if !ok {
        slog.Error("Invalid private key")
	}
	return key
}

func decodePublicKey(filename string) *packet.PublicKey {

	// open ascii armored public key
	in, err := os.Open(filename)
	if err != nil {
        slog.Error("os.Open %s %s \n",filename,err)
	}
	defer in.Close()

	block, err := armor.Decode(in)
	if err != nil {
        slog.Error("armor.Decode %s \n",err)
	}

	if block.Type != openpgp.PublicKeyType {
        slog.Error("Invalid private key file")
	}

	reader := packet.NewReader(block.Body)
	pkt, err := reader.Next()
	if err != nil {
        slog.Error("reader.Next %s \n",err)
	}
	key, ok := pkt.(*packet.PublicKey)
	if !ok {
        slog.Error("Invalid public key \n")
	}
	return key
}

func generateKeys() {

	key, err := rsa.GenerateKey(rand.Reader, 4096)
	if err != nil {
        slog.Error("rsa.GenerateKey %s \n",err)
	}

	priv, err := os.Create(fname+".privkey")
	if err != nil {
        slog.Error("os.Create %s %s \n",fname+".privkey",err)
	}
	defer priv.Close()

	pub, err := os.Create(fname+".pubkey")
	if err != nil {
        slog.Error("os.Create %s %s \n",fname+".pubkey",err)
	}
    defer pub.Close()

	encodePrivateKey(priv, key)
	encodePublicKey(pub, key)
}

func createEntityFromKeys(pubKey *packet.PublicKey, privKey *packet.PrivateKey) *openpgp.Entity {
	config := packet.Config{
		DefaultHash:            crypto.SHA256,
		DefaultCipher:          packet.CipherAES256,
		DefaultCompressionAlgo: packet.CompressionZLIB,
		CompressionConfig: &packet.CompressionConfig{
			Level: 9,
		},
		RSABits: 4096,
	}
	currentTime := config.Now()
	uid := packet.NewUserId("", "", "")

	e := openpgp.Entity{
		PrimaryKey: pubKey,
		PrivateKey: privKey,
		Identities: make(map[string]*openpgp.Identity),
	}
	isPrimaryId := false

	e.Identities[uid.Id] = &openpgp.Identity{
		Name:   uid.Name,
		UserId: uid,
		SelfSignature: &packet.Signature{
			CreationTime: currentTime,
			SigType:      packet.SigTypePositiveCert,
			PubKeyAlgo:   packet.PubKeyAlgoRSA,
			Hash:         config.Hash(),
			IsPrimaryId:  &isPrimaryId,
			FlagsValid:   true,
			FlagSign:     true,
			FlagCertify:  true,
			IssuerKeyId:  &e.PrimaryKey.KeyId,
		},
	}

	keyLifetimeSecs := uint32(86400 * 365 * 10)

	e.Subkeys = make([]openpgp.Subkey, 1)
	e.Subkeys[0] = openpgp.Subkey{
		PublicKey: pubKey,
		PrivateKey: privKey,
		Sig: &packet.Signature{
			CreationTime:              currentTime,
			SigType:                   packet.SigTypeSubkeyBinding,
			PubKeyAlgo:                packet.PubKeyAlgoRSA,
			Hash:                      config.Hash(),
			PreferredHash:             []uint8{8}, // SHA-256
			FlagsValid:                true,
			FlagEncryptStorage:        true,
			FlagEncryptCommunications: true,
			IssuerKeyId:               &e.PrimaryKey.KeyId,
			KeyLifetimeSecs:           &keyLifetimeSecs,
		},
	}
	return &e
}

// Encrypt Message - always base64 encoded
func encrypt(message string)  string {
    var b bytes.Buffer
// Armor Message
  	w, err := armor.Encode(&b, "Message", nil)
	if err != nil {
        slog.Error("armor.Encode %s \n",err)
	}
// Encrypt Message
	plain, err := openpgp.Encrypt(w, []*openpgp.Entity{to}, nil, nil, nil)
	if err != nil {
        slog.Error("openpgp.Encrypt %s \n",err)
	}
    _, err = plain.Write([]byte(message))
	if err != nil {
        slog.Error("plain.Write %s \n",err)
	}
    plain.Close()
 	w.Close()
//    fmt.Println(&b)
// encode to base64
    bytes, err := ioutil.ReadAll(&b)
    if err != nil {
        slog.Error("ioutil.ReadAll %s \n",err)
    }
    encStr := base64.StdEncoding.EncodeToString(bytes)
//    fmt.Println(b.String())
    return encStr
}

// Decrypt Message - always base64 encoded
func decrypt(message string)  string {
// Decode Base64
    data, err := base64.StdEncoding.DecodeString(message)
    if err != nil {
        slog.Error("base64.StdEncoding.DecodeString %s \n",err)
    }
//    fmt.Printf("\ndata: %q\n", data)
    b := bytes.NewBuffer([]byte(data))
//    fmt.Println(&b)
// Armor decode
    block, err := armor.Decode(b)
	if err != nil {
        slog.Error("armor.Decode %s \n",err)
	}
//  fmt.Println("\nblock.Type %s \n", block.Type)
//  fmt.Println("\narmor.decode %s \n", block.Body)
//  fmt.Println("\nb %s \n",  b.String())
	if block.Type != "Message" {
        slog.Error("Invalid Block Type")
	}
// Decrypt Message
	var entityList openpgp.EntityList
	entityList = append(entityList, to)
	md, err := openpgp.ReadMessage(block.Body, entityList, nil, nil)
	if err != nil {
        slog.Error("openpgp.ReadMessage %s \n",err)
	}

//	fmt.Println("\nmd.UnverifiedBody %qs \n", &md.UnverifiedBody)
	var m bytes.Buffer
    _, err = io.Copy(&m, md.UnverifiedBody)
	if err != nil {
        slog.Error("io.Copy %s \n",err)
	}
//  fmt.Println("\nDecrypted %d bytes\n", n)
//	fmt.Println("\nb %s \n", m.String())

    encStr := base64.StdEncoding.EncodeToString([]byte(m.String()))
    return encStr
}

// test funcktion
func test() {
    message:="see https://www.cs.utexas.edu/~mitra/honors/soln.html\n"+
    "Choose p = 3 and q = 11 \n" +
    "Compute n = p * q = 3 * 11 = 33 \n" +
    "Compute φ(n) = (p - 1) * (q - 1) = 2 * 10 = 20 \n" +
    "Choose e such that 1 < e < φ(n) and e and φ (n) are coprime. Let e = 7 \n" +
    "Compute a value for d such that (d * e) % φ(n) = 1. One solution is d = 3 [(3 * 7) % 20 = 1] \n" +
    "Public key is (e, n) => (7, 33) \n" +
    "Private key is (d, n) => (3, 33) \n" +
    "The encryption of m = 2 is c = 2^7 % 33 = 29 \n" +
    "The decryption of c = 29 is m = 29^3 % 33 = 2 \n"

    fmt.Println("\nmessage: \n", message)
    encryptedmessage:=encrypt(message)
    fmt.Println("\nencrypted message: \n", encryptedmessage)
    decryptedmessage:=decrypt(encryptedmessage)
    fmt.Println("\ndecrypted message: \n", decryptedmessage)
}

var (
	url  = regexp.MustCompile(`^\/[\/]*$`)
	encodeUrl  = regexp.MustCompile(`^\/encode`)
	decodeUrl = regexp.MustCompile(`^\/decode`)
	healthzUrl = regexp.MustCompile(`^\/healthz`)
)

type msg struct {
 	Message  string `json:"message"`
}

type healthz struct {
 	Version   string `json:"version"`
 	Doku string `json:"doku"`
}

type datastore struct {
	m map[string]healthz
	*sync.RWMutex
}

type healthzHandler struct {
	store *datastore
}

func (h *healthzHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	slog.Info("healthzHandler",slog.Any(" r.Method ", r.Method),slog.Any(" URL ", r.URL))
	switch {
	case r.Method == http.MethodGet && url.MatchString(r.URL.Path):
    	//slog.Info("GET ServeHTTP")
		h.getRequest(w, r)
		return
	case r.Method == http.MethodGet && healthzUrl.MatchString(r.URL.Path):
    	//slog.Info("GET healthzUrl")
		h.healthzRequest(w, r)
		return
	case r.Method == http.MethodPost && encodeUrl.MatchString(r.URL.Path):
    	//slog.Info("ENCODE ServeHTTP")
		h.encodeRequest(w, r)
		return
	case r.Method == http.MethodPost && decodeUrl.MatchString(r.URL.Path):
    	//slog.Info("DECODE ServeHTTP")
		h.decodeRequest(w, r)
		return
	default:
		notFound(w, r)
		return
	}
}

// This is the standard answer, can be used as health-check
func (h *healthzHandler) getRequest(w http.ResponseWriter, r *http.Request)  error {
//    slog.Info("GET Request")

    type Client struct {
        Message string
    }

    type Connection struct {
        Clients []Client
    }

    var clients []Client
    clients = append(clients, Client{
        Message: "All messages are base64 encoded",
    })
    clients = append(clients, Client{
        Message: "eg. curl -X POST -H 'content-type: application/json' --data 'eyJDbGllbnRzIjpbeyJNZXNzYWdlIjoiTWVzc2FnZTEifSx7Ik1lc3NhZ2UiOiJNZXNzYWdlMiJ9XX0=' http://localhost/encrypt",
    })

    // add more if you want ...

    JsonBytes, err := json.Marshal(Connection{Clients:clients})
	if err != nil {
		slog.Error("json.Marshal %q\n", err)
		internalServerError(w, r)
		return err
	}
	w.WriteHeader(http.StatusOK)
//    slog.Info("Bytes:",slog.Any("GetRequest:",JsonBytes))
    encStr := base64.StdEncoding.EncodeToString(JsonBytes)
	w.Write([]byte(encStr))
	return nil
}

// healthz
func (h *healthzHandler) healthzRequest(w http.ResponseWriter, r *http.Request)  error {
//    slog.Info("healthz Request")

    JsonBytes, err := json.Marshal(h.store.m)
	if err != nil {
		slog.Error("json.Marshal %q\n", err)
		internalServerError(w, r)
		return err
	}
	w.WriteHeader(http.StatusOK)
    //slog.Info("Bytes:",slog.Any("GetRequest:",JsonBytes))
    encStr := base64.StdEncoding.EncodeToString(JsonBytes)
	w.Write([]byte(encStr))
	return nil
}

func (h *healthzHandler) encodeRequest(w http.ResponseWriter, r *http.Request)  error {
//    slog.Info("ENCODE Request")
    var m msg
//    slog.Info("r.Body:",slog.Any("Body:",&r.Body))
    err := json.NewDecoder(r.Body).Decode(&m)
    if err != nil {
		slog.Error("json.NewDecoder %q\n", err)
        internalServerError(w, r)
        return err
    }
//    slog.Info("Message:",slog.Any("message:",m.Message))
    secret:=m.Message
//    slog.Info("Secret:",secret)
    data, err := base64.StdEncoding.DecodeString(secret)
    if err != nil {
        slog.Error("base64.StdEncoding.DecodeString %s \n",err)
    }
    encryptedmessage:=encrypt(string(data))
//  slog.Info("encryptedmessage:",encryptedmessage)
	w.WriteHeader(http.StatusOK)
    w.Write([]byte(encryptedmessage))
	return nil
}

func (h *healthzHandler) decodeRequest(w http.ResponseWriter, r *http.Request)  error {
//    slog.Info("DECODE Request")

    var m msg
//    slog.Info("r.Body:",slog.Any("Body:",&r.Body))
    err := json.NewDecoder(r.Body).Decode(&m)
    if err != nil {
		slog.Error("json.NewDecoder %q\n", err)
        internalServerError(w, r)
        return err
    }
//    slog.Info("Message:",slog.Any("message:",m.Message))
    secret:=m.Message
//    slog.Info("Secret:",secret)
    decryptedmessage:=decrypt(string(secret))
//    slog.Info("decryptedmessage:",decryptedmessage)
	w.WriteHeader(http.StatusOK)
    w.Write([]byte(decryptedmessage))
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

// Check Existence of Keys
    slog.Info("Check Existence of Keys")
    existpriv, err := Exists(fname+".privkey")
	if err != nil {
        slog.Error("Exists %s %s \n",fname+".privkey",err)
	}

    existpub, err := Exists(fname+".pubkey")
	if err != nil {
        slog.Error("Exists %s %s \n",fname+".pubkey",err)
	}

    if existpriv && existpub {
        slog.Info("Keyfile file exists -- All Good")
    } else {
        slog.Info("Keyfile will be created")
    	generateKeys()
    }
// read Keys in Memory
	priv := decodePrivateKey(fname+".privkey")
	pub := decodePublicKey(fname+".pubkey")
	to = createEntityFromKeys(pub, priv)
    slog.Info("Entity ", slog.Any("to:",to))
 //    test()

    slog.Info("Start Service")

    mux := http.NewServeMux()

	healthzH := &healthzHandler{
		store: &datastore{
			m: map[string]healthz{  // Initial Status Record
				"1": healthz{Version: "2025-03-01", Doku: "https://gitlab.com/Alfred-Sabitzer/microk8s-ubuntu/-/tree/master/gpgsecret?ref_type=heads"},
			},
			RWMutex: &sync.RWMutex{},
		},
	}

    slog.Info("Starting Server")
	mux.Handle("/", healthzH)

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
            w.WriteHeader(200)
            w.Write([]byte("ok"))
        })

    err = http.ListenAndServe(":8080", mux)
	if err != nil {
	    slog.Error("error starting the server: %q", err)
	}
    slog.Info("End Service")
}
