#define M_TILE_H 16 // Height of input M tiles (Y dimension)
#define M_TILE_W 64 // Width of input M tiles (X dimension) 
#define N_TILE_H 64 // Height of input N tiles (Y dimension)
#define N_TILE_W 16 // Weight of input N tiles (X dimension)

__global__ void sgemm(float* M, float* N, float* P, int HeiM, int WidM, int WidN) { 
    
    __shared__ float Mds[M_TILE_H][M_TILE_W]; // constant row, loop varying column
    __shared__ float Nds[N_TILE_H][N_TILE_W]; // constant column, loop varying row

    int bx = blockIdx.x; int by = blockIdx.y;
    int tx = threadIdx.x; int ty = threadIdx.y;

 // Identify the row and column of the P element to work on
    int Row = by * M_TILE_H + ty;
    int Col = bx * N_TILE_W + tx;

 float Pvalue = 0;
 // Loop over the M and N tiles required to compute P element
    for (int m = 0; m < (WidM - 1)/ M_TILE_W + 1; ++m) {

 // Collaborative load of M and N tiles into shared memory
        if(Row < HeiM) { Mds[ty][tx] = M[Row * WidM + (m*M_TILE_W)+tx]} 
            else {Mds[ty][tx] = 0.0;
            }
        if(Col < WidN) {Nds[ty][tx] = N[(m * N_TILE_H + ty) * WidN+Col]} 
            else {Nds[ty][tx] = 0.0;
            }
        __syncthreads();

        if (Row < HeiM && Col < WidN) {
            for (int k = 0; k < M_TILE_W; ++k) {
                Pvalue += Mdsp[ty][k] * Nds [k][tx]
                }
        }
 __syncthreads();
    }
    if (Row < HeiM && Col < WidN) P[Row*Width + Col] = Pvalue;
}
