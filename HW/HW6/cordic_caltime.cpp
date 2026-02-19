
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

using namespace std;

// quantization
#define BITS            14
#define QUANT_VAL       (1 << BITS)
#define QUANTIZE_F(f)   (int)(((float)(f) * (float)QUANT_VAL))
#define QUANTIZE_I(i)   (int)((int)(i) * (int)QUANT_VAL)
#define DEQUANTIZE_I(i)   (int)((int)(i) / (int)QUANT_VAL)
#define DEQUANTIZE_F(i)   (float)((float)(i) / (float)QUANT_VAL)

#define CORDIC_NTAB 16
static const short CORDIC_TABLE[] =
{
    0x3243, 0x1DAC, 0x0FAD, 0x07F5, 0x03FE, 0x01FF, 0x00FF, 0x007F, 
    0x003F, 0x001F, 0x000F, 0x0007, 0x0003, 0x0001, 0x0000, 0x0000
};

// Constants
#define K           1.646760258121066
#define CORDIC_1K   QUANTIZE_F(1/K)   
#define PI          QUANTIZE_F(M_PI)
#define TWO_PI      QUANTIZE_F(M_PI*2.0) 
#define HALF_PI     QUANTIZE_F(M_PI/2.0)

void cordic_stage(short k, short c, short *x, short *y, short *z)
{
    short xk = *x;
    short yk = *y;
    short zk = *z;

    short d = (zk >= 0) ? 0 : -1;
    short tx = xk - (((yk >> k) ^ d) - d);
    short ty = yk + (((xk >> k) ^ d) - d);
    short tz = zk - ((c ^ d) - d);

    *x = tx; 
    *y = ty; 
    *z = tz;    
}

void cordic(int rad, short *s, short *c)
{
    short x = CORDIC_1K;
    short y = 0;
    int r = rad;

    while ( r > PI  ) r -= TWO_PI;
    while ( r < -PI ) r += TWO_PI;

    if ( r > HALF_PI )
    {
        r -= PI;
        x = -x;
        y = -y;
    }
    else if ( r < -HALF_PI )
    {
        r += PI;
        x = -x;
        y = -y;
    }

    short z = r;

    for ( int k = 0; k < CORDIC_NTAB; k++ )
    {
        cordic_stage(k, CORDIC_TABLE[k], &x, &y, &z);
    }  
    
    *c = x; 
    *s = y;
}

int main(int argc, char **argv)
{
    int num_iterations = 10000000; // 10 million iterations
    clock_t start, end;
    double cpu_time_used;

    printf("Benchmarking CORDIC Software Implementation...\n");
    printf("Iterations: %d\n", num_iterations);

    // Dummy variables to prevent optimization
    short s = 0, c = 0;
    int rad = QUANTIZE_F(M_PI/4.0); // 45 degrees

    start = clock();
    for (int i = 0; i < num_iterations; i++) {
        // Vary input slightly to prevent compiler caching (though mostly unlikely with -O0/O1)
        // logic XOR to flip bits
        cordic(rad ^ (i & 0xFF), &s, &c); 
    }
    end = clock();

    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Total Time: %f seconds\n", cpu_time_used);
    printf("Time per Operation: %f us\n", (cpu_time_used * 1000000) / num_iterations);
    printf("Time per Operation: %f ns\n", (cpu_time_used * 1000000000) / num_iterations);

    return 0;
}
