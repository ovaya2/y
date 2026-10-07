<!-- schema-diagramme.md — v2.0.0 — Neuaufbau aus dem Datenbankprojekt: 28 Tabellen, neue Gruppe Adressen/Vereinsobjekte, Löschverhalten berechnet -->
<!-- erzeugt mit tools/schema_extract.py 1.0.0 und tools/schema_render.py 1.0.0; Diagramme sind Mermaid -->

# yam3 — Datenbankschema-Diagramme

Schema: `[yam3]` | Quelle: Datenbankprojekt `yam2.Database`, Branch `feature/gruppe-sitzspalte-entfernen`, Stand `d1dfd1b` | Stand: 2026-10-07

Die Beschreibung der Tabellen und Spalten steht in `schema.md`. Dort steht auch die Zuordnung alter zu neuen Namen.

---

## 1. Gesamtübersicht (Tabellengruppen, Pfeil = „wird referenziert von“)

```mermaid
graph TD
    subgraph MASTER["Stammdaten"]
        m_mitglied["m_mitglied<br/>Mitglieder"]
        m_user["m_user<br/>Benutzer"]
        m_jump["m_jump<br/>Besuchsverlauf"]
        m_mark["m_mark<br/>Markierungen"]
    end
    subgraph FAKT["Finanzen"]
        f_soll["f_soll<br/>Gebühren (Soll)"]
        f_ist["f_ist<br/>Zahlungen (Ist)"]
    end
    subgraph LOOKUP["Lookups"]
        d_anrede["d_anrede<br/>Anreden"]
        d_status["d_status<br/>Mitgliedsstatus"]
        d_beitragsart["d_beitragsart<br/>Beitragsarten"]
        d_solltyp["d_solltyp<br/>Soll-Typen"]
        d_konto["d_konto<br/>Vereinskonten"]
        d_zahlungsart["d_zahlungsart<br/>Zahlungsarten"]
    end
    subgraph RBAC["Rechte (RBAC)"]
        d_role["d_role<br/>Rollen"]
        d_perm["d_perm<br/>Berechtigungen"]
        x_user_role["x_user_role<br/>Benutzer ↔ Rolle"]
        x_role_perm["x_role_perm<br/>Rolle ↔ Berechtigung"]
    end
    subgraph ZUORD["Gruppen und Funktionen"]
        d_gruppe["d_gruppe<br/>Gruppen / Abteilungen"]
        d_yfun["d_yfun<br/>Funktionen / Ämter"]
        x_gruppe_mitglied["x_gruppe_mitglied<br/>Mitglied ↔ Gruppe"]
        x_fa["x_fa<br/>Mitglied ↔ Funktion"]
    end
    subgraph ADR["Adressen"]
        d_land["d_land<br/>Länder"]
        d_ort["d_ort<br/>Orte / PLZ"]
        m_adresse["m_adresse<br/>Adressen"]
        x_mitglied_adresse["x_mitglied_adresse<br/>Mitglied ↔ Adresse"]
    end
    subgraph OBJ["Vereinsobjekte"]
        d_objekttyp["d_objekttyp<br/>Objekttypen"]
        m_objekt["m_objekt<br/>Vereinsobjekte"]
        x_objekt_gruppe["x_objekt_gruppe<br/>Objekt ↔ Gruppe"]
    end
    subgraph TECH["Technisch"]
        t_reg["t_reg<br/>App-Registry"]
    end
    d_anrede --> m_mitglied
    d_beitragsart --> f_soll
    d_beitragsart --> m_mitglied
    d_gruppe --> x_gruppe_mitglied
    d_gruppe --> x_objekt_gruppe
    d_konto --> f_ist
    d_land --> d_ort
    d_objekttyp --> m_objekt
    d_ort --> m_adresse
    d_perm --> x_role_perm
    d_role --> x_role_perm
    d_role --> x_user_role
    d_solltyp --> f_soll
    d_status --> m_mitglied
    d_yfun --> x_fa
    d_zahlungsart --> f_ist
    f_soll --> f_ist
    m_adresse --> m_objekt
    m_adresse --> x_mitglied_adresse
    m_mitglied --> f_soll
    m_mitglied --> m_jump
    m_mitglied --> m_mark
    m_mitglied --> m_user
    m_mitglied --> x_fa
    m_mitglied --> x_gruppe_mitglied
    m_mitglied --> x_mitglied_adresse
    m_objekt --> x_objekt_gruppe
    m_user --> m_jump
    m_user --> m_mark
    m_user --> x_user_role
```

