//
// Created by EZNARWHAL on 4/4/1984.
//
#include <iostream>
#include <cmath>
#include <vector>
#include <iomanip>
#include <algorithm>
#include <map>
#include <deque>
#include <numeric>
#include <random>
#include <set>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int tt, INF = 2147483647;
    cin >> tt;
    while (tt--) {
        int n; cin >> n;
        int64_t ans = 337 * n * (n + 1) * (4 * n - 1);
        cout << ans % ((long long)1e9+7) << '\n';

    }
    return 0;
}