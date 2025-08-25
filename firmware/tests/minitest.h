#pragma once
#include <vector>
#include <string>
#include <functional>
#include <iostream>
#include <stdexcept>

struct TestRegistry {
    std::vector<std::pair<std::string, std::function<void()>>> tests;
    static TestRegistry& instance() {
        static TestRegistry inst;
        return inst;
    }
    void add(const std::string& name, std::function<void()> fn) {
        tests.emplace_back(name, fn);
    }
};

struct TestAdder {
    TestAdder(const std::string& name, std::function<void()> fn) {
        TestRegistry::instance().add(name, fn);
    }
};

#define TEST(name) \
void name(); \
static TestAdder adder_##name(#name, name); \
void name()

#define EXPECT_EQ(a,b) \
if(!((a) == (b))) { \
    std::cerr << "EXPECT_EQ failed: " << #a << " != " << #b << std::endl; \
    throw std::runtime_error("EXPECT_EQ failed"); \
}

#define EXPECT_TRUE(x) EXPECT_EQ(true, (x))
#define EXPECT_FALSE(x) EXPECT_EQ(false, (x))
