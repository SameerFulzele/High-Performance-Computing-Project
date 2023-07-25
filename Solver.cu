#include<stdio.h>
#include<stdlib.h>

__global__ void step1(float* fn2, float* fn1, float B)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
	int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;
	int id1 = threadId + 1;
	int id2 = threadId - 1;
	int id3 =  threadId - blockDim.x ;
	int id4 = threadId + blockDim.x ;
	if(threadIdx.y == 0)
	{
		int blockIdof3 = blockIdx.x + (blockIdx.y -1) * gridDim.x;
		id3 = blockIdof3 *(blockDim.x* blockDim.y)+((blockDim.y-1) *blockDim.x)+threadIdx.x;
	}

	if(threadIdx.y == blockDim.y -1 )
	{
		int blockIdof4 = blockIdx.x + (blockIdx.y +1) * gridDim.x;
		id4 = blockIdof4 *(blockDim.x* blockDim.y) + threadIdx.x;
	}


	if(threadIdx.x == 0)
	{
		int blockIdof2 = (blockIdx.x-1) + blockIdx.y * gridDim.x;
		id2 = blockIdof2 *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+(blockDim.x-1);
	}

	if(threadIdx.x == blockDim.x -1 )
	{
		int blockIdof1 = (blockIdx.x+1) + blockIdx.y * gridDim.x;
		id1 = blockIdof1 *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x);
	}

	if(threadIdx.y == 0 && blockIdx.y == 0)
		id3 = threadId;

	if(threadIdx.y == blockDim.y -1  && blockIdx.y == gridDim.y -1)
		id4 = threadId;

	if(threadIdx.x == 0 && blockIdx.x == 0)
		id2 = threadId;

	if(threadIdx.x == blockDim.x -1  && blockIdx.x == gridDim.x -1)
		id1 = threadId;

	fn2[threadId] = 2*fn1[id]+B*(fn1[id1]+ fn1[id2]+ fn1[id3] + fn1[id4] - (4*fn1[id]) );
}

__global__ void step2(float* fn2, float* fn0)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
	int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;

	fn2[blockId ] = fn2[blockId] - fn0[blockId] ;
}
__global__ void copy(float* fn1, float* fn0)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
	int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;

	fn1[blockId] = fn0[blockId];
}

int main()
{

	int N = 1028;
	int T = 16;
	int G = 64;
	int size = N*N* sizeof(int);

	float f0[N*N], f1[N*N], f2[N*N],*fn1, *fn2,*fn0;
	float h = 0.001, At = 0.1, c = 0.01, b;
	b = (c*c*At*At) / (h*h);
	b= 0.0025;

	int i,j;
	for(i=0; i<16; i++ )
	{
		for(j=0; j<16; j++ )
		{
			f0[j + (i*N)] = 0;
			f1[j + (i*N)] = 0;
			f2[j + (i*N)] = 0;
		}
	}
	int x = N*N/2;
	f1[x] = 5;

	cudaMalloc(&fn1, size);
	cudaMemcpy(fn1, f1 , size, cudaMemcpyHostToDevice);

	cudaMalloc(&fn0, size);
	cudaMemcpy(fn0, f0, size, cudaMemcpyHostToDevice);
	cudaMalloc(&fn2, size);

	dim3   DimBlock(T,T);
	dim3   DimGrid(G,G);

	int n;      // n is the number of iteration
	n = 4;

	for(i=0 ;i<n ; i++)
	{
		step1<<< DimGrid,DimBlock >>>(fn2 , fn1 ,b);
		step2<<<DimGrid,DimBlock >>>(fn2 , fn1);

		copy<<< DimGrid,DimBlock >>>(fn0 , fn1 );
		copy<<< DimGrid,DimBlock >>>(fn1 , fn2 );
	}

	cudaMemcpy(f2, fn2, size, cudaMemcpyDeviceToHost);
	cudaMemcpy(f1, fn1, size, cudaMemcpyDeviceToHost);
	cudaMemcpy(f0, fn0, size, cudaMemcpyDeviceToHost);
	indexof_f2 = ( ((j/T) + (i/T) * T) * (G*G) ) + j%T + ((i%t)*G);

	for(i=0 ; i<N ; i++)
		{
			for(j=0;j<N;j++){
				printf("%f  ",f2[indexof_f2]);
			}
			printf("\n");
		}
}
