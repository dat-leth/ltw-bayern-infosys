# Wahl Informationssystem

## Lokale Ausführung

Zum lokalen Ausführen muss das docker-compose file `./src/docker-compose.yaml` ausgeführt werden. Gestartet werden dadurch die Datenbank und der postgREST Server.

```shell
$ cd ./src
$ docker-compose up 
```

Das Starten der Datenbank startet außerdem deren Initialisierung. Die Initialisierung erstellt zuerst alle Tabellen und Views und startet danach die Generierung der Einzelstimmen.

Das Frontend kann dann mittels npm gestartet werden. Solange sich die Datenbank in der Initialisierung befindet, antwortet auch der postgREST Dienst nicht.

```shell
$ cd ./src/web
$ npm install
$ npm run dev 
```

Anschließend kann das Frontend unter [http://localhost:3000/overview](http://localhost:3000/overview) zugegriffen werden.