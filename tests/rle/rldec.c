/*
 * RLE decoder.
 *
 * For the worst case, the dst buffer needs to be twice as large as the src.
 *
 * Example 1:
 * 12 bytes of input: [1]A[1]B[1]A[3]C[1]A[1]B
 *  8 bytes of output:  ABACCCABA
 *
 * Example 2:
 * 12 bytes of input: [5]D[1]A[1]C[1]D[5]B[3]D
 * 16 bytes of output:  DDDDDACDBBBBBDDD
 */

int rldec(unsigned char *src, unsigned char *dst, int src_size)
{
    int dst_size = 0;
    
    for (int i = 0; i < src_size; i++) {
        // Get the count.
        unsigned char count = src[i];
        i++;
        unsigned char value = src[i];
        for (int j = 0; j < count; j++) {
            *dst = value;
            dst++;
            dst_size++;
        }
    }
    
    return dst_size;
}
