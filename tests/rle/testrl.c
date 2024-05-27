#include "rlenc.c"
#include "rldec.c"

int main(void) {
    unsigned char *test1in = "DDDDDACDBBBBBDDD";
    unsigned char test1out[32];
    unsigned char test1dec[32];
    
    int encode_size = rlenc(test1in, test1out, 16);

    int decode_size = rldec(test1out, test1dec, encode_size);
    
    return 0;
}
