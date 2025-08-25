#pragma once
#include <functional>
#include <iostream>
#include <string>
#include <vector>

namespace minigtest {
struct Test {
    std::string name;
    std::function<void()> func;
};

inline std::vector<Test>& registry() {
    static std::vector<Test> tests;
    return tests;
}

struct Registrar {
    Registrar(const std::string& name, std::function<void()> func) {
        registry().push_back({name, std::move(func)});
    }
};

inline int RunAllTests() {
    int failures = 0;
    for (const auto& t : registry()) {
        try {
            t.func();
            std::cout << "[  OK  ] " << t.name << std::endl;
        } catch (const std::exception& e) {
            ++failures;
            std::cout << "[ FAIL ] " << t.name << " - " << e.what() << std::endl;
        } catch (...) {
            ++failures;
            std::cout << "[ FAIL ] " << t.name << std::endl;
        }
    }
    std::cout << registry().size() - failures << " tests passed, "
              << failures << " failed." << std::endl;
    return failures;
}
} // namespace minigtest

#define TEST(suite, name) \
    void suite##_##name(); \
    static minigtest::Registrar registrar_##suite##_##name(#suite "." #name, suite##_##name); \
    void suite##_##name()

#define EXPECT_EQ(expected, actual) \
    do { \
        if (!((expected) == (actual))) { \
            std::cerr << __FILE__ << ":" << __LINE__ << " Expected equality" << std::endl; \
        } \
    } while (0)

#define ASSERT_EQ(expected, actual) \
    do { \
        if (!((expected) == (actual))) { \
            std::cerr << __FILE__ << ":" << __LINE__ << " Expected equality" << std::endl; \
            throw std::runtime_error("ASSERT_EQ failed"); \
        } \
    } while (0)

inline int RUN_ALL_TESTS() { return minigtest::RunAllTests(); }
