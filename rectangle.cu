#include<stdio.h>
#include<stdlib.h>

__global__ void step1(float* fn2, float* fn1, float B)
{
	int id = (threadIdx.y * blockDim.x) + threadIdx.x + (blockIdx.x * blockDim.x * blockDim.y); 
	int id1 = id + 1 ;						
	int id2 = id -1 ;
	
	
   int id3 =(threadIdx.y * blockDim.x) + threadIdx.x - blockDim.x + (blockIdx.x * blockDim.x * blockDim.y);  
   int id4 =(threadIdx.y * blockDim.x) + threadIdx.x + blockDim.x + (blockIdx.x * blockDim.x * blockDim.y) ;
	if(threadIdx.y == 0 && blockIdx.x ==0 )
     	{ id3 = id ; } 

	if(threadIdx.y == blockDim.y-1 && blockIdx.x == gridDim.x - 1)
     	{ id4 = id ; } 

		//printf("%d id k upar %d k neche %d bagal me %d %d  for %d\n ", id , id3 , id4 , id2,id1,blockIdx.x );

	
	
	
        fn2[id] = 2*fn1[id]+B*(fn1[id1]+ fn1[id2]+ fn1[id3] + fn1[id4] - (4*fn1[id]) );	

	
}






__global__ void step2(float* fn2, float* fn0)
{
	int id= threadIdx.y * blockDim.x + threadIdx.x + blockIdx.x * blockDim.x * blockDim.y  ;
	  

	fn2[id ] = fn2[id]- fn0[id] ;
}
__global__ void copy(float* fn1, float* fn0)
{
	int id = threadIdx.y * blockDim.x + threadIdx.x +  (blockIdx.x * blockDim.x *blockDim.y) ;

	fn1[id] = fn0[id] ;
} 

					  



int main()
{	
	int A = 32 , B = 16 ;
	
	int size = A*B* sizeof(int);
	
	float f0[A*B], f1[A*B], f2[A*B],*fn1, *fn2,*fn0;
	

	float h = 0.001  , At = 0.1 , c = 0.01  ,b ;
	b = (c*c*At*At) / (h*h) ;
	b= 0.25;


	int i,j;
	for(i=0; i<B ; i++ )
	{
		for(j=0; j<A ; j++ )
		{
			f0[j + (i*A)] = 0;
			f1[j + (i*A)] = 0;
			f2[j + (i*A)] = 0;
		}
	}
	int x = (A*B)/2;
	f1[x] = 5 ;


	cudaMalloc(&fn1, size);
	cudaMemcpy(fn1, f1 , size, cudaMemcpyHostToDevice); 

	cudaMalloc(&fn0, size);
	cudaMemcpy(fn0, f0, size, cudaMemcpyHostToDevice);

	cudaMalloc(&fn2, size);

	     
	dim3   DimBlock(A , B); 	
	dim3   DimGrid(1, 1);
	
	
	int n =3;
	for(i=0 ;i<n ; i++)
	{
	step1<<<  DimGrid,DimBlock >>>(fn2 , fn1 ,b);
	step2<<<  DimGrid,DimBlock >>>(fn2 , fn1);
	
		
	copy<<<  DimGrid,DimBlock >>>(fn0 , fn1 );
	copy<<<  DimGrid,DimBlock >>>(fn1 , fn2 );

	}
		
		

		cudaMemcpy(f2, fn2, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(f1, fn1, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(f0, fn0, size, cudaMemcpyDeviceToHost);
    
	for(i=13; i<19 ; i++ )
	{
		for(j=13; j<19 ; j++ )
		{
		printf("%f   " ,f2[j + (i*B)]);
		}
		printf("\n ");
	


	}
	printf("%f  %f %f %f %f\n end " ,f2[x],f2[x-32],f2[x+32], f2[x+65], f2[x-65]);
	
	
	
}
