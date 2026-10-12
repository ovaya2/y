<!-- claude.md — v3.0.1 — Veröffentlichungsfassung: Hinweis zum Stand des Hauptzweigs bei I-16 entfällt (kein Hinweis auf noch aktive Sonderregeln in einem öffentlichen Dokument); vorher v3.0.0 — Inventur aus dem Code im Stand d1dfd1b: Klassen und Muster geprüft, Namenskonvention DB neu (Umbenennung), Zählwerte wie schema.md, Issues mit Status und Fundstelle (inkl. B-11 bis B-14); Namen der Datenbank maskiert -->
<!-- vorher: claude.md (Stand 2026-04-01, `y`/claude.md) -->
# CLAUDE.md — yam2 Vereinsverwaltung

> Kontext-Anker für alle Claude-Sessions.
> Stand: 12.10.2026 · Quellstand Code: Branch `feature/gruppe-sitzspalte-entfernen`, Commit `d1dfd1b`
> Schema → `schema.md` (aus der DDL erzeugt) und `schema-diagramme.md` | Adress-Design → `rev4/adress-design.md` | Entscheidungen → `rev4/ENTSCHEIDUNGEN.md`
> Jede Aussage hier ist am Quellstand geprüft; Abweichungen zur Fassung vom 01.04.2026 stehen in §8.

---

## 1. Projektübersicht

| Eigenschaft | Wert |
|---|---|
| **Name** | yam2 — Vereinsverwaltung (Lernprojekt, Features vom Ausbilder) |
| **UI** | WPF, .NET Framework 4.8, C# 7.0, `WinExe` |
| **DB** | MS SQL Server, Schema `[yam3]`, Datenbank `[DB-NAME]`, Server `[DB-SERVER]` (echte Namen nie in Dokumenten) |
| **Datenbankprojekt** | SSDT-Projekt `yam2.Database`, Schema als `.sql`-Dateien (`yam3/Tables`, `Triggers`, `Stored Procedures`, `Views`, `Scripts`) |
| **Auth** | Windows-Auth (`Trusted_Connection=True` in `App.config`) |
| **DI** | `Microsoft.Extensions.DependencyInjection` 5.0.2 |
| **Mapping** | AutoMapper 10.1.1 (`MappingProfile` in `Profiles/`, Assembly-Scan) |
| **Zugriff auf Daten** | ADO.NET von Hand, kein ORM |
| **Tests** | kein Testprojekt; Build und Lauf nur mit Visual Studio/MSBuild unter Windows |
| **Kompatibilität** | .NET 4.8 / C# 7.0 — keine .NET 9-Patterns! |

Umfang (Quellstand): **80** C#-Dateien in `yam2/` (77 ohne `Properties/`), davon Core 11, Models 13, ViewModels 16, Views 13, Services 21, Profiles 1, Anwendung 2 (`App.xaml.cs`, `MainWindow.xaml.cs`).

---

## 2. Schichtenstruktur

```
yam2/
├── Core/          → Basisklassen, Converter, Behavior (kein Business-Code)      11 Dateien
├── Models/        → Datenmodell (Member, Fee, Payment, Group erben ObservableValidator)   13
├── ViewModels/    → MVVM-ViewModels (Basis ObservableObject oder ViewModelBase) 16
├── Views/         → XAML + schlanke Code-Behind-Dateien                          13 Paare
├── Services/      → Interfaces + SQL-Implementierungen + Repositories            21
├── Profiles/      → AutoMapper MappingProfile                                     1
├── App.xaml.cs    → Composition Root (DI-Setup)
└── MainWindow.xaml(.cs) → Shell mit DataTemplates
yam2.Database/     → SSDT-Datenbankprojekt (Schema [yam3])
```

---

## 3. Architektur-Patterns (kritisch)

