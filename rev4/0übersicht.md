<!-- 0übersicht.md — v2.0.0 — rev4, Teil 1: Rückmeldungen → Stand; v2.0.0: nach dem Review-Regelwerk (review-regelwerk.md RV-5a, E-013) neu gebaut: eine Tabelle Rückmeldung | umgesetzt? | Wo?, Fragen nur zu Punkten der Tabelle; Kennzahlen, Zählweise und Statuslegende entfallen (stehen im Zwischenbericht); Zeilen 1–12 inhaltlich wie v1.1.0 (Beleg-Tabelle BT-08 bis BT-25) -->
# Rückmeldungen → Stand der Umsetzung (Runde 4)

**Stand:** 12.10.2026 · **Version:** 2.0 · **Bezug:** Rückmeldungen vom 01.04., 20.04., 23.04. und 06.05.2026; Begleitdokumente in dieser Runde: Adress-Design 4.2 (`rev4/adress-design.md`), Entscheidungsprotokoll (`rev4/ENTSCHEIDUNGEN.md`, E-nnn), Schema (`schema.md`).

## A. Auf einen Blick

✓ Probelauf = im Datenbankprojekt bzw. Arbeitszweig umgesetzt und auf einer Probe-Datenbank geprüft. Die Team-Datenbank ist noch ohne Rollout.

| Nr | Rückmeldung (sinngemäß) | umgesetzt? | Wo? |
|---|---|---|---|
| 1 | Hinweise 1–7 (01.04.): Normalisierung, Fremdschlüssel und Löschweitergabe, Typzuordnung, Modell aus mehreren Tabellen, Datenzugriff getrennt vom Modell, Datenbankprojekt, Trigger | ✓ Probelauf | Arbeitszweig (Code); Datenbankprojekt: `schema.md` |
| 2 | Hinweis 8 (01.04.): Key-Index | – offen (B2) | E-008 |
| 3 | Kürzel in den Namen ausschreiben (20.04., 23.04.) | ✓ Probelauf: 49 Umbenennungen, Rückweg getestet; einzelne Kürzel bleiben vorerst | `schema.md` §3; Adress-Design §4.5; E-004 |
| 4 | Adress-Design: Anwendungsfälle, Logik, Datenbank (20.04.) | ✓ abgeschlossen: Fassung 4.2; Freigabe offen (B1) | Adress-Design §2–§4, §9 |
| 5 | Arbeitsweise: Anforderung → Spezifikation → Datenbank → Code, kein großer Prototyp (23.04.) | laufend: kleine Prüfläufe auf der Probe-Datenbank, Entscheidungsprotokoll | `ENTSCHEIDUNGEN.md` |
| 6 | Postleitzahl als Textfeld, Adressen mit Gültigkeitszeiträumen (06.05.) | ✓ abgeschlossen: unverändert übernommen | Adress-Design §3, §4.4 |
| 7 | Sportstätte: Verknüpfung mit der Aktivität fehlt (06.05.) | ✓ Probelauf: Vereinsobjekt ↔ Gruppe mit Beschreibung | Adress-Design §4.4 (`x_objekt_gruppe`); E-002 |
| 8 | Vereinsheim und Sportstätte zusammenführen; Vereinssitz (06.05.) | ✓ Probelauf: eine Tabelle mit Typ; Sitz als Kennzeichen, höchstens einer | Adress-Design §4.4 (`m_objekt`, `ist_sitz`), §7 #7; E-001, E-009 |
| 9 | Überlappende Adress-Zeiträume in der Datenbank verhindern (06.05.) | ✓ Probelauf: Überlappungsschutz und „Ende nach Beginn“, 10 von 10 Testfällen | Adress-Design §4.3, §4.4 (`tr_x_mitglied_adresse_no_overlap`); E-011 |
| 10 | Whitespace-Normalisierung der Adressen (06.05.) | zurückgestellt: optionale Phase 6 | Adress-Design §6.1, §7 #9; E-003 |
| 11 | Vereinssitz-Spalte bei den Gruppen entfällt (Folge aus 8) | ✓ Probelauf: aus dem Datenbankprojekt entfernt, Spalte war leer | Adress-Design §9, §10 |
| 12 | Gruppenverwaltung | ✓ Probelauf: Umbenennung übernommen, Regressionstest ohne Namensfehler | Arbeitszweig (Code) |

Stand je Punkt mit Probelauf und Team-Datenbank: Adress-Design §10.

## B. Offen

| Nr | Frage | Vorschlag |
|---|---|---|
| B1 | Freigabe der Adress-Konzepte (Adress-Design 4.2)? | freigeben; Datenzugriff und Oberfläche für Adressen und Sportstätten setzen die Freigabe voraus |
| B2 | Hinweis 8 („Key-Index“): Indizes auf Status und „erledigt“ oder eine Key-Index-Tabelle? | Indizes anlegen (vorläufig entschieden, E-008) |

Weitere Fragen (Rolle „Leser“, Rollen-Zuweisung, Austrittsdatum, Überzahlung) stehen im Zwischenbericht, Abschnitt 4.
