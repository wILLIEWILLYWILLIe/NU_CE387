#include <stdio.h>
#include <math.h>
#define BITS 14
#define QUANT_VAL (1 << BITS)
#define QUANTIZE_F(f) (int)(((float)(f) * (float)QUANT_VAL))
#define PI 3.14159265358979323846
int main() {
    int N = 16;
    int step = N;
    int j;
    for (j = 0; j < N/2; j++) {
        float angle_step = -PI / (step / 2);
        float angle = j * angle_step;
        int wr = QUANTIZE_F(cos(angle));
        int wi = QUANTIZE_F(sin(angle));
        printf("W_%d^%d: real=0x%04x (%d), imag=0x%04x (%d)\n", N, j, wr & 0xFFFF, wr, wi & 0xFFFF, wi);
    }
    return 0;
}
