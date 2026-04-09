#ifdef _WIN32
#define SENTRY_EXPORT __declspec(dllexport)
#else
#define SENTRY_EXPORT __attribute__((visibility("default")))
#endif

extern "C" SENTRY_EXPORT void sentry_flutter_native_stub() {}
