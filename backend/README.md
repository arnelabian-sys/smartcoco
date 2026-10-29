# SmartCoco — FastAPI backend (REST API bridge)

REST API sa likod sa Flutter app (`SmartCoco`): authentication, user management,
coconut varieties, image classification (simulated CNN) ug system health.

- **Framework:** FastAPI + Pydantic v2
- **Database:** PostgreSQL (SQLAlchemy 2.x + psycopg 3)
- **Auth:** JWT bearer token + `auth_sessions` table (revocable, para sa "online now")
- **Docs:** `http://localhost:8000/docs` (Swagger UI)

```
backend/
├── app/
│   ├── main.py          # FastAPI app + CORS + routers
│   ├── config.py        # SMARTCOCO_* settings / .env
│   ├── database.py      # engine, session, Base
│   ├── models.py        # users, auth_sessions, varieties, predictions, ...
│   ├── schemas.py       # request/response bodies
│   ├── security.py      # bcrypt + JWT
│   ├── deps.py          # get_current_user, require_admin, ...
│   ├── seed.py          # admin + Tall/Dwarf/Hybrid + model version
│   └── routers/         # auth, users, varieties, predictions, health
├── tests/               # pytest (SQLite, walay server needed)
├── requirements.txt
├── .env.example
└── docker-compose.yml   # PostgreSQL 16 (optional)
```

## 1. Setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

copy .env.example .env
# edit .env → ilisi ang SMARTCOCO_SECRET_KEY
```

### Database (PostgreSQL)

Default DSN:

```
postgresql+psycopg://smartcoco:smartcoco@localhost:5432/smartcoco
```

#### Option A — pgAdmin 4 (GUI)

1. Open **pgAdmin 4** → *Servers* → **PostgreSQL 18** → type the `postgres`
   password you set during installation.
2. **Create the role**
   - Right-click **Login/Group Roles** → **Create** → **Login/Group Role…**
   - *General* tab → Name: `smartcoco`
   - *Definition* tab → Password: `smartcoco`
   - *Privileges* tab → **Can login? = Yes**
   - **Save**
3. **Create the database**
   - Right-click **Databases** → **Create** → **Database…**
   - *General* tab → Database: `smartcoco`, Owner: `smartcoco`
   - **Save**
4. *(Optional)* Right-click `smartcoco` → **Query Tool** → run
   `SELECT current_database(), current_user;`

#### Option B — SQL / script

```powershell
cd backend
.\scripts\create_database.ps1     # asks for the postgres superuser password
```

o i-paste sa **pgAdmin → Query Tool** (connect sa `postgres` database):

```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smartcoco') THEN
    CREATE ROLE smartcoco LOGIN PASSWORD 'smartcoco';
  END IF;
END $$;

CREATE DATABASE smartcoco OWNER smartcoco ENCODING 'UTF8';
```

#### Option C — Docker

```powershell
docker compose up -d db
```

> Ang tables **dili** nimo kinahanglan himoon manually — inig-start sa API
> (`SMARTCOCO_AUTO_CREATE_TABLES=true`) automatic niya i-create ang 7 ka tables
> ug i-seed ang admin + varieties. Makita nimo sa pgAdmin:
> `smartcoco → Schemas → public → Tables`.

## 2. Run

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

Inig-start:
- automatic `CREATE TABLE` (kung `SMARTCOCO_AUTO_CREATE_TABLES=true`)
- gi-seed ang **administrator** (`admin@smartcoco.ph` / `Admin123`, usba sa `.env`)
- gi-seed ang varieties `TALL`, `DWARF`, `HYBRID` ug model `cnn-v1.0.0`

## 3. Endpoints (`/api/v1`)

| Method | Path | Access | Purpose |
|---|---|---|---|
| POST | `/auth/register` | public | Bag-ong account (user/student/farmer/agriculturist) |
| POST | `/auth/login` | public | User login (admin → 403 `admin_portal_required`) |
| POST | `/auth/admin/login` | public | Admin portal login |
| GET | `/auth/me` | bearer | Kasamtangan nga account |
| POST | `/auth/logout` | bearer | I-revoke ang session |
| PATCH | `/users/me` | bearer | Update profile |
| POST | `/users/me/password` | bearer | Change password |
| GET | `/users` | admin | List accounts (`?q=`, `?role=`, `?status=`) |
| GET | `/users/stats` | admin | Total / online / logins / by role |
| GET | `/users/{id}` | admin | Usa ka account |
| PATCH | `/users/{id}/status` | admin | `active` / `disabled` |
| PATCH | `/users/{id}/role` | admin | Promote to researcher |
| GET | `/varieties` | bearer | Active varieties (`?include_inactive=true` for admin) |
| POST | `/varieties` | admin | Add variety |
| PATCH | `/varieties/{id}` | admin | Update variety |
| DELETE | `/varieties/{id}` | admin | Soft delete (`active=false`) |
| POST | `/predictions` | bearer | Upload photo (`multipart/form-data`) |
| GET | `/predictions` | bearer | History (own; admin = tanan) |
| GET | `/predictions/stats` | admin/researcher | Aggregate stats (`?start=YYYY-MM-DD&end=YYYY-MM-DD`) |
| GET | `/predictions/{id}` | owner/admin | Single result |
| GET | `/predictions/{id}/image` | owner/admin | Ang gi-upload nga photo |
| GET | `/health` | public | Health snapshot (api/model/varieties) |
| GET | `/health/history` | admin | Previous checks |

> Tanan nga path sa lamesa nag-start sa `/api/v1`, e.g. `http://127.0.0.1:8000/api/v1/health`.
> Ang `/health` (walay prefix) kay lightweight liveness probe: `{"status": "ok"}`.

