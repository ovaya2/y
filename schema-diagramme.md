# yam3 — Datenbankschema-Diagramme

Schema: `[yam3]` | DB: `ovaya_test` | Stand: 2026-04-01

---

## 1. Gesamtübersicht (Tabellengruppen)

```mermaid
graph TD
    subgraph MASTER["Mastertabellen (m_)"]
        m_gl["m_gl\nMitglieder"]
        m_u["m_u\nBenutzer"]
        m_jump["m_jump\nBesuchsverlauf"]
        m_mark["m_mark\nMarkierungen"]
    end

    subgraph FAKT["Faktentabellen (f_)"]
        f_soll["f_soll\nGebühren / Soll"]
        f_ist["f_ist\nZahlungen / Ist"]
    end

    subgraph LOOKUP["Lookup-Tabellen (d_)"]
        d_anr["d_anr\nAnreden"]
        d_sta["d_sta\nMitgliedsstatus"]
        d_ybart["d_ybart\nBeitragsarten"]
        d_ysolltyp["d_ysolltyp\nSoll-Typen"]
        d_ykto["d_ykto\nVereinskonten"]
        d_zart["d_zart\nZahlungsarten"]
    end

    subgraph RBAC["RBAC (d_ / x_)"]
        d_role["d_role\nRollen"]
        d_perm["d_perm\nPermissions"]
        x_ur["x_ur\nUser ↔ Rolle"]
        x_rp["x_rp\nRolle ↔ Permission"]
    end

    subgraph ZUORD["Zuordnungen (x_)"]
        x_gm["x_gm\nMitglied ↔ Gruppe"]
        x_fa["x_fa\nMitglied ↔ Funktion"]
        d_ygrp["d_ygrp\nGruppen"]
        d_yfun["d_yfun\nFunktionen"]
    end

    subgraph TECH["Technisch (t_)"]
        t_reg["t_reg\nApp-Registry"]
    end

    m_gl --> f_soll
    m_gl --> m_u
    f_soll --> f_ist
    m_u --> x_ur
    x_ur --> d_role
    d_role --> x_rp
    x_rp --> d_perm
    m_gl --> x_gm
    m_gl --> x_fa
```

---

## 2. Kern-Entitäten: Mitglieder, Gebühren, Zahlungen

```mermaid
erDiagram
    m_gl {
        int id PK
        nvarchar gl_nr UK
        int anr_id FK
        nvarchar vn
        nvarchar nn
        date geb
        nvarchar mail
        nvarchar tel
        nvarchar str
        nvarchar plz
        nvarchar ort
        nvarchar iban
        nvarchar bic
        nvarchar sepa_ref
        date sepa_datum
        int sta_id FK
        int ybart_id FK
        date eintritt
        date austritt
        bit dsgvo_dat
        bit dsgvo_foto
        datetime erstellt_am
        datetime geaendert_am
    }

    f_soll {
        int id PK
        int gl_id FK
        int ybart_id FK
        int ysolltyp_id FK
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
        int ykto_id FK
        int zart_id FK
        decimal betrag
        date datum
        nvarchar text
        uniqueidentifier batch_id
    }

    d_anr {
        int id PK
        nvarchar bez
    }

    d_sta {
        int id PK
        nvarchar bez
    }

    d_ybart {
        int id PK
        nvarchar bez
        decimal std_betrag
    }

    d_ysolltyp {
        int id PK
        nvarchar bez
    }

    d_ykto {
        int id PK
        nvarchar bez
        nvarchar iban
    }

    d_zart {
        int id PK
        nvarchar bez
    }

    m_gl ||--o{ f_soll : "hat (CASCADE)"
    f_soll ||--o{ f_ist : "wird bezahlt durch"
    d_anr ||--o{ m_gl : "anr_id"
    d_sta ||--o{ m_gl : "sta_id"
    d_ybart ||--o{ m_gl : "ybart_id"
    d_ybart ||--o{ f_soll : "ybart_id"
    d_ysolltyp ||--o{ f_soll : "ysolltyp_id"
    d_ykto ||--o{ f_ist : "ykto_id"
    d_zart ||--o{ f_ist : "zart_id"
```

---

## 3. Benutzerverwaltung & RBAC

```mermaid
erDiagram
    m_u {
        int id PK
        int gl_id FK
        nvarchar win_user UK
        bit is_admin
        datetime letzter_login
    }

    d_role {
        int id PK
        nvarchar bez UK
        nvarchar beschreibung
        bit is_superadmin
        bit is_system
    }

    d_perm {
        int id PK
        nvarchar perm_key UK
        nvarchar modul
        nvarchar aktion
        nvarchar bez
    }

    x_ur {
        int u_id FK
        int role_id FK
        datetime zugewiesen_am
    }

    x_rp {
        int role_id FK
        int perm_id FK
    }

    m_gl {
        int id PK
        nvarchar gl_nr UK
        nvarchar vn
        nvarchar nn
    }

    m_gl ||--o{ m_u : "gl_id (optional)"
    m_u ||--o{ x_ur : "u_id (CASCADE)"
    d_role ||--o{ x_ur : "role_id"
    d_role ||--o{ x_rp : "role_id (CASCADE)"
    d_perm ||--o{ x_rp : "perm_id"
```

