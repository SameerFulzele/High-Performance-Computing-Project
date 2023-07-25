#include<stdio.h>
#include<stdlib.h>

__global__ void step1(float* fn2, float* fn1, float B)
{
	int id = (threadIdx.y * blockDim.x) + threadIdx.x + (blockIdx.x * blockDim.x * blockDim.y  ); // here 256  is  blockDim.x * blockDim.y  
	int id1 = id + 1 ;						
	int id2 = id -1 ;
	
	
int id3 =  (threadIdx.y * blockDim.x) + threadIdx.x - blockDim.x + (blockIdx.x * blockDim.x * blockDim.y  );  
      int id4 =(threadIdx.y * blockDim.x) + threadIdx.x + blockDim.x + (blockIdx.x * blockDim.x * blockDim.y  ) ;
	if(threadIdx.y == 0 && blockIdx.x ==0 )
     { id3 = id ; } 

	if(threadIdx.y == blockDim.y -1 && blockIdx.x == gridDim.x - 1)
     { id4 = id ; } 
	
	
        fn2[id] = 2*fn1[id]+B*(fn1[id1]+ fn1[id2]+ fn1[id3] + fn1[id4] - (4*fn1[id]) );
}






__global__ void step2(float* fn2, float* fn0)
{
	int id= threadIdx.y * blockDim.x + threadIdx.x + blockIdx.x * blockDim.x * blockDim.y  ;
	  

	fn2[id ] = fn2[id]+ fn0[id] ;
}
__global__ void copy(float* fn1, float* fn0)
{
	int id = threadIdx.y * blockDim.x + threadIdx.x +  (blockIdx.x * blockDim.x *blockDim.y) ;

	fn1[id] = fn0[id] ;
} 

					  



int main()
{
	int size = 256*256* sizeof(int);
	//int N = 256*256 ;
	float f0[256][256], f1[256][256], f2[256][256],*fn1, *fn2,*fn0;
	

	float h = 0.001  , At = 0.1 , c = 0.01  ,b ;
	b = (c*c*At*At) / (h*h) ;
	int i,j;
	for(i=0; i<256; i++ )
	{
		for(j=0; j<256; j++ )
		{
			f0[i][j] = 0;
			f1[i][j] = 0;
			f2[i][j] = 0;
		}
	}
/*for(i=120; i<156; i++ )
	{
		for(j=120; j<156; j++ )
		{
			f1[i][j] = 3;
			
		}
	}*/
	f1[125][125] = 5 ;
	cudaMalloc(&fn1, size);
	cudaMemcpy(fn1, f1 , size, cudaMemcpyHostToDevice); // if this doesn't work make f0,f1,f2 a 1D array 

	cudaMalloc(&fn0, size);
	cudaMemcpy(fn0, f0, size, cudaMemcpyHostToDevice);

	cudaMalloc(&fn2, size);

	     
	dim3   DimBlock(16,16);   // each block will have 16 * 16 threads so total elements N=256*256 total no of blocks is N/256 = 256
	
	//if we want values of matrix at time t = T sec 
	

	for(i=0 ;i<2 ; i++){
	step1<<< 256,DimBlock >>>(fn2 , fn1 ,b);
	step2<<< 256,DimBlock >>>(fn2 , fn1);
	
		
	copy<<< 256,DimBlock >>>(fn0 , fn1 );
	copy<<< 256,DimBlock >>>(fn1 , fn2 );}
		
		cudaMemcpy(f2, fn2, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(f1, fn1, size, cudaMemcpyDeviceToHost);
				cudaMemcpy(f0, fn0, size, cudaMemcpyDeviceToHost);
    
	for(i=120; i<130; i++ )
	{
		for(j=120; j<130; j++ )
		{
			printf("\t %f",f2[i][j]);
		}
		printf("\n ");
	} 

	printf("\n  %f",b);

	for(i=120; i<130; i++ )
	{
		for(j=120; j<130; j++ )
		{
			printf("\t %f",f1[i][j]);
		}
		printf("\n ");
	} 
		printf("\n  %f",b);
	
	

	for(i=120; i<130; i++ )
	{
		for(j=121; j<128; j++ )
		{
			printf("\t %f",f0[i][j]);
		}
		printf("\n ");
	} 
		printf("\n  %f",b);
	
}
