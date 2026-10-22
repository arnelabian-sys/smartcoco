# SmartCoco — Flutter Web Client

**A Web-Based Coconut Variety Classification System Using Image Recognition** (Final Project)

Users capture or upload a coconut photo and get a variety result (Tall, Dwarf, or Hybrid) with a confidence score. This client is built with Flutter Web and currently uses a **mock backend** (`DataStore` and `AuthController` with simulated delays), so no server is needed to try it.

## Features

- **Authentication:** register, log in, log out, with role-based access
- **Classify:** upload a coconut photo and receive a variety and confidence score
- **History:** your past classifications, with a variety filter and detail view
- **Varieties:** reference list of coconut varieties
- **Dashboard and Settings:** summary stats, profile update, change password
- **Researcher:** statistics page with a date-range filter
- **Admin:** manage varieties (add, edit, activate or deactivate) and view API/model status

## User Roles

| Role | Access |
|------|--------|
| Registered user (student, farmer, agriculturist) | Dashboard, Classify, History, Varieties, Settings |
| Researcher | Everything above, plus Statistics (`/stats`) |
| Administrator | Everything above, plus Manage Varieties and System Status (`/admin/...`) |

Routes are guarded in `lib/routes/app_router.dart`: signed-out users are sent to Login, and users without the right role see a Forbidden page.

## UI State Responses

Async requests follow this flow:

```
IDLE -> LOADING -> SUCCESS
                -> EMPTY
                -> ERROR -> RETRY
```

| State | Example in the app |
|-------|--------------------|
| **Idle** | Empty Login/Register form; Classify page before a photo is picked |
| **Loading** | Spinner inside the Log in button (button disabled to prevent double submit); "Classifying…" overlay on Classify |
| **Success** | "Registration successful! You can now log in." with a Log in button; result screen after classification |
| **Empty** | History: "No classifications yet." with a "Classify a coconut" button; Classify: "No coconut detected" |
| **Error** | Login: red Password field with "Incorrect password. Please try again."; request errors shown in a banner with a Retry button |
| **Retry** | Password field is cleared on a wrong password; the Retry button re-runs a failed request |

Form validation shows "This field is required." under empty required fields and scrolls to the first missing box.

### Testing each state with the mock classifier

`DataStore.classifyImage` picks the outcome from the **file name** of the uploaded photo:

| File name contains | Result |
|--------------------|--------|
| `empty`, `blank`, `none` | EMPTY (no coconut detected) |
| `error`, `fail` | ERROR on the first attempt; Retry then succeeds |
| anything else | SUCCESS |

## Project Structure

```
lib/
  main.dart, app.dart, theme.dart
  routes/      app_router.dart            # route table and role guards
  models/      models.dart                # AppUser, Variety, Prediction
  services/    auth_controller.dart       # mock login/register/profile
               data_store.dart            # mock classifier, history, varieties, stats
  screens/     landing, login, register, home, dashboard, upload (Classify),
               result, history, history_detail, varieties, statistics,
               settings, admin_varieties, admin_status, not_found
  widgets/     app_shell, app_button, app_text_field, feedback_banner,
               empty_state, status_chip, confirm_dialog, smartcoco_hero
  utils/       file picker (web and stub implementations)
test/          classify_flow, login_password, register_form tests
assets/images/ backgrounds and landing images
web/           index.html, manifest, icons
```

Reusable widgets (`FeedbackBanner`, `EmptyState`, `AppButton` with a `loading` flag) keep the loading, success, empty, and error states consistent across screens.

## Run (development)

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.13.1`) and Chrome.

```bash
cd smartcoco
flutter pub get
flutter run -d chrome
```

## Test

```bash
flutter test
```

## Build (release)

```bash
flutter build web
```

Output is in `build/web`.

## Demo accounts

For testing only. Remove these before any public or production release.

| Role | Email | Password |
|------|-------|----------|
| Registered user | `user@smartcoco.ph` | `User1234` |
| Researcher | `researcher@smartcoco.ph` | `Research123` |
| Administrator | `admin@smartcoco.ph` | `Admin123` |

Register with any email except `taken@smartcoco.ph` to simulate a new account (that one triggers the "duplicate email" error).

## Notes

- All data is in memory and resets on refresh.
- To connect a real backend, replace the methods in `lib/services/data_store.dart` and `lib/services/auth_controller.dart` with API calls; the screens already handle loading, empty, and error states.