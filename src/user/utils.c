#include "sys/sys.h"

void waitsecond()
{
    uint32_t current_timestamp = get_timestamp();

    while (get_timestamp() - current_timestamp > 0)
        ;
}

void waitbusy()
{
    // loop 1 million time
    for (uint32_t i = 0; i < 1e6; i++)
        ;
}

static uint32_t next = 1;

int32_t rand(int32_t low, int32_t high)
{
    next = next * 1103515245 + 12345;

    int32_t initial_result = (unsigned int)(next / 65536) % 32768;

    return (initial_result % (high - low + 1)) + low;
}

void srand(uint32_t seed)
{
    next = seed;
}