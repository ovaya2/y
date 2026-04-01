# CLAUDE.md — yam2 Vereinsverwaltung

> Kontext-Anker für alle Claude-Sessions.
> Zuletzt aktualisiert: 2026-04-01
> Schema → `docs/schema.md` | Stand/Issues → `docs/state.md`

---

## 1. Projektübersicht

| Eigenschaft | Wert |
|---|---|
| **Name** | yam2 — Vereinsverwaltung (Lernprojekt, Features vom Ausbilder) |
| **UI** | WPF, .NET Framework 4.8, C# 7.0, `WinExe` |
| **DB** | MS SQL Server 2022, Schema `[yam3]`, DB `ovaya_test`, Server `SauerSQL2` |
| **Auth** | Windows-Auth (`Trusted_Connection=True`) |
| **DI** | `Microsoft.Extensions.DependencyInjection` 5.0.2 |
| **Mapping** | AutoMapper 10.1.1 (MappingProfile in `Profiles/`) |
| **Kompatibilität** | .NET 4.8 / C# 7.0 — keine .NET 9-Patterns! |

---

## 2. Schichtenstruktur

```
yam2/
├── Core/          → Basisklassen (kein Business-Code)
├── Models/        → Datenmodell (erben von ObservableValidator)
├── ViewModels/    → MVVM-ViewModels (erben von ViewModelBase)
├── Views/         → XAML + leere Code-Behind-Dateien
├── Services/      → Interfaces + SQL-Implementierungen + Repositories
├── Profiles/      → AutoMapper MappingProfile
└── App.xaml.cs    → Composition Root (DI-Setup)
```

---

## 3. Architektur-Patterns (kritisch)

### MVVM
- Kein Code-Behind in Views (außer `InitializeComponent()`)
- Navigation: ViewModel-first via `ContentControl` + `DataTemplate` in `MainWindow.xaml`
- `IViewService` abstrahiert Dialog-Öffnung — **niemals** `new Window()` in ViewModels

### Commands
- Sync: `RelayCommand` (Navigation, Dismiss)
- Async: `AsyncRelayCommand(execute, canExecute, onError:)` — **onError ist Named Parameter!**
- Kein `async void` außer in `App.OnStartup` (einzige erlaubte Stelle)

### Edit-Copy-Pattern
- Beim Bearbeiten immer `Clone()` → auf Kopie arbeiten → bei Save: `_mapper.Map(copy, original)` oder `CopyFrom()`
- **Niemals** Original direkt mutieren

### Repository-Pattern
- Interface → SQL-Implementierung, z.B. `IMemberRepository` → `SqlMemberRepository`
- Alle Repositories erben `SqlRepositoryBase` → nutzen `WithConnectionAsync<T>()`
- **Niemals** `_connectionString` duplizieren — Basisklasse verwaltet ihn

### ViewModelBase
- Alle ViewModels mit Lade-/Fehlerstatus erben `ViewModelBase`
- Properties: `IsLoading`, `ErrorMessage`, `HasError` (computed), `StatusMessage`
- Methode: `SetStatus(msg)` — setzt Status UND löscht ErrorMessage

### CloseAction-Pattern
- Detail-ViewModels: `Action<bool> CloseAction` — ViewService setzt es
- `CloseAction?.Invoke(true)` = Speichern, `false` = Abbrechen

### ViewService / Factory-Delegate
- `ViewService` erhält `Func<AppUser, UserDetailViewModel>` statt Repository direkt
- Repository-Kenntnis bleibt im Composition Root (`App.xaml.cs`)

### RBAC
- `PermissionService` (Singleton) lädt User + Rollen beim Start via `RefreshAsync()`
- `CanDo(permKey)` in ViewModels: prüft `_permissionService?.HasPermission(permKey)` → Fallback auf `_currentUser.IsAdmin`
- Superadmin-Rollen (`IsSuperadmin=true`) bypassen alle Permission-Checks

---

## 4. Zentrale Klassen

### Core
| Klasse | Funktion |
|---|---|
| `ObservableObject` | `INotifyPropertyChanged` + `SetProperty<T>()` |
| `ObservableValidator` | + `INotifyDataErrorInfo` + DataAnnotations |
| `RelayCommand` | Sync ICommand |
| `AsyncRelayCommand` | Async ICommand + `onError` + `_isExecuting`-Guard |
| `ViewModelBase` | Abstract: IsLoading, ErrorMessage, HasError, SetStatus() |
| `SqlExtensions` | `ToDbNull()` / `FromDbNull<T>()` — ADO.NET Null-Bridge |
| `GridColumnAttribute` | Custom Attribute für DataGrid-Auto-Generierung |

### Einstiegspunkt & Navigation
| Klasse | Rolle |
|---|---|
| `App.xaml.cs` | Composition Root — DI, `PermissionService.RefreshAsync()` beim Start |
| `MainViewModel` | Shell: `CurrentView` (object), Navigation-Commands |
| `MainWindow.xaml` | DataTemplates: `HomeViewModel→HomeView`, `MembersViewModel→MembersView`, `UsersViewModel→UsersView`, `RolesViewModel→RolesView` |

