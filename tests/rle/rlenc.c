/*
 * RLE encoder.
 *
 * For the worst case, the dst buffer needs to be twice as large as the src.
 *
 * Example 1:
 *  8 bytes of input:  ABACCCABA
 * 12 bytes of output: [1]A[1]B[1]A[3]C[1]A[1]B
 *
 * Example 2:
 * 16 bytes of input:  DDDDDACDBBBBBDDD
 * 12 bytes of output: [5]D[1]A[1]C[1]D[5]B[3]D
 */

int rlenc(unsigned char *src, unsigned char *dst, int src_size)
{
    unsigned char rle_count = 1;
    unsigned char *dstPtr = dst;
    int dst_size = 0;
    char rle_byte = src[0];
    
    for (int i = 1; i <= src_size; i++) {
        // Compare the byte.
        if (src[i] == rle_byte && rle_count <= 255 && i < src_size) {
            rle_count++;
        } else {
            // Either we've found a different value at src[i], or we've exceeded the 255 byte RLE count. 
            *dstPtr = rle_count;
            dstPtr++;
            *dstPtr = rle_byte;
            dstPtr++;
            dst_size += 2;
            rle_count = 1;
            rle_byte = src[i];
        }
    }
    
    return dst_size;
}
