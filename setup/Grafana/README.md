# Grafana einrichten

Für ein funktionierendes Grafana braucht es auch ein paar Reports.

## Vorbereitung

Grafana muß bereits lauffähig sein. Das admin-Passwort wurde bereits auf das entsprechende Secret geändert.
Dies geschieht im ClusterSetup/MicroK8SDashboard.sh

## Startskript

Die beiden Hilfsskripten können Reports aus Grafana lokal speichern, bzw. wieder in Grafana zurückladen.

```
./Export_all_Reports.sh
./Import_all_Reports.sh
```

Somit kann man selbst erstellte Reports an andere Grafana-Installationen weitergeben.
