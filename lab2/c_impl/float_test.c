#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

int main(int argc, char const *argv[])
{
    float f = -3.1415926535897932384626433832795f;
    u32 t = *(u32*)&f;
    u8 ms = ~((t & (1 << 31)) >> 31);
    u32 me = (t & (0x7F << 24)) >> 24;
    u16 mm = (t & (0xFFFF << 8)) >> 8;
    u32 nmn = (ms << 23) | (me << 16) | ( mm);
    u32 nm = (ms << 31) | (me << 24) | ( mm << 8 );
    printf("%f\n0x%x\n\n", f, t);
    printf("%f\n0x%x\n\n", *(float*)&nm, nmn);
    printf("%x \t%x \t%x\n", ms, me, mm);
    return 0;
}
