#include<stdio.h>
#include<stdlib.h>

__global__ void step1(float* fn2, float* fn1, float B)
{
	int id = (threadIdx.y * blockDim.x) + threadIdx.x ;  
	int id1 = id + 1 ;						
	int id2 = id - 1  ;
	
	
     	 int id3 =  id - blockDim.x ;  
     	 int id4 = id + blockDim.x ;
	if(threadIdx.y == 0)
   	  { id3 = id ; } 

	if(threadIdx.y == blockDim.y -1 )
  	  { id4 = id ; } 
	
	
        fn2[id] = 2*fn1[id]+B*(fn1[id1]+ fn1[id2]+ fn1[id3] + fn1[id4] - (4*fn1[id]) );	

	
}






__global__ void step2(float* fn2, float* fn0)
{
	int id= threadIdx.y * blockDim.x + threadIdx.x + blockIdx.x * blockDim.x * blockDim.y  ;
	  

	fn2[id ] = fn2[id] - fn0[id] ;
}
__global__ void copy(float* fn1, float* fn0)
{
	int id = threadIdx.y * blockDim.x + threadIdx.x +  (blockIdx.x * blockDim.x *blockDim.y) ;

	fn1[id] = fn0[id] ;
} 

					  



int main()
{	

	int N = 16 ;
	int size = N*N* sizeof(int);
	
	float f0[N*N], f1[N*N], f2[N*N],*fn1, *fn2,*fn0;
	

	float h = 0.001  , At = 0.1 , c = 0.01  ,b ;
	b = (c*c*At*At) / (h*h) ;
	b= 0.0025;
	


	
	int i,j;
	for(i=0; i<N; i++ )
	{
		for(j=0; j<N; j++ )
		{
			f0[j + (i*N)] = 0;
			f1[j + (i*N)] = 0;
			f2[j + (i*N)] = 0;
		}

	}
	int x = N*N/2;
	f1[x] = 5 ;






	cudaMalloc(&fn1, size);
	cudaMemcpy(fn1, f1 , size, cudaMemcpyHostToDevice); 

	cudaMalloc(&fn0, size);
	cudaMemcpy(fn0, f0, size, cudaMemcpyHostToDevice);

	cudaMalloc(&fn2, size);

	     
	dim3   DimBlock(N,N);   
	
	int n;      // n is the number of iteration 
	n = 4 ;
	


	for(i=0 ;i<n ; i++)
	{
	
	step1<<< 1,DimBlock >>>(fn2 , fn1 ,b);
	step2<<< 1,DimBlock >>>(fn2 , fn1);
	
		
	copy<<< 1,DimBlock >>>(fn0 , fn1 );
	copy<<< 1,DimBlock >>>(fn1 , fn2 );
	
	}
		
		


		cudaMemcpy(f2, fn2, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(f1, fn1, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(f0, fn0, size, cudaMemcpyDeviceToHost);
    
	for(i=N; i<N; i++ )
	{
		for(j=0; j<N; j++)
		{	
			printf("%f ",f2[j + (i*N)]);
			
		}
		printf("\n END ");}

		for(j=N-2; j<N+3; j++)
		{	
			printf("%f   ",f2[j]);
			
		}

	
printf("%f  %f \n inti %f   ",f2[N*7],f2[N*6],f2[x]);
	


	
		
}
