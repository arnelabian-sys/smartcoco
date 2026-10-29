/// Cross-platform session persistence.
///
/// On Flutter Web this reads/writes the browser's `localStorage`; everywhere
/// else it falls back to an in-memory value. Keeping the switch in one place
/// means [AuthController] never has to care which platform it runs on.
library;

export 'session_store_stub.dart'
    if (dart.library.html) 'session_store_web.dart';
