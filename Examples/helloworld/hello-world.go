package main

// Ausgabe eines einfachen HTML-Files und ersetzen von Schlüsselwörtern mit konkreten Informationen
// Inspiration https://golang.org/doc/articles/wiki/
// https://www.socketloop.com/tutorials/golang-get-hardware-information-such-as-disk-memory-and-cpu-usage
//
// alfred@monitoring:~/GetInfo$ go get github.com/shirou/gopsutil/...

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/shirou/gopsutil/disk"
	"github.com/shirou/gopsutil/host"
	"github.com/shirou/gopsutil/mem"
)

type Page struct {
	Title string
	Body  []byte
}

func loadError(xerr string) (xhtml string) {
	var xs string
	currentTime := time.Now()
	xtext, err := ioutil.ReadFile("error.html")
	if err != nil {
		log.Fatal("Error File kann nicht geöffnet werden " + err.Error())
	}
	xs = strings.Replace(string(xtext), "%SYSTIME%", currentTime.Format("2006-01-02 15:04:05 Monday"), -1)
	xs = strings.Replace(string(xs), "%SYSTEMFEHLER%", xerr, -1)
	return xs
}

func loadPage(title string) (*Page, error) {
	var xhtml string
	var xtmp string
	var xenv string
	const GB = 1073741824

	if title == "" {
	    title = "hello"
	}
	filename := title + ".html"
	log.Println(filename)
	xhtml = ""

	currentTime := time.Now()
	f, err := os.Open(filename)

	if err != nil {
		log.Println(filename+" kann nicht geöffnet werden: ", err)
		xhtml = loadError(err.Error())
	} else {
		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			xtmp = scanner.Text()
			if strings.Contains(xtmp, "%SYSTIME%") {
				xtmp = strings.Replace(xtmp, "%SYSTIME%", currentTime.Format("2006-01-02 15:04:05 Monday"), -1)
			}
			if strings.Contains(xtmp, "%OSENVIRONMENT%") {
				xenv = ""
				for _, pair := range os.Environ() {
					variable := strings.Split(pair, "=")
					xenv += variable[0] + "=>" + variable[1] + "<br>"
				}
				xtmp = strings.Replace(xtmp, "%OSENVIRONMENT%", xenv, -1)
			}
			if strings.Contains(xtmp, "%DISKUSAGE%") {
				diskStat, err := disk.Usage("/")
				if err != nil {
					log.Println(" Plattenbelegung kann nicht gelesen werden: ", err)
				}
				xenv = "Pfad:" + diskStat.Path +
					"<br>FSTYPE:" + diskStat.Fstype +
					"<br>Total disk space:" + fmt.Sprintf("%5.1f", float64(diskStat.Total)/GB) +
					" GB<br>Free disk space:" + fmt.Sprintf("%5.1f", float64(diskStat.Free)/GB) +
					" GB<br>Used disk space:" + fmt.Sprintf("%5.1f", float64(diskStat.Used)/GB) +
					" GB<br>Used GB Prozent:" + fmt.Sprintf("%3.1f", diskStat.UsedPercent) +
					"<br>Used Inodes:" + strconv.FormatUint(diskStat.InodesUsed, 10) +
					"<br>Used Inodes Prozent:" + fmt.Sprintf("%3.1f", diskStat.InodesUsedPercent)
				xtmp = strings.Replace(xtmp, "%DISKUSAGE%", xenv, -1)
			}
			if strings.Contains(xtmp, "%HOSTINFO%") {
				// host or machine kernel, uptime, platform Info
				hostStat, err := host.Info()
				if err != nil {
					log.Println(" Hostinformation kann nicht gelesen werden: ", err)
				}
				xenv = "Hostname: " + hostStat.Hostname +
					"<br>OS: " + hostStat.OS +
					"<br>Platform: " + hostStat.Platform +
					"<br>Host ID(uuid): " + hostStat.HostID +
					"<br>Uptime (sec): " + strconv.FormatUint(hostStat.Uptime, 10) +
					"<br>Number of processes running: " + strconv.FormatUint(hostStat.Procs, 10)
				xtmp = strings.Replace(xtmp, "%HOSTINFO%", xenv, -1)
			}
			if strings.Contains(xtmp, "%MEMINFO%") {
				runtimeOS := runtime.GOOS
				vmStat, err := mem.VirtualMemory()
				if err != nil {
					log.Println(" Memoryinformation kann nicht gelesen werden: ", err)
				}
				xenv = "OS : " + runtimeOS +
					"<br>Total memory: " + fmt.Sprintf("%5.1f", float64(vmStat.Total)/GB) +
					" GB<br>Free memory: " + fmt.Sprintf("%5.1f", float64(vmStat.Free)/GB) +
					" GB<br>Used memory: " + fmt.Sprintf("%5.1f", float64(vmStat.Used)/GB) +
					" GB<br>Percentage used memory: " + strconv.FormatFloat(vmStat.UsedPercent, 'f', 2, 64)
				xtmp = strings.Replace(xtmp, "%MEMINFO%", xenv, -1)
			}
			xhtml += xtmp
		}
		if err := scanner.Err(); err != nil {
			log.Println(filename+" kann nicht gelesen werden: %s\n", err)
			xhtml = loadError(err.Error())
		}
	}
	defer f.Close()
	return &Page{Title: title, Body: []byte(xhtml)}, nil
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	title := r.URL.Path[len("/"):]
	log.Println("title:"+title+"\n")
	p, _ := loadPage(title)
	fmt.Fprintf(w, "%s", p.Body)
}

func main() {
	log.Println("Main Started")
	http.HandleFunc("/", viewHandler)
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
            w.WriteHeader(200)
            w.Write([]byte("ok"))
        })
	log.Fatal(http.ListenAndServe(":8080", nil))
	log.Println("Main End")
}
