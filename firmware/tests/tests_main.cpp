#include "minitest.h"

int main() {
    int failed = 0;
    for (const auto& t : TestRegistry::instance().tests) {
        try {
            t.second();
            std::cout << "[PASS] " << t.first << std::endl;
        } catch (const std::exception& e) {
            std::cout << "[FAIL] " << t.first << ": " << e.what() << std::endl;
            failed++;
        }
    }
    std::cout << TestRegistry::instance().tests.size() - failed << "/" << TestRegistry::instance().tests.size() << " tests passed" << std::endl;
    return failed == 0 ? 0 : 1;
}
