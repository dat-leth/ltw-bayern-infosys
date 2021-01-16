# Stimmabgabe
## Organisatorischer Ablauf

0. Wahlhelfer*innen haben Wahl-PC vorkonfiguriert, besitzen Wahlregister für Wahllokal und haben Zugang als Wahlhelfer\*in zum Datenbanksystem.
1. Wahlberechtigte*r betritt Wahllokal.
2. Wahlhelfer*in prüft Wahlberechtigung und Ausweis, hakt im Register die Teilnahme an der Wahl ab, aktiviert die Personalausweisnummer für die Wahl im Wahllokal.
3. Wahlberechtigte*r trägt am Wahl-PC seine Personalausweisnummer ein, füllt Stimmzettel für Erst-/Zweitstimme aus und bestätigt seine Stimmen.
4. Wahlberechtigte*r verlässt das Wahllokal.
5. Wahl-PC setzt sich automatisch nach 5 Sekunden zurück.


## Technische Umsetzung
- Personalausweisnummer wird sha256-gehashed als Wahlabgabetoken mit Wahllokal gespeichert. Abgabestatus ist auf `false` (noch nicht abgegeben) gesetzt.
- Bei Bearbeiten der Anfrage an Stimmabgabe-Endpunkt wird in einer Transaktion geprüft, ob der Abgabestatus auf `true` (abgegeben) gesetzt werden kann. Falls in mindestens einem Fall nicht möglich, wird Transaktion zurückgesetzt. Ansonsten werden die Stimmen ohne Zurückführung auf Token/Personalausweisnummer/Person in Stimmentabelle gespeichert.