### MVVM
- Views haben nur `InitializeComponent()` und Verdrahtung: DataContext, `CloseAction` (Dialoge), `DataContextChanged` zum Start des Ladens (`GroupsView`). Keine Fachlogik im Code-Behind.
- Navigation: ViewModel-first über `ContentControl` + `DataTemplate` in `MainWindow.xaml` (Home, Members, Users, Roles, Groups). `MainViewModel` erzeugt bei jeder Navigation ein **neues** ViewModel (Factories, z. B. `Func<GroupsViewModel>`).
- `IViewService` abstrahiert Dialoge und Bestätigungen (`Confirm`) — **niemals** `new Window()` oder `MessageBox` in ViewModels.

### Commands
- Sync: `RelayCommand` (Navigation, Dismiss).
- Async: `AsyncRelayCommand(execute, canExecute, onError)` — `onError` ist ein benannter, optionaler Parameter; die Klasse hat einen `_isExecuting`-Guard gegen Doppelklicks.
- `async void` nur in `App.OnStartup` und in `AsyncRelayCommand.Execute` (Schnittstellenvorgabe von `ICommand`); sonst nie.

### Edit-Copy-Pattern
- Beim Bearbeiten immer `Clone()` → auf der Kopie arbeiten → beim Speichern `_mapper.Map(copy, original)`.
- `CopyFrom()` gibt es nur noch an `Group` (ohne Mapping-Profil); an `Member`, `Fee`, `AppUser` ist es entfernt.
- **Niemals** das Original direkt ändern.

### Repository-Pattern
- Interface → SQL-Implementierung, z. B. `IMemberRepository` → `SqlMemberRepository`.
- Alle `Sql*Repository` erben `SqlRepositoryBase` und nutzen `WithConnectionAsync<T>()`.
- Die Connection-String wird einmal in `App.xaml.cs` gelesen und per Konstruktor übergeben — **niemals** `ConfigurationManager` oder `_connectionString` anderswo.

### ViewModelBase
- ViewModels mit Lade-/Fehlerstatus erben `ViewModelBase` (`IsLoading`, `ErrorMessage`, `HasError` berechnet, `StatusMessage`, `SetStatus()`).
- Basis `ViewModelBase`: `MembersViewModel`, `HomeViewModel`, `UsersViewModel`, `RolesViewModel`, `GroupsViewModel`, `UserDetailViewModel`. Basis `ObservableObject`: `MainViewModel` und die übrigen Detail-/Dialog-ViewModels.

### CloseAction-Pattern
- Detail-ViewModels haben `Action<bool> CloseAction`; die View setzt es im Konstruktor (setzt `DialogResult` und schließt).
- `CloseAction?.Invoke(true)` = Speichern, `false` = Abbrechen.

### ViewService / Factory-Delegate
- `ViewService` erhält `Func<AppUser, UserDetailViewModel>`; Gruppen-Dialoge bekommen ihre ViewModels als Parameter (`ShowGroupDetail`, `ShowGroupMemberAdd`).
- Repository-Kenntnis bleibt im Composition Root (`App.xaml.cs`).

### RBAC
- `PermissionService` (Singleton) lädt User, Rollen und Rechte beim Start per `RefreshAsync()` (in `OnStartup` mit `await`) und hält sie im Speicher; `HasPermission(permKey)` und `IsSuperadmin` sind reine Speicherprüfungen.
- **Fail-closed:** Fehlt der User (vor `RefreshAsync` oder bei DB-Fehler), liefern beide `false`; bei Fehler entsteht ein Gast-`AppUser` ohne Rechte. Das nie auf „offen“ ändern.
- `CanDo(permKey)` in ViewModels prüft `_permissionService.HasPermission(permKey)`; ohne `_permissionService` gilt der Fallback `_currentUser.IsAdmin` (Migrationsrest, Form beibehalten). Superadmin-Rollen (`IsSuperadmin`) erfüllen jede Prüfung (`Role.HasPermission`).
- Rechte, die im Code geprüft werden: `member.create|edit|delete`, `fee.create|edit|delete`, `payment.create`, `role.create|edit|delete`. Gruppen und Benutzer sind noch nicht auf Rechte umgestellt.
- `User.IsAdmin` (App-Singleton, `App.xaml.cs`) ist die Superadmin-Rolle **oder** das Admin-Kennzeichen am Benutzer (`m_user.is_admin`). Der `UserService` liefert nur den Windows-Namen; sein eigenes `IsAdmin` (Windows-Administrator) wird nicht ausgewertet.
- Beim Start wird zusätzlich `m_user.letzter_login` gesetzt (`UpdateLastLoginAsync`, Fehler blockieren den Start nicht).

