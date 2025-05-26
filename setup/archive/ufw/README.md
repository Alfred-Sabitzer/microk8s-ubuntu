# UFW - Uncomplicated Firewall

Dokumentation aller Schritte und Einstellungen, die für die Firewall notwendig sind.
Siehe auch https://wiki.ubuntuusers.de/ufw/ 

## Profiles
Ich habe ein paar Profiles von https://github.com/ageis/ufw-application-profiles geholt.

## Einrichtung
Die UFW sollte standardmäßig am System vorhanden sein.
Wir enablen mal, das was da ist:)

```bash
sudo ufw status
sudo ufw enable
sudo ufw status
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw status
```
Danach laden wir ein paar Profiles.

```bash
sudo cp ./ufw-profiles/applications.d/IMAP /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/IMAPS /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/POP3 /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/POP3S /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/submission /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/submissions /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/WWW /etc/ufw/applications.d/
sudo cp ./ufw-profiles/applications.d/DKIM /etc/ufw/applications.d/
```

Danach prüfen wir, welche Settings vorhanden sind.

```bash
sudo ufw app list
Available applications:
  DKIM
  IMAP
  IMAPS
  Mail submission
  Mail submissionS
  OpenSSH
  POP3
  POP3S
  WWW
  WWW Cache
  WWW Full
  WWW Secure
```

Jetzt können wir die Applikationen enablen.

```bash
sudo ufw allow IMAP
sudo ufw allow IMAPS
sudo ufw allow 'Mail submission'
sudo ufw allow POP3
sudo ufw allow POP3S
sudo ufw allow 'WWW Full'
sudo ufw allow 'WWW Cache'
sudo ufw allow submission
sudo ufw allow submissions
sudo ufw allow DKIM
```

Für Kubernetes brauchen wir aber noch ein paar Regeln.

```bash
sudo ufw allow from 127.0.0.1
sudo ufw allow from 10.1.0.0/24
```

Für den NFS-Server brauchen auch noch ein paar Regeln.

```bash
sudo ufw allow from 10.0.2.15/24 to any port nfs
sudo ufw allow from 127.0.0.1 to any port nfs
```

Nun überprüfen wir den Status.

```bash
sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
Anywhere on cni0           ALLOW       Anywhere                  
OpenSSH                    ALLOW       Anywhere                  
IMAP                       ALLOW       Anywhere                  
IMAPS                      ALLOW       Anywhere                  
Mail submission            ALLOW       Anywhere                  
POP3                       ALLOW       Anywhere                  
POP3S                      ALLOW       Anywhere                  
WWW                        ALLOW       Anywhere                  
WWW Secure                 ALLOW       Anywhere                  
WWW Full                   ALLOW       Anywhere                  
WWW Cache                  ALLOW       Anywhere                  
Anywhere                   ALLOW       127.0.0.1                 
Anywhere                   ALLOW       10.1.0.0/16               
2049                       ALLOW       10.0.2.0/24               
2049                       ALLOW       127.0.0.1                 
Anywhere                   ALLOW       10.1.0.0/24               
Anywhere on vxlan.calico   ALLOW       Anywhere                  
Anywhere on cali+          ALLOW       Anywhere                  
587/tcp                    ALLOW       Anywhere                  
465/tcp                    ALLOW       Anywhere                  
DKIM                       ALLOW       Anywhere                  
Anywhere (v6) on cni0      ALLOW       Anywhere (v6)             
OpenSSH (v6)               ALLOW       Anywhere (v6)             
IMAP (v6)                  ALLOW       Anywhere (v6)             
IMAPS (v6)                 ALLOW       Anywhere (v6)             
Mail submission (v6)       ALLOW       Anywhere (v6)             
POP3 (v6)                  ALLOW       Anywhere (v6)             
POP3S (v6)                 ALLOW       Anywhere (v6)             
WWW (v6)                   ALLOW       Anywhere (v6)             
WWW Secure (v6)            ALLOW       Anywhere (v6)             
WWW Full (v6)              ALLOW       Anywhere (v6)             
WWW Cache (v6)             ALLOW       Anywhere (v6)             
Anywhere (v6) on vxlan.calico ALLOW       Anywhere (v6)             
Anywhere (v6) on cali+     ALLOW       Anywhere (v6)             
587/tcp (v6)               ALLOW       Anywhere (v6)             
465/tcp (v6)               ALLOW       Anywhere (v6)             
DKIM (v6)                  ALLOW       Anywhere (v6)             

Anywhere                   ALLOW OUT   Anywhere on cni0          
Anywhere                   ALLOW OUT   Anywhere on vxlan.calico  
Anywhere                   ALLOW OUT   Anywhere on cali+         
Anywhere (v6)              ALLOW OUT   Anywhere (v6) on cni0     
Anywhere (v6)              ALLOW OUT   Anywhere (v6) on vxlan.calico
Anywhere (v6)              ALLOW OUT   Anywhere (v6) on cali+    
```
Jetzt sollte der Server einigermaßen sicher sein.

Man kann auch die offenen Ports prüfen.

```bash
sudo lsof -i -P -n | grep LISTEN
sudo netstat -tulpn | grep LISTEN
sudo ss -tulpn | grep LISTEN
sudo lsof -i:22 ## see a specific port such as 22 ##
# Wenn nmap vorhanden
sudo nmap -sTU -O 89.58.16.23 
```

Happy Hacking
