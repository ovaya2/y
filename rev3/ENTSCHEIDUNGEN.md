<!-- ENTSCHEIDUNGEN.md — v1.0.0 — Erstfassung E-001 bis E-008 (Stand 01.10.2026, vorläufig) -->
# yam2 — Entscheidungsprotokoll

Klassen: A klar und klein · B klar, aber wirksam (Spike, nicht veröffentlichen) · C fachlich (nur Vorschlag, Gino entscheidet).
Einträge werden nur ersetzt, nicht überschrieben.

## E-001 — Vereinssitz        [Klasse B · Status: entschieden]
Gino-Bezug:         Adress-Design §7 #7
Entscheidung:       Flag `ist_sitz` + Filter-Unique-Index.
Begründung:         Genau ein Sitz pro Verein lässt sich per Index erzwingen, ohne neuen Objekttyp.
Nächste Alternative: eigener Objekttyp „Vereinssitz“ · Wechselaufwand: offen · Auslöser: Sitz braucht eigene Attribute
Umsetzung/Test:     noch kein Spike
Rückweg:            Spike-Branch verwerfen, Probe-DB neu aufbauen
Review bis:         offen · Vertrauen: mittel

## E-002 — Objekt-Beschreibung        [Klasse A · Status: entschieden]
Gino-Bezug:         Adress-Design §7 #8
Entscheidung:       Freitext.
Begründung:         Strukturierte Belegung wäre ein Mini-Buchungssystem (Nicht-Ziel §8).
Nächste Alternative: Spalten Wochentag/von/bis · Wechselaufwand: offen · Auslöser: Belegung muss abfragbar sein
Umsetzung/Test:     noch keine
Rückweg:            Entscheidung ersetzen
Review bis:         offen · Vertrauen: hoch

## E-003 — Whitespace-Normalisierung        [Klasse A · Status: entschieden]
Gino-Bezug:         Adress-Design §7 #9
Entscheidung:       Als Phase 6, nach stabiler Hauptmigration.
Begründung:         Erst die Migration stabilisieren, Normalisierung ändert Daten nur kosmetisch.
Nächste Alternative: weglassen · Wechselaufwand: keiner · Auslöser: Aufwand zu hoch
Umsetzung/Test:     noch keine
Rückweg:            Entscheidung ersetzen
Review bis:         offen · Vertrauen: hoch

## E-004 — `m_gl` → `m_mitglied`, `gl_id` → `mitglied_id`        [Klasse B · Status: entschieden]
Gino-Bezug:         Adress-Design §7 #1
Entscheidung:       Ja, als getrennte Migration nach Adress-Abschluss.
Begründung:         Trennt zwei große Änderungen und hält jeden Rückweg einzeln testbar.
Nächste Alternative: jetzt vorziehen, Adress-DDL gleich mit `mitglied_id` · Wechselaufwand: offen · Auslöser: Adress-DDL startet vor Abschluss
Umsetzung/Test:     noch kein Spike
Rückweg:            Rollback-Skript nach Muster `tools/rename-rollback.sql`
Review bis:         offen · Vertrauen: mittel

## E-005 — Rolle „Leser“ hat `member.create`, `fee.create`        [Klasse C · Status: Vorschlag, Gino entscheidet]
Gino-Bezug:         Beobachtung S8.3 (01.10.2026)
Entscheidung:       Offen. Option 1: Rechte entziehen (Beschreibung sagt „Lesezugriff“). Option 2: Beschreibung anpassen.
Begründung:         Rechte-Politik ist Fachregel.
Nächste Alternative: Beschreibung anpassen · Wechselaufwand: eine Seed-Zeile · Auslöser: Ginos Antwort
Umsetzung/Test:     keine
Rückweg:            entfällt
Review bis:         Ginos Antwort · Vertrauen: mittel

## E-006 — Rollen-Zuweisung an Benutzer fehlt in der UI        [Klasse C · Status: Vorschlag, Gino entscheidet]
Gino-Bezug:         Beobachtung S8.3 (01.10.2026)
Entscheidung:       Offen. Vorschlag: Mehrfachauswahl im Benutzer-Dialog.
Begründung:         Neues Feature, ändert, was Anwender tun dürfen.
Nächste Alternative: eigener Dialog „Rollen zuweisen“ · Wechselaufwand: offen · Auslöser: Ginos Antwort
Umsetzung/Test:     keine
Rückweg:            entfällt
Review bis:         Ginos Antwort · Vertrauen: mittel

## E-007 — Soll-Typ-Name statt ID in der Gebührenliste        [Klasse A · Status: entschieden]
Gino-Bezug:         Beobachtung S8.3 (01.10.2026)
Entscheidung:       Nach dem Rollout: Name per JOIN, read-only Property.
Begründung:         Reine Anzeige, keine Schreibwirkung; erst nach dem Rollout, damit die Umbenennung unverändert bleibt.
Nächste Alternative: ID beibehalten · Wechselaufwand: keiner · Auslöser: JOIN verlangsamt die Liste
Umsetzung/Test:     noch keine
Rückweg:            Commit zurücksetzen
Review bis:         offen · Vertrauen: hoch

## E-008 — Indizes auf `sta_id` (jetzt `status_id`), `erledigt`        [Klasse B · Status: entschieden]
Gino-Bezug:         Ginos Hinweis 8 (01.04.), Bedeutung „Index“ oder „Key-Index-Tabelle“ unklar
Entscheidung:       Indizes im SSDT-Projekt anlegen.
Begründung:         Häufig gefilterte Spalten; unklare Bedeutung von Hinweis 8, daher Review-Datum.
Nächste Alternative: zurückstellen · Wechselaufwand: keiner · Auslöser: Gino meint etwas anderes
Umsetzung/Test:     noch kein Spike
Rückweg:            Index-Datei entfernen, neu veröffentlichen
Review bis:         offen (Datum setzen) · Vertrauen: mittel