---

## 4. Zentrale Klassen

### Core
| Klasse | Funktion |
|---|---|
| `ObservableObject` | `INotifyPropertyChanged` + `SetProperty<T>()` |
| `ObservableValidator` | + `INotifyDataErrorInfo` + DataAnnotations |
| `RelayCommand` | Sync-`ICommand` |
| `AsyncRelayCommand` | Async-`ICommand` + `onError` + `_isExecuting`-Guard |
| `SqlExtensions` | `ToDbNull()` / `FromDbNull<T>()` — ADO.NET-Null-Brücke |
| `GridColumnAttribute` | Attribut für die automatische Erzeugung von DataGrid-Spalten (in `ModelAttributes.cs`) |
| `GridColumnHelper` | liest die Attribute per Reflection (mit Cache) |
| `DataGridColumnsBehavior` | Attached Behavior: erzeugt DataGrid-Spalten aus den Definitionen |
| `EnumExtensions` | Hilfen für Enums (Beschreibungen) |
| `SaldoColorConverter`, `ZeroToVisibilityConverter` | WPF-Converter |

### Einstiegspunkt & Navigation
| Klasse | Rolle |
|---|---|
| `App.xaml.cs` | Composition Root: DI, Kultur `de-DE`, `PermissionService.RefreshAsync()` beim Start, `OnExit` gibt den `ServiceProvider` frei |
| `MainViewModel` | Shell: `CurrentView` (object), Navigation-Commands, hält `CurrentUser` |
| `MainWindow.xaml` | DataTemplates: `HomeViewModel→HomeView`, `MembersViewModel→MembersView`, `UsersViewModel→UsersView`, `RolesViewModel→RolesView`, `GroupsViewModel→GroupsView` |

### ViewModels → Views
| ViewModel | Basis | Zweck |
|---|---|---|
| `MainViewModel` | ObservableObject | Shell, Navigation |
| `HomeViewModel` | ViewModelBase | Dashboard, KPI-Cards |
| `MembersViewModel` | ViewModelBase | Master-Detail: Member + Fees + Payments |
| `UsersViewModel` (Datei `UserViewModel.cs`) | ViewModelBase | AppUser-CRUD, Admin-Guard über `IsAdminOrSuperadmin` |
| `RolesViewModel` | ViewModelBase | Rollen-CRUD + Rechtezuweisung (RBAC) |
| `GroupsViewModel` | ViewModelBase | Gruppen-CRUD und Mitglieder je Gruppe |
| `MemberDetailViewModel` | ObservableObject | Add/Edit Member, CloseAction |
| `FeeDetailViewModel` | ObservableObject | Add/Edit Fee, CloseAction |
| `PaymentDetailViewModel` | ObservableObject | Add Payment, CloseAction |
| `UserDetailViewModel` | ViewModelBase | Add/Edit AppUser, CloseAction |
| `RoleDetailViewModel` | ObservableObject | Add/Edit Role, CloseAction |
| `GroupDetailViewModel` | ObservableObject | Add/Edit Gruppe, CloseAction |
| `GroupMemberAddViewModel` | ObservableObject | Mitglied zu einer Gruppe hinzufügen, CloseAction |
| `PermissionAssignViewModel` | ObservableObject | Checkbox-Liste für Rechtezuweisung (`CheckablePermission`) |