### ViewModels → Views
| ViewModel | Basis | Zweck |
|---|---|---|
| `MainViewModel` | ObservableObject | Shell, Navigation |
| `HomeViewModel` | ViewModelBase | Dashboard, KPI-Cards, RefreshCommand |
| `MembersViewModel` | ViewModelBase | Master-Detail: Member + Fees + Payments |
| `UsersViewModel` | ViewModelBase | AppUser-CRUD, Admin-Guard |
| `RolesViewModel` | ViewModelBase | Rollen-CRUD + Permission-Zuweisung (RBAC) |
| `MemberDetailViewModel` | ObservableObject | Add/Edit Member, CloseAction |
| `FeeDetailViewModel` | ObservableObject | Add/Edit Fee, CloseAction |
| `PaymentDetailViewModel` | ObservableObject | Add Payment, CloseAction |
| `UserDetailViewModel` | ViewModelBase | Add/Edit AppUser, CloseAction |
| `RoleDetailViewModel` | ObservableObject | Add/Edit Role, CloseAction |
| `PermissionAssignViewModel` | ObservableObject | CheckBox-Liste für Permission-Zuweisung |

### Services / Repositories
| Interface | Implementierung | Zweck |
|---|---|---|
| `IMemberRepository` | `SqlMemberRepository` | CRUD `[yam3].[m_gl]` |
| `IFinanceRepository` | `SqlFinanceRepository` | CRUD `[yam3].[f_soll]` + `[f_ist]` + Lookups |
| `IHomeRepository` | `SqlHomeRepository` | Dashboard-KPI-Queries |
| `IUserRepository` | `SqlUserRepository` | CRUD `[yam3].[m_u]` |
| `IRoleRepository` | `SqlRoleRepository` | CRUD `[yam3].[d_role]` + Permissions + User-Rollen |
| `IUserService` | `UserService` | Windows-Identity → `User`-Objekt |
| `IPermissionService` | `PermissionService` | Gecachter RBAC-Check, `RefreshAsync()` |
| `IViewService` | `ViewService` | Dialog-Öffnung (Factory-Delegate-Pattern) |
| — | `MockMemberRepository` | In-Memory (nicht in DI — nur für Tests) |

---

## 5. Kritische Konventionen

### C# / .NET 4.8 — NIEMALS .NET 9-Patterns
```csharp
// FALSCH (C# 8+):
if (obj is { Property: value }) ...
var attr = field.GetCustomAttribute<T>();

// RICHTIG (C# 7):
if (obj != null && obj.Property == value) ...
var attr = (T)field.GetCustomAttribute(typeof(T));
```

### ADO.NET-Mapping
```csharp
// RICHTIG:
reader.GetValue(index).FromDbNull<T>()  // nicht: reader.FromDbNull<T>(index)
value.ToDbNull()                         // C# null → DBNull.Value
```

### AsyncRelayCommand
```csharp
// onError ist NAMED PARAMETER:
new AsyncRelayCommand(execute, canExecute, onError: ex => HandleException(ex))
```

### AutoMapper
```csharp
// Id IMMER ignorieren:
CreateMap<Member, Member>().ForMember(dest => dest.Id, opt => opt.Ignore());
// PaidAmount ignorieren (kommt aus DB-JOIN):
CreateMap<Fee, Fee>().ForMember(dest => dest.PaidAmount, opt => opt.Ignore());
```

### LookupItem
```csharp
new LookupItem(id, bezeichnung)  // immutable Konstruktor
// Property: item.Bezeichnung     // NICHT item.Name o.ä.
```

### WithConnectionAsync — nie duplizieren
```csharp
// RICHTIG: immer über Basisklasse
return WithConnectionAsync(async conn => { ... });
// FALSCH: eigene SqlConnection öffnen
```

### IsDone / erledigt — NUR Trigger!
- Flag `f_soll.erledigt` wird **ausschließlich** von `tr_f_ist_auto_close` gesetzt
- Niemals per C#-Code `IsDone = true` setzen

### Soft-Delete (Member)
- `DeleteAsync` setzt `sta_id = 6` (Ausgetreten) + `austritt = GETDATE()`
- Kein physisches DELETE auf `m_gl`
- `GetAllAsync` filtert `WHERE sta_id <> @ausgetreten`

### async void — nur App.OnStartup
- Sonst immer `AsyncRelayCommand` mit `onError`-Callback

### Deadlock-Vermeidung
- `.GetAwaiter().GetResult()` auf async DB-Calls beim DI-Setup → Deadlock
- Fix: `PermissionService.RefreshAsync()` wird `await`-ed in `OnStartup` (async void)

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
| DB-Tabellen | `[yam3].[kürzel_tabelle]` | `[yam3].[m_gl]` |
| DB-Schema | immer `[yam3].` voranstellen | — |

---

## 7. Bekannte offene Issues (→ Details in `docs/state.md`)

| Problem | Schwere |
|---|---|
| `EnumBindingSource.cs` enthält GitHub-HTML statt C# | Hoch |
| Schema-Drift: RBAC-Tabellen fehlen im DB-Report | Mittel |
| IsAdmin-DB-Lookup auskommentiert (Deadlock-Fix) | Mittel |
| `MockMemberRepository` nicht in DI | Niedrig |
| Doppelter `using` in `ViewService.cs` | Niedrig |
| `#endregion` nach Klasse in `MainViewModel.cs` | Niedrig |
| `ovanot/tmp.cs` als `<Compile>` im .csproj | Niedrig |
| Fehlende Indizes auf `sta_id`, `erledigt` | Niedrig |
