// Browser implementation of the session store: the payloads are kept in
// `localStorage` so a page refresh (or coming back to the site) does not sign
// the user out, and registered accounts behave like rows in a real database.
//
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

const String _sessionKey = 'smartcoco.session';
const String _accountsKey = 'smartcoco.accounts';

/// Returns the saved session payload, or `null` when nobody is signed in.
String? readSession() => _read(_sessionKey);

/// Saves [value] as the current session, or clears it when `null`.
void writeSession(String? value) => _write(_sessionKey, value);

/// Returns the saved list of registered accounts (mock `users` table).
String? readAccounts() => _read(_accountsKey);

/// Saves the registered accounts, or clears them when `null`.
void writeAccounts(String? value) => _write(_accountsKey, value);

String? _read(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    // Private mode / storage disabled — just behave as signed out.
    return null;
  }
}

void _write(String key, String? value) {
  try {
    if (value == null || value.isEmpty) {
      html.window.localStorage.remove(key);
    } else {
      html.window.localStorage[key] = value;
    }
  } catch (_) {
    // Ignore storage failures: the in-memory session still works.
  }
}