### Services / Repositories
| Interface | Implementierung | Zweck (Tabellen im Schema `[yam3]`) |
|---|---|---|
| `IMemberRepository` | `SqlMemberRepository` | CRUD `m_mitglied` |
| `IFinanceRepository` | `SqlFinanceRepository` | CRUD `f_soll` + `f_ist` + Lookups |
| `IHomeRepository` | `SqlHomeRepository` | Dashboard-KPI-Abfragen |
| `IUserRepository` | `SqlUserRepository` | CRUD `m_user` |
| `IRoleRepository` | `SqlRoleRepository` | CRUD `d_role` + Rechte + User-Rollen, `LoadUserWithRolesAsync` |
| `IGroupRepository` | `SqlGroupRepository` | CRUD `d_gruppe` + `x_gruppe_mitglied` |
| `IUserService` | `UserService` | Windows-Identity → `User`-Objekt (nur der Name wird ausgewertet) |
| `IPermissionService` | `PermissionService` | gecachter RBAC-Check, `RefreshAsync()` |
| `IViewService` | `ViewService` | Dialog-Öffnung (Factory-Delegate) |
| — | `MockMemberRepository` | In-Memory (nicht in DI, nur für Tests) |
| — | `EnumBindingSource` | XAML-Hilfe: Enum als Datenquelle |

---

## 5. Kritische Konventionen

### C# / .NET 4.8 — NIEMALS .NET 9-Patterns
```csharp
// FALSCH (C# 8+):
if (obj is { Property: value }) ...
// RICHTIG (C# 7):
if (obj != null && obj.Property == value) ...
var attr = (T)field.GetCustomAttribute(typeof(T));
```

### ADO.NET-Mapping
```csharp
reader.GetValue(index).FromDbNull<T>()  // nicht: reader.FromDbNull<T>(index)
value.ToDbNull()                         // C# null → DBNull.Value
```

### AsyncRelayCommand
```csharp
new AsyncRelayCommand(execute, canExecute, onError: ex => HandleException(ex))
```

### AutoMapper
- `CreateMap<Member, Member>()`, `CreateMap<Fee, Fee>()`, `CreateMap<AppUser, AppUser>()`: `Id` ignorieren, bei `Fee` zusätzlich `PaidAmount` (kommt aus dem DB-JOIN), bei `AppUser` `Roles`.

### LookupItem
```csharp
new LookupItem(id, bezeichnung)  // immutable
// Property: item.Bezeichnung    // NICHT item.Name
```

### WithConnectionAsync — nie duplizieren
- Immer über die Basisklasse; keine eigene `SqlConnection` öffnen.

### `erledigt` — nur der Trigger
- `f_soll.erledigt` wird im Betrieb **nur** von `tr_f_ist_auto_close` gesetzt (`AFTER INSERT, UPDATE` auf `f_ist`). `AddFeeAsync` und `sp_multiplier_soll` legen Gebühren mit 0 an. Niemals per C#-Code auf 1 setzen.
- Grenze: Bei Änderung von `f_soll.betrag` (`UpdateFeeAsync`) wird `erledigt` nicht neu berechnet (Issue I-9).

### Soft-Delete (Member)
- `DeleteAsync` setzt `status_id` auf `MemberStatus.Ausgetreten` (6) und `austritt` auf heute; kein physisches DELETE auf `m_mitglied`.
- `GetAllAsync` filtert `status_id <> @ausgetreten` (parametrisiert mit `(int)MemberStatus.Ausgetreten`).
- Enum-ID-Kopplung (müssen mit den Seed-Daten übereinstimmen): `MemberStatus` 1 bis 6, `Anrede` 1 bis 5, `Zahlungsart` 1 bis 4 (`Models/MemberEnums.cs`, `Models/Enums.cs`; Seeds in `yam2.Database/Scripts`).