---

## 2. Kern-Entitäten: Mitglieder, Gebühren, Zahlungen

```mermaid
erDiagram
    m_mitglied {
        int id PK
        nvarchar mitglied_nr UK
        int anrede_id FK
        nvarchar vorname
        nvarchar nachname
        date geburtsdatum
        nvarchar email
        nvarchar telefon
        nvarchar str
        nvarchar plz
        nvarchar ort
        nvarchar iban
        nvarchar bic
        nvarchar sepa_referenz
        date sepa_datum
        int status_id FK
        int beitragsart_id FK
        date eintritt
        date austritt
        bit dsgvo_einwilligung_daten
        bit dsgvo_einwilligung_foto
        datetime erstellt_am
        datetime geaendert_am
    }
    f_soll {
        int id PK
        int mitglied_id FK
        int beitragsart_id FK
        int solltyp_id FK
        int jahr
        decimal betrag
        nvarchar zweck
        date faellig
        bit erledigt
        uniqueidentifier batch_id
    }
    f_ist {
        int id PK
        int soll_id FK
        int konto_id FK
        int zahlungsart_id FK
        decimal betrag
        date datum
        nvarchar text
        uniqueidentifier batch_id
    }
    d_status {
        int id PK
        nvarchar bezeichnung
    }
    d_anrede {
        int id PK
        nvarchar bezeichnung
    }
    d_beitragsart {
        int id PK
        nvarchar bezeichnung
        decimal standard_betrag
    }
    d_solltyp {
        int id PK
        nvarchar bezeichnung
    }
    d_konto {
        int id PK
        nvarchar bezeichnung
        nvarchar iban
    }
    d_zahlungsart {
        int id PK
        nvarchar bezeichnung
    }
    d_anrede ||--o{ m_mitglied : "anrede_id"
    d_status ||--o{ m_mitglied : "status_id"
    d_beitragsart ||--o{ m_mitglied : "beitragsart_id"
    d_beitragsart ||--o{ f_soll : "beitragsart_id"
    d_solltyp ||--o{ f_soll : "solltyp_id"
    m_mitglied ||--o{ f_soll : "mitglied_id"
    d_konto ||--o{ f_ist : "konto_id"
    d_zahlungsart ||--o{ f_ist : "zahlungsart_id"
    f_soll |o--o{ f_ist : "soll_id"
```

---

## 3. Benutzerverwaltung und RBAC

```mermaid
erDiagram
    m_user {
        int id PK
        int mitglied_id FK
        nvarchar win_user UK
        bit is_admin
        datetime letzter_login
    }
    x_user_role {
        int user_id PK, FK
        int role_id PK, FK
        datetime zugewiesen_am
    }
    d_role {
        int id PK
        nvarchar bezeichnung UK
        nvarchar beschreibung
        bit is_superadmin
        bit is_system
    }
    x_role_perm {
        int role_id PK, FK
        int perm_id PK, FK
    }
    d_perm {
        int id PK
        nvarchar perm_key UK
        nvarchar modul
        nvarchar aktion
        nvarchar bezeichnung
    }
    m_jump {
        int id PK
        int u_id FK
        int mitglied_id FK
        datetime besucht_am
    }
    m_mark {
        int id PK
        int u_id FK
        int mitglied_id FK
        char mark_char
        datetime gesetz_am
    }
    m_mitglied {
        int id PK
        nvarchar mitglied_nr UK
        int anrede_id FK
        int status_id FK
        int beitragsart_id FK
    }
    m_mitglied |o--o{ m_user : "mitglied_id"
    d_role ||--o{ x_user_role : "role_id"
    m_user ||--o{ x_user_role : "user_id"
    d_perm ||--o{ x_role_perm : "perm_id"
    d_role ||--o{ x_role_perm : "role_id"
    m_mitglied ||--o{ m_jump : "mitglied_id"
    m_user ||--o{ m_jump : "u_id"
    m_mitglied ||--o{ m_mark : "mitglied_id"
    m_user ||--o{ m_mark : "u_id"
```

---

## 4. Gruppen, Funktionen und technische Tabellen