---

## 4. Gruppen, Funktionen & technische Tabellen

```mermaid
erDiagram
    m_gl {
        int id PK
        nvarchar gl_nr UK
        nvarchar vn
        nvarchar nn
    }

    d_ygrp {
        int id PK
        nvarchar bez
    }

    d_yfun {
        int id PK
        nvarchar bez
    }

    x_gm {
        int gl_id FK
        int ygrp_id FK
        date seit
    }

    x_fa {
        int gl_id FK
        int yfun_id FK
        date wahl
    }

    m_u {
        int id PK
        nvarchar win_user UK
    }

    m_jump {
        int id PK
        int u_id FK
        int gl_id FK
        datetime besucht_am
    }

    m_mark {
        int id PK
        int u_id FK
        int gl_id FK
        char mark_char
        datetime gesetz_am
    }

    t_reg {
        char reg_name PK
        nvarchar payload
        int u_id FK
        datetime geaendert_am
    }

    m_gl ||--o{ x_gm : "gl_id (CASCADE)"
    d_ygrp ||--o{ x_gm : "ygrp_id"
    m_gl ||--o{ x_fa : "gl_id (CASCADE)"
    d_yfun ||--o{ x_fa : "yfun_id"
    m_u ||--o{ m_jump : "u_id"
    m_gl ||--o{ m_jump : "gl_id (CASCADE)"
    m_u ||--o{ m_mark : "u_id"
    m_gl ||--o{ m_mark : "gl_id (CASCADE)"
    m_u ||--o| t_reg : "u_id"
```

---

## 5. CASCADE-Übersicht

> Welche Daten werden beim Löschen eines Eintrags automatisch mitgelöscht?

```mermaid
graph TD
    m_gl["🗑 m_gl\n(Mitglied löschen)"]

    m_gl -->|CASCADE| f_soll["f_soll\nGebühren"]
    m_gl -->|CASCADE| x_gm["x_gm\nGruppen-Zuordnung"]
    m_gl -->|CASCADE| x_fa["x_fa\nFunktions-Zuordnung"]
    m_gl -->|CASCADE| m_jump["m_jump\nBesuchsverlauf"]
    m_gl -->|CASCADE| m_mark["m_mark\nMarkierungen"]

    f_soll -->|"⚠ NO ACTION\n(Waisen!)"| f_ist["f_ist\nZahlungen bleiben erhalten"]

    style m_gl fill:#2e1a1a,stroke:#e05252,color:#e05252
    style f_ist fill:#3a2e14,stroke:#f5a623,color:#f5a623
```

---

## 6. FK-Referenzmatrix

| Von | Spalte | → Nach | ON DELETE |
|-----|--------|--------|-----------|
| `m_gl` | `anr_id` | `d_anr.id` | NO ACTION |
| `m_gl` | `sta_id` | `d_sta.id` | NO ACTION |
| `m_gl` | `ybart_id` | `d_ybart.id` | NO ACTION |
| `f_soll` | `gl_id` | `m_gl.id` | **CASCADE** |
| `f_soll` | `ybart_id` | `d_ybart.id` | NO ACTION |
| `f_soll` | `ysolltyp_id` | `d_ysolltyp.id` | NO ACTION |
| `f_ist` | `soll_id` | `f_soll.id` | NO ACTION |
| `f_ist` | `ykto_id` | `d_ykto.id` | NO ACTION |
| `f_ist` | `zart_id` | `d_zart.id` | NO ACTION |
| `m_u` | `gl_id` | `m_gl.id` | NO ACTION |
| `x_ur` | `u_id` | `m_u.id` | **CASCADE** |
| `x_ur` | `role_id` | `d_role.id` | NO ACTION |
| `x_rp` | `role_id` | `d_role.id` | **CASCADE** |
| `x_rp` | `perm_id` | `d_perm.id` | NO ACTION |
| `m_jump` | `gl_id` | `m_gl.id` | **CASCADE** |
| `m_jump` | `u_id` | `m_u.id` | NO ACTION |
| `m_mark` | `gl_id` | `m_gl.id` | **CASCADE** |
| `m_mark` | `u_id` | `m_u.id` | NO ACTION |
| `x_gm` | `gl_id` | `m_gl.id` | **CASCADE** |
| `x_gm` | `ygrp_id` | `d_ygrp.id` | NO ACTION |
| `x_fa` | `gl_id` | `m_gl.id` | **CASCADE** |
| `x_fa` | `yfun_id` | `d_yfun.id` | NO ACTION |