### Deadlock-Vermeidung
- Kein `.GetAwaiter().GetResult()` auf Datenbankaufrufe beim DI-Setup. `PermissionService.RefreshAsync()` wird in `OnStartup` mit `await` aufgerufen; `UserService.GetCurrentUser()` ruft keine Datenbank auf.

### Datenbankprojekt
- Immer `[yam3].`-Qualifier; Prozeduren mit `SET NOCOUNT ON`, `TRY/CATCH` + `RAISERROR`; bereits angewendete Skripte nie nachträglich ändern.
- Seeds laufen über `Scripts/Script.PostDeployment.sql` (Dispatcher mit `:r`-Includes); jedes Seed-Skript ist idempotent.

---

## 6. Namenskonventionen

| Element | Schema | Beispiel |
|---|---|---|
| ViewModel | `[Name]ViewModel` | `MembersViewModel` |
| Detail-VM | `[Name]DetailViewModel` | `MemberDetailViewModel` |
| Repository-Interface | `I[Name]Repository` | `IMemberRepository` |
| SQL-Implementierung | `Sql[Name]Repository` | `SqlMemberRepository` |
| Command | `[Aktion]Command` | `AddCommand`, `DeleteFeeCommand` |
| Private Felder | `_camelCase` | `_selectedMember` |
| Properties | `PascalCase` | `SelectedMember` |
| DB-Tabellen | `[yam3].[<präfix>_<name>]`, Präfixe `d_` (Lookup), `m_` (Stammdaten), `x_` (Verknüpfung), `f_` (Finanzen), `t_` (Technik) | `[yam3].[m_mitglied]`, `[yam3].[x_gruppe_mitglied]` |
| DB-Spalten | ausgeschrieben, ohne Kürzel (seit der Umbenennung) | `vorname`, `nachname`, `mitglied_id`, `bezeichnung` |
| DB-Objekte | Trigger `tr_…`, Prozeduren `sp_…`, Sichten `v_…`, Constraints `pk_`/`fk_`/`uq_`/`ck_`/`df_`/`ix_` | `tr_f_ist_auto_close`, `sp_adresse_korrigieren`, `v_user_perms` |
| DB-Schema | immer `[yam3].` voranstellen | — |

Umbenennung (49 Vorgänge im Refactorlog), die alte Namen in älteren Dokumenten erklärt: `m_gl` → `m_mitglied`, `gl_id` → `mitglied_id`, `d_ygrp` → `d_gruppe`, `x_gm` → `x_gruppe_mitglied`, `d_sta` → `d_status`, `d_anr` → `d_anrede`, `d_zart` → `d_zahlungsart`, `d_ybart` → `d_beitragsart`, `d_ykto` → `d_konto`, `d_ysolltyp` → `d_solltyp`, `m_u` → `m_user`, `x_ur` → `x_user_role`, `x_rp` → `x_role_perm`, `x_gl_adresse` → `x_mitglied_adresse`; Spaltenkürzel `bez` → `bezeichnung`, `vn`/`nn`/`geb`/`tel`/`mail` → `vorname`/`nachname`/`geburtsdatum`/`telefon`/`email`. Vollständige Zuordnung und Gründe: `schema.md`. Bewusst unverändert (spätere Welle): `m_jump`, `m_mark`, `t_reg`, `x_fa`, `d_yfun` sowie die `y`-Präfixe in einzelnen Spalten (`ygrp_id` in `x_objekt_gruppe`) und die Namen vieler Constraints.

---

## 7. Datenbank im Überblick (Zählwerte wie `schema.md`)

| Kennzahl | Wert |
|---|---|
| Tabellen im Schema `[yam3]` | 28 |
| Spalten | 140 |
| Fremdschlüssel | 30 |
| Trigger | 3 (`tr_f_ist_auto_close`, `tr_m_adresse_immutable`, `tr_x_mitglied_adresse_no_overlap`) |
| Prozeduren | 2 (`sp_adresse_korrigieren`, `sp_multiplier_soll`) |
| Sichten | 1 (`v_user_perms`) |
| Umbenennungen (Refactorlog) | 49 |
| Indizes (außer Schlüsseln) | 5 |