```mermaid
erDiagram
    d_gruppe {
        int id PK
        nvarchar bezeichnung
    }
    x_gruppe_mitglied {
        int mitglied_id PK, FK
        int gruppe_id PK, FK
        date seit
    }
    d_yfun {
        int id PK
        nvarchar bez
    }
    x_fa {
        int mitglied_id PK, FK
        int yfun_id PK, FK
        date wahl
    }
    t_reg {
        char reg_name PK
        nvarchar payload
        int u_id
        datetime geaendert_am
    }
    m_user {
        int id PK
        int mitglied_id FK
        nvarchar win_user UK
    }
    m_mitglied {
        int id PK
        nvarchar mitglied_nr UK
        int anrede_id FK
        int status_id FK
        int beitragsart_id FK
    }
    m_mitglied ||--o{ x_gruppe_mitglied : "mitglied_id"
    d_gruppe ||--o{ x_gruppe_mitglied : "gruppe_id"
    m_mitglied ||--o{ x_fa : "mitglied_id"
    d_yfun ||--o{ x_fa : "yfun_id"
    m_mitglied |o--o{ m_user : "mitglied_id"
```

---

## 5. Adressen und Vereinsobjekte

```mermaid
erDiagram
    d_land {
        int land_id PK
        char iso_code UK
        nvarchar bezeichnung
        nvarchar plz_regex
    }
    d_ort {
        int ort_id PK
        int land_id FK
        varchar plz
        nvarchar ort
        nvarchar bundesland
    }
    m_adresse {
        int adresse_id PK
        nvarchar strasse
        nvarchar hausnummer
        nvarchar adresszusatz
        int ort_id FK
        datetime2 erstellt_am
        nvarchar erstellt_von
    }
    x_mitglied_adresse {
        int mitglied_adresse_id PK
        int mitglied_id FK
        int adresse_id FK
        date gueltig_von
        date gueltig_bis
        datetime2 geaendert_am
        nvarchar geaendert_von
    }
    m_mitglied {
        int id PK
        nvarchar mitglied_nr UK
        int anrede_id FK
        int status_id FK
        int beitragsart_id FK
    }
    d_objekttyp {
        int objekttyp_id PK
        nvarchar bezeichnung UK
    }
    m_objekt {
        int objekt_id PK
        nvarchar bezeichnung
        int typ_id FK
        int adresse_id FK
        bit ist_sitz
        bit ist_vereinseigen
        nvarchar beschreibung
        bit aktiv
        datetime2 erstellt_am
        nvarchar erstellt_von
        datetime2 geaendert_am
        nvarchar geaendert_von
    }
    x_objekt_gruppe {
        int objekt_id PK, FK
        int ygrp_id PK, FK
        nvarchar beschreibung
        datetime2 erstellt_am
        nvarchar erstellt_von
    }
    d_gruppe {
        int id PK
    }
    d_land ||--o{ d_ort : "land_id"
    d_ort ||--o{ m_adresse : "ort_id"
    m_mitglied ||--o{ x_mitglied_adresse : "mitglied_id"
    m_adresse ||--o{ x_mitglied_adresse : "adresse_id"
    d_objekttyp ||--o{ m_objekt : "typ_id"
    m_adresse ||--o{ m_objekt : "adresse_id"
    m_objekt ||--o{ x_objekt_gruppe : "objekt_id"
    d_gruppe ||--o{ x_objekt_gruppe : "ygrp_id"
```

---

## 6. Löschverhalten (CASCADE und blockierende Verweise)

