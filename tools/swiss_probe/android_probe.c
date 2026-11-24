#include <stdio.h>
#include "swephexp.h"

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    const double instant = 2460689.435416667;
    double values[6];
    char error[256] = {0};
    const int flags = SEFLG_SWIEPH | SEFLG_SPEED;
    const int ephemeris_mask = SEFLG_SWIEPH | SEFLG_JPLEPH | SEFLG_MOSEPH;
    swe_set_ephe_path(argv[2]);
    int missing = swe_calc_ut(instant, SE_MOON, flags, values, error);
    if (missing >= 0 && (missing & ephemeris_mask) == SEFLG_SWIEPH) return 3;
    swe_close();

    swe_set_ephe_path(argv[1]);
    const int bodies[] = {SE_SUN, SE_MOON, SE_PLUTO, SE_MEAN_NODE, SE_TRUE_NODE, SE_CHIRON};
    for (size_t i = 0; i < sizeof(bodies) / sizeof(bodies[0]); ++i) {
        int status = swe_calc_ut(instant, bodies[i], flags, values, error);
        if (status < 0 || (status & ephemeris_mask) != SEFLG_SWIEPH) {
            fprintf(stderr, "Body %d did not use Swiss data: %d %s\n", bodies[i], status, error);
            return 4;
        }
        printf("Body %d: longitude %.9f, flags %d\n", bodies[i], values[0], status);
    }
    swe_close();
    return 0;
}