- Das Schema ist die einzige Wahrheit in den `.sql`-Dateien; `schema.md` und `schema-diagramme.md` werden daraus erzeugt, nie von Hand gepflegt.
- Mitglieder-, Finanz-, Benutzer-/RBAC- und Gruppen-Tabellen werden vom C#-Code genutzt. Für 14 Tabellen findet die Code-Suche (SQL-Literale in `yam2/Services`) keinen Zugriff: `d_anrede`, `d_status` (nur über Enum-Kopplung), `d_land`, `d_ort`, `m_adresse`, `x_mitglied_adresse`, `d_objekttyp`, `m_objekt`, `x_objekt_gruppe` (Adress- und Objekt-Modell: Schema vorbereitet, Anwendung offen, siehe `rev4/adress-design.md` §10), `m_jump`, `m_mark`, `t_reg`, `x_fa`, `d_yfun`.

---

## 8. Bekannte Issues (Status am Quellstand `d1dfd1b`)

**Offen**

| ID | Problem | Schwere | Fundstelle | Hinweis |
|---|---|---|---|---|
| I-8 | Keine Indizes auf `status_id` und `erledigt` (Ginos Hinweis 8) | niedrig | `yam2.Database/yam3/Tables/m_gl.sql`, `f_soll.sql`: keine `CREATE INDEX`; Schema hat 5 Indizes, keiner darauf | Entscheidung E-008 (vorläufig): anlegen; Bedeutung von „Key-Index“ ungeklärt |
| I-9 | `f_soll.erledigt` wird bei Änderung von `betrag` nicht neu berechnet; der Trigger feuert nur bei INSERT/UPDATE auf `f_ist` (B-11) | mittel (fachlich) | `Services/SqlFinanceRepository.cs` `UpdateFeeAsync` (Z. 252, Kommentar Z. 245), `yam2.Database/yam3/Triggers/tr_f_ist_auto_close.sql` | Eine erledigte Gebühr bleibt nach Erhöhung des Betrags „erledigt“ (mit Datenbank belegt: nach Erhöhung von 100 auf 200 bleibt `erledigt` = 1). Fachlich zu klären (Klasse B/C) |
| I-10 | `LoadLookupAsync` setzt den Tabellennamen per String-Interpolation ins SQL (B-12) | niedrig | `Services/SqlFinanceRepository.cs` Z. 506 | Werte sind Konstanten im Code, kein Angriffsweg; widerspricht der Regel „nie String-Konkatenation“ |
| I-11 | `sp_multiplier_soll` ohne `TRY/CATCH` + `RAISERROR` (B-13) | niedrig | `yam2.Database/yam3/Stored Procedures/sp_multiplier_soll.sql` | Regelabweichung |
| I-12 | Kommentare in `IFinanceRepository` nennen alte Tabellennamen (`d_ykto`, `d_ybart`, `d_ysolltyp`, `d_zart`) (B-14) | niedrig | `Services/IFinanceRepository.cs` Z. 135 bis 138 | irreführend; Kommentar nur erweitern |
| I-4 | `MockMemberRepository` nicht in DI | niedrig | `Services/MockMemberRepository.cs`; keine Registrierung in `App.xaml.cs` | gewollt (nur Tests); es gibt kein Testprojekt |
| I-13 | Kommentar „ACHTUNG: Diese Datei ersetzt …“ in `d_ygrp.sql` ist ein Chat-Rest; die Datei heißt noch `d_ygrp.sql`, definiert aber `d_gruppe` | kosmetisch | `yam2.Database/yam3/Tables/d_ygrp.sql` Z. 2 | bewusst vorerst belassen |
| I-14 | `UserService` hält eine ungenutzte Abhängigkeit `_userRepository` | kosmetisch | `Services/UserService.cs` | im Dateikopf dokumentiert, bewusst belassen |
| I-15 | `UserService.GetCurrentUser()` setzt `IsAdmin` für jeden lokalen Windows-Administrator; der Wert wird nicht ausgewertet (nur der Name), die App-Admin-Eigenschaft kommt aus Superadmin-Rolle oder `m_user.is_admin` | kosmetisch | `Services/UserService.cs` Z. 219; `App.xaml.cs` Z. 316 bis 320; `Services/SqlRoleRepository.cs` Z. 483 | toter Anteil; bei Abschluss der RBAC-Migration entfernen |

