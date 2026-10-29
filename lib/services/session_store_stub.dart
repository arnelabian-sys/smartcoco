/// In-memory fallback for the session store.
///
/// Used on non-web targets (tests, desktop) where there is no browser
/// `localStorage`. Values only live for the current process.
final Map<String, String> _values = <String, String>{};

/// Returns the saved session payload, or `null` when nobody is signed in.
String? readSession() => _values['session'];

/// Saves [value] as the current session, or clears it when `null`.
void writeSession(String? value) => _write('session', value);

/// Returns the saved list of registered accounts (mock `users` table).
String? readAccounts() => _values['accounts'];

/// Saves the registered accounts, or clears them when `null`.
void writeAccounts(String? value) => _write('accounts', value);

void _write(String key, String? value) {
  if (value == null || value.isEmpty) {
    _values.remove(key);
  } else {
    _values[key] = value;
  }
}