```mermaid
graph TD
    d_perm["d_perm<br/>Berechtigungen"]
    d_role["d_role<br/>Rollen"]
    f_ist["f_ist<br/>Zahlungen (Ist)"]
    f_soll["f_soll<br/>Gebühren (Soll)"]
    m_jump["m_jump<br/>Besuchsverlauf"]
    m_mark["m_mark<br/>Markierungen"]
    m_mitglied["m_mitglied<br/>Mitglieder"]
    m_objekt["m_objekt<br/>Vereinsobjekte"]
    m_user["m_user<br/>Benutzer"]
    x_fa["x_fa<br/>Mitglied ↔ Funktion"]
    x_gruppe_mitglied["x_gruppe_mitglied<br/>Mitglied ↔ Gruppe"]
    x_mitglied_adresse["x_mitglied_adresse<br/>Mitglied ↔ Adresse"]
    x_objekt_gruppe["x_objekt_gruppe<br/>Objekt ↔ Gruppe"]
    x_role_perm["x_role_perm<br/>Rolle ↔ Berechtigung"]
    x_user_role["x_user_role<br/>Benutzer ↔ Rolle"]
    d_perm -->|CASCADE| x_role_perm
    d_role -->|CASCADE| x_role_perm
    d_role -->|CASCADE| x_user_role
    m_mitglied -->|CASCADE| f_soll
    m_mitglied -->|CASCADE| m_jump
    m_mitglied -->|CASCADE| m_mark
    m_mitglied -->|CASCADE| x_fa
    m_mitglied -->|CASCADE| x_gruppe_mitglied
    m_objekt -->|CASCADE| x_objekt_gruppe
    m_user -->|CASCADE| x_user_role
    f_soll -.->|"NO ACTION: blockiert das Löschen"| f_ist
    m_mitglied -.->|"NO ACTION: blockiert das Löschen"| m_user
    m_mitglied -.->|"NO ACTION: blockiert das Löschen"| x_mitglied_adresse
    m_user -.->|"NO ACTION: blockiert das Löschen"| m_jump
    m_user -.->|"NO ACTION: blockiert das Löschen"| m_mark
    style d_perm fill:#2e1a1a,stroke:#e05252,color:#e05252
    style d_role fill:#2e1a1a,stroke:#e05252,color:#e05252
    style m_mitglied fill:#2e1a1a,stroke:#e05252,color:#e05252
    style m_objekt fill:#2e1a1a,stroke:#e05252,color:#e05252
    style m_user fill:#2e1a1a,stroke:#e05252,color:#e05252
```

---

## 7. FK-Referenzmatrix

| Von | Spalte | → Nach | ON DELETE |
|---|---|---|---|
| `d_ort` | `land_id` | `d_land.land_id` | NO ACTION |
| `f_ist` | `konto_id` | `d_konto.id` | NO ACTION |
| `f_ist` | `zahlungsart_id` | `d_zahlungsart.id` | NO ACTION |
| `f_ist` | `soll_id` | `f_soll.id` | NO ACTION |
| `f_soll` | `beitragsart_id` | `d_beitragsart.id` | NO ACTION |
| `f_soll` | `solltyp_id` | `d_solltyp.id` | NO ACTION |
| `f_soll` | `mitglied_id` | `m_mitglied.id` | **CASCADE** |
| `m_adresse` | `ort_id` | `d_ort.ort_id` | NO ACTION |
| `m_jump` | `mitglied_id` | `m_mitglied.id` | **CASCADE** |
| `m_jump` | `u_id` | `m_user.id` | NO ACTION |
| `m_mark` | `mitglied_id` | `m_mitglied.id` | **CASCADE** |
| `m_mark` | `u_id` | `m_user.id` | NO ACTION |
| `m_mitglied` | `anrede_id` | `d_anrede.id` | NO ACTION |
| `m_mitglied` | `status_id` | `d_status.id` | NO ACTION |
| `m_mitglied` | `beitragsart_id` | `d_beitragsart.id` | NO ACTION |
| `m_objekt` | `typ_id` | `d_objekttyp.objekttyp_id` | NO ACTION |
| `m_objekt` | `adresse_id` | `m_adresse.adresse_id` | NO ACTION |
| `m_user` | `mitglied_id` | `m_mitglied.id` | NO ACTION |
| `x_fa` | `mitglied_id` | `m_mitglied.id` | **CASCADE** |
| `x_fa` | `yfun_id` | `d_yfun.id` | NO ACTION |
| `x_gruppe_mitglied` | `mitglied_id` | `m_mitglied.id` | **CASCADE** |
| `x_gruppe_mitglied` | `gruppe_id` | `d_gruppe.id` | NO ACTION |
| `x_mitglied_adresse` | `mitglied_id` | `m_mitglied.id` | NO ACTION |
| `x_mitglied_adresse` | `adresse_id` | `m_adresse.adresse_id` | NO ACTION |
| `x_objekt_gruppe` | `objekt_id` | `m_objekt.objekt_id` | **CASCADE** |
| `x_objekt_gruppe` | `ygrp_id` | `d_gruppe.id` | NO ACTION |
| `x_role_perm` | `perm_id` | `d_perm.id` | **CASCADE** |
| `x_role_perm` | `role_id` | `d_role.id` | **CASCADE** |
| `x_user_role` | `role_id` | `d_role.id` | **CASCADE** |
| `x_user_role` | `user_id` | `m_user.id` | **CASCADE** |