**Erledigt** (Fassung vom 01.04.2026 führte sie noch offen)

| ID | Früheres Problem | Stand | Fundstelle |
|---|---|---|---|
| I-1 | `EnumBindingSource.cs` enthielt GitHub-HTML statt C# | erledigt: Datei ist gültiger C# (Version 1.1 vom 16.07.2026) | `Services/EnumBindingSource.cs` |
| I-2 | Schema-Drift: RBAC-Tabellen fehlten im DB-Report | erledigt: `schema.md` wird aus der DDL erzeugt und enthält `m_user`, `x_user_role`, `d_role`, `x_role_perm`, `d_perm`, `v_user_perms` | `schema.md` |
| I-3 | `IsAdmin`-DB-Lookup auskommentiert (Deadlock-Fix) | erledigt: `UserService` ruft keine Datenbank auf, Rechte kommen aus dem `PermissionService`; die alte Logik steht nur noch als Kommentar | `Services/UserService.cs` |
| I-5 | Doppeltes `using` in `ViewService.cs` | erledigt (keine doppelte Direktive) | `Services/ViewService.cs` |
| I-6 | `#endregion` nach der Klasse in `MainViewModel.cs` | erledigt: am Ende der Region `Konstruktor` vor dem Klassenende | `ViewModels/MainViewModel.cs` |
| I-7 | `ovanot/tmp.cs` als `<Compile>` im `.csproj` | erledigt: kein Eintrag mehr | `yam2/yam2.csproj` |
| I-16 | Namensbasierte Admin-Sonderregel (fest eingetragener Benutzername) in `UserService` | im Arbeitszweig erledigt: entfernt (UserService v1.2.0), das `IsAdmin` des Benutzerdienstes hängt nur an der Windows-Rolle und wird nicht ausgewertet (siehe I-15) | `Services/UserService.cs` |
| I-17 | Gruppe löschen warf eine rohe `SqlException` bei vorhandenen Mitgliedern | erledigt: `DeleteAsync` liefert `Task<bool>` (vorab `COUNT(*)`), `GroupsViewModel` fragt vorher nach (`Confirm`) | `Services/IGroupRepository.cs`, `Services/SqlGroupRepository.cs`, `ViewModels/GroupsViewModel.cs` |
| I-18 | `x_gruppe_mitglied.seit` nullable, aber `GetDateTime` ohne NULL-Prüfung | erledigt: Spalte `NOT NULL`, Backfill-Skript vor der Umstellung | `yam2.Database/yam3/Tables/x_gm.sql`, `Scripts/x_gm_seit_backfill.sql` |
| I-19 | Ehrenmitglieder fehlten bei der Massenanlage von Gebühren | erledigt: Filter `status_id IN (1, 3)` in `sp_multiplier_soll` | `yam2.Database/yam3/Stored Procedures/sp_multiplier_soll.sql` |
| I-20 | `tr_m_adresse_immutable` verwies auf eine nicht vorhandene Prozedur | erledigt: `sp_adresse_korrigieren` angelegt | `yam2.Database/yam3/Stored Procedures/sp_adresse_korrigieren.sql` |

Hinweis zu Dateinamen: Mehrere Dateien tragen noch Namen aus der Zeit vor der Umbenennung (`m_gl.sql`, `x_gl_adresse.sql`, `x_gm.sql`, `d_ygrp.sql`); der Inhalt trägt die neuen Tabellennamen.