### Signature sa classification

```powershell
curl -X POST http://localhost:8000/api/v1/predictions `
  -H "Authorization: Bearer <TOKEN>" `
  -F "file=@coconut.png;type=image/png"
```

Response (success):

```json
{
  "id": 1,
  "user_id": 2,
  "variety": { "id": 1, "code": "TALL", "name": "Tall", "active": true },
  "confidence": 0.9123,
  "image_path": "predictions/2026/10/<uuid>.png",
  "status": "success",
  "error_message": null,
  "latency_ms": 421,
  "created_at": "2026-10-29T09:12:33Z"
}
```

Ang `status` mo-follow sa UI states: `success` | `empty` | `error`.
Filename nga naay `empty` → `empty`; naay `error` → HTTP 422 `classification_failed`.

## 4. Tests

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```

28 ka test, SQLite in-memory — **walay PostgreSQL nga kinahanglan** para mo-run.
Ang models portable (String + CHECK, generic JSON) para parehas mo-gana sa
PostgreSQL (production) ug SQLite (tests).

## 5. Kalabutan sa Flutter app

**Konektado na** ang Flutter Web sa API. Sa web build, `AuthController` ug
`DataStore` mo-tawag sa REST endpoints; sa `flutter test` ug desktop builds,
mock ang gamit (para walay server kinahanglan).

| Flutter | Endpoint |
|---|---|
| `AuthController.login` | `POST /auth/login` |
| `AuthController.loginAsAdmin` | `POST /auth/admin/login` |
| `AuthController.register` | `POST /auth/register` |
| `AuthController.logout` | `POST /auth/logout` |
| `AuthController.updateProfile` | `PATCH /users/me` |
| `AuthController.changePassword` | `POST /users/me/password` |
| `AuthController.fetchAccounts` | `GET /users` |
| `DataStore.fetchVarieties` | `GET /varieties` |
| `DataStore.addVariety` | `POST /varieties` |
| `DataStore.updateVariety` | `PATCH /varieties/{id}` |
| `DataStore.classifyImage` | `POST /predictions` (multipart `file`) |
| `DataStore.fetchHistory` | `GET /predictions` |
| `DataStore.stats` | `GET /predictions/stats?start=&end=` |
| `DataStore.fetchUsersCount` | `GET /users/stats` |
| `DataStore.health` | `GET /health` |

Ang base URL naa sa `lib/services/api_config.dart` (default
`http://localhost:8000/api/v1`). Ilisi sa build time:

```powershell
flutter build web --release --dart-define=SMARTCOCO_API_BASE=https://api.example.com/api/v1
```

> Importante para sa Flutter Web: i-set ang
> `SMARTCOCO_CORS_ORIGINS=http://localhost:<flutter-port>` (o `*` during dev).
## 6. Image storage

- Ang file ma-save sa `uploads/predictions/<YYYY>/<MM>/<uuid>.<ext>`
- Ang database nag-hold lang sa **relative path** (`image_path`)
- Limit: `SMARTCOCO_MAX_UPLOAD_MB` (default 8 MB); JPEG/PNG/WebP lang
