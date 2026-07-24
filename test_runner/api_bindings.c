#include <string.h>
#include <stdlib.h>

// Forward declarations for Wren API
typedef struct WrenVM WrenVM;
void wrenSetSlotBool(WrenVM* vm, int slot, bool value);
void* wrenGetUserData(WrenVM* vm);
void wrenSetUserData(WrenVM* vm, void* userData);

static const char* data = "my user data";
static const char* otherData = "other user data";

static void testReallocateFn(void* ptr, size_t newSize, void* userData) {
    if (strcmp((const char*)userData, data) != 0) return NULL;
    
    if (newSize == 0) {
        free(ptr);
        return NULL;
    }
    
    return realloc(ptr, newSize);
}

static void test(WrenVM* vm) {
    // Simple test that returns true
    wrenSetSlotBool(vm, 0, true);
}

// Export the binding function
void* userDataBindMethod(const char* signature) {
    if (strcmp(signature, "static UserData.test") == 0) return test;
    return NULL;
}
