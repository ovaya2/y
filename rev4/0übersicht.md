<!-- 0übersicht.md — v1.1.0 — rev4, Teil 1: Ginos Rückmeldungen und Stand der Umsetzung; v1.1.0: Befunde der unabhängigen Prüfung eingearbeitet (Statusdefinition, Zählweise, Team-Datenbank, Gruppierung) -->
# Rückmeldungen → Stand der Umsetzung

Übersicht zu den Rückmeldungen und Anforderungen aus den bisherigen Gesprächen mit Ergebnis und Status. Die Übersicht bleibt ohne Details; Nachweise liegen vor und werden auf Nachfrage erklärt.

Status in dieser Übersicht:

- **im Probelauf bestanden**: umgesetzt und auf einer Probe-Datenbank geprüft; die Team-Datenbank ist unverändert.
- **abgeschlossen**: Die Arbeit ist erledigt; eine noch offene Freigabe ist dabei angegeben.
- **wartet auf Entscheidung**: Rückmeldung von Gino nötig (Fragen im letzten Abschnitt).

Zählweise: Gezählt sind die einzelnen Punkte aus den Rückmeldungen, wie sie in Teil 1 aufgeführt sind; ein Punkt kann mehrere Arbeitsschritte bündeln.

## Überblick

| Kennzahl | Wert |
|---|---|
| Punkte aus den Rückmeldungen | 12 |
| im Probelauf bestanden | 7 |
| abgeschlossen (Freigabe der Konzepte offen) | 2 |
| wartet auf Entscheidung | 1 |
| zurückgestellt (vorläufig entschieden) | 1 |
| laufend | 1 |
| Fragen an Gino | 6 |
| Team-Datenbank | kein Rollout; Stand der alten Namen |

## Teil 1: Ginos Rückmeldungen → Stand

### Erste Rückmeldung (Hinweise zur Anwendung)

| Nr | Rückmeldung | Stand | Status |
|---|---|---|---|
| 1 | Hinweise 1 bis 7: Normalisierung, Fremdschlüssel und Löschweitergabe, Typzuordnung, Modell aus mehreren Tabellen, Trennung von Datenzugriff und Modell, Datenbankprojekt, Ausführung und Trigger | im Arbeitszweig eingearbeitet | im Probelauf bestanden |
| 2 | Hinweis 8: Indizes („Key-Index“) | Bedeutung ist ungeklärt; Frage 6 unten | wartet auf Entscheidung |

### Gespräch zur Adress-Anforderung

| Nr | Anforderung | Stand | Status |
|---|---|---|---|
| 3 | Kürzel in den Namen ausschreiben | 49 Umbenennungen in mehreren Wellen; Regressionstest ohne Namensfehler; Rückweg getestet; einzelne Kürzel bleiben vorerst bestehen | im Probelauf bestanden |
| 4 | Adress-Design: Anwendungsfälle, Logik, Datenbank-Design | Fassung nach der Rückmeldung zu Version 3 und Korrekturen aus eigener Prüfung liegen vor; der Nachzug der Namen und des Umsetzungsstands liegt als Entwurf vor | abgeschlossen; Freigabe der Konzepte offen |
| 5 | Arbeitsweise: Anforderung, Spezifikation, Datenbank, dann Code; kein großer Prototyp | eingehalten: kleine Prüfläufe auf der Probe-Datenbank, Freigabeschritte, Entscheidungsprotokoll | laufend |

### Rückmeldung zum Adress-Design (Version 3)

| Nr | Rückmeldung | Stand | Status |
|---|---|---|---|
| 6 | Postleitzahl als Textfeld mit Gültigkeitszeiträumen: bestätigt | unverändert übernommen | abgeschlossen |
| 7 | Sportstätte: Verknüpfung mit der Aktivität fehlte | Verknüpfung zwischen Vereinsobjekt und Gruppe mit Beschreibung; Prüfläufe bestanden | im Probelauf bestanden |
| 8 | Vereinsheim und Sportstätte zusammenführen; Vereinssitz | gemeinsame Tabelle für Vereinsobjekte mit Typ-Auswahl; der Vereinssitz ist ein Kennzeichen, die Datenbank erlaubt höchstens einen Sitz | im Probelauf bestanden |
| 9 | Überlappung von Adress-Zeiträumen in der Datenbank verhindern | Überlappungsschutz und Prüfung „Ende nach Beginn“; 10 von 10 Testfällen bestanden (Umzug bleibt erlaubt, Überlappung und leerer Zeitraum werden abgelehnt) | im Probelauf bestanden |
| 10 | Whitespace-Normalisierung (optional) | als spätere, optionale Phase vorgesehen; vorläufig entschieden, nicht umgesetzt | zurückgestellt |
| 11 | Vereinssitz-Spalte bei den Gruppen entfällt | aus dem Datenbankprojekt entfernt; die Spalte war leer; auf der Team-Datenbank erfolgt die Entfernung später in einem eigenen Schritt | im Probelauf bestanden |
### Weitere Aufgaben

| Nr | Aufgabe | Stand | Status |
|---|---|---|---|
| 12 | Gruppenverwaltung | Umbenennung im Arbeitszweig übernommen; Regressionstest ohne Namensfehler | im Probelauf bestanden |

## Wartet auf Gino

Format je Frage: Optionen, Empfehlung, Antwort „Ja“ oder Alternative.

| Nr | Frage | Optionen | Empfehlung |
|---|---|---|---|
| 1 | Freigabe der Adress-Konzepte (Adress-Design) | freigeben; oder Änderungswünsche nennen | Vorschlag: freigeben; die Anwendungsteile (Datenzugriff und Oberfläche) für Adressen und Sportstätten setzen die Freigabe voraus |
| 2 | Rolle „Leser“ darf Mitglieder und Gebühren anlegen: Fehler oder gewollt? | Rechte entziehen (die Beschreibung der Rolle lautet Lesezugriff); oder die Beschreibung anpassen | Vorschlag: Rechte entziehen |
| 3 | Rollen-Zuweisung an Benutzer fehlt in der Oberfläche (heute nur über die Datenbank) | Mehrfachauswahl im Benutzer-Dialog; oder eigener Dialog „Rollen zuweisen“ | Mehrfachauswahl im Benutzer-Dialog |
| 4 | Austrittsdatum: Beim Wechsel des Status auf „Ausgetreten“ über Bearbeiten bleibt das Datum leer | der Statuswechsel setzt das Datum; oder der Dialog verlangt das Datum | keine Empfehlung; fachliche Entscheidung |
| 5 | Zahlung und Gebühren: Eine Zahlung gehört zu genau einer Gebühr; eine Überzahlung wird als negativer Saldo gebucht | Überzahlung auf Gebühren verteilen; oder wie bisher als negativen Saldo führen | keine Empfehlung; fachliche Entscheidung |
| 6 | Hinweis 8 („Key-Index“): Was ist gemeint? | Indizes auf Status und „erledigt“ anlegen; oder eine Key-Index-Tabelle ist gemeint | Indizes anlegen (vorläufige Entscheidung) |

Dieses Dokument enthält Teil 1.
