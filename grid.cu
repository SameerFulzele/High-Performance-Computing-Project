#include<stdio.h>
#include<stdlib.h>

/*
Our equation is 
F(i,j,t+1) = 2*F(i,j,t)  + B*B [F(i+1,j,t) + F(i-1,j,t) + F(i,j+1,t) + F(i,j-1,t) - 4*F(i,j,t) ] + F(i,j,t-1)  

We use step 1 kernel to evaluate first two terms in RHS and then step 2 kernel to add last 3rd term in RHS to F(i,j,t+1) in LHS

Here B =  (C*C) * (deltaT*deltaT) / (h*h) where h is the seperation between two points 
				  	and deltaT is the time period between two iterations





If we use 2D grid and 2D block in we will have indexing like 

blockId = blockIdx.x + blockIdx.y * gridDim.x;
threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;

this threadId will be F(i,j,t) to find the threadId of F(i,j+1,t), F(i,j-1,t) , F(i-1,j,t) , F(i+1,j,t)  


1st case : if all the 4 are inside the block and not at the boundary of the block 
we have id1, id2, id3, id4 for  F(i,j+1,t), F(i,j-1,t) , F(i-1,j,t) , F(i+1,j,t) respectively 

2nd case : if all four lie on the boundary of the block but block is not on the boundary of the initial matrix
for id1,id2,id3,id4 we need to acess the id of the blocks nearest to them



3rd case : where we have all four values at the boundary of the bock as well as at the boundary of initial matrix 
in this case we take the id for(i,j) and put the same for id1,id2,id3,id4 accordingly.








*/
__global__ void step1(float* fn2, float* fn1, float B)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;  
	
	//id of nearby points in case 1 :
	int id1 = threadId + 1 ;						
	int id2 = threadId - 1  ;
	
	
     	 int id3 =  threadId - blockDim.x ;  
     	 int id4 = threadId + blockDim.x ;
	
	//id of nearby points in case 2:
	if(threadIdx.y == 0) // here f(i,j) lies on the upper boundary of the block 
	{
	//block id of the block above the current one with f(i,j)	
	 int blockIdof3 = blockIdx.x + (blockIdx.y -1) * gridDim.x;
		
	//id of the point above the f(i,j) which lies on the block above it
	id3 = blockIdof3 *(blockDim.x* blockDim.y)+((blockDim.y-1) *blockDim.x)+threadIdx.x;  
	}
   	   

	if(threadIdx.y == blockDim.y -1 )  // here f(i,j) lies on the lower boundary of the block 
  	{
	//block id of the block above the current one with f(i,j)	
	int blockIdof4 = blockIdx.x + (blockIdx.y +1) * gridDim.x;
		
        //id of the point below the f(i,j) which lies on the block above it
	id4 = blockIdof4 *(blockDim.x* blockDim.y) + threadIdx.x;  
	}


	if(threadIdx.x == 0)  // here f(i,j) lies on the left boundary of the block
	{
	//block id of the block to the left the current one with f(i,j)
	 int blockIdof2 = (blockIdx.x-1) + blockIdx.y * gridDim.x;
		
	//id of the point to the left the f(i,j) which lies on the block beside it
	id2 = blockIdof2 *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+(blockDim.x-1); 
	}
   	   

	if(threadIdx.x == blockDim.x -1 ) // here f(i,j) lies on the right boundary of the block
  	{
	//block id of the block to the left the current one with f(i,j)
	int blockIdof1 = (blockIdx.x+1) + blockIdx.y * gridDim.x;
	
	//id of the point to the left the f(i,j) which lies on the block beside it
	id1 = blockIdof1 *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x);  
	}
	
	//3rd case where we take the id for f(i,j,t) and put it in id1,2,3,4 accordingly 
	if(threadIdx.y == 0 && blockIdx.y == 0)
   	  { id3 = threadId ; } 

	if(threadIdx.y == blockDim.y -1  && blockIdx.y == gridDim.y -1)
  	  { id4 = threadId ; } 

	if(threadIdx.x == 0 && blockIdx.x == 0)
   	  { id2 = threadId ; } 

	if(threadIdx.x == blockDim.x -1  && blockIdx.x == gridDim.x -1)
  	  { id1 = threadId ; } 


	

	
	
	
	// evaluating the first two terms of the equation and updating in f(i,j,t+1) i.e fn2
        fn2[threadId] = 2*fn1[threadId]+B*(fn1[id1]+ fn1[id2]+ fn1[id3] + fn1[id4] - (4*fn1[threadId]) );	

	
}





// step 2 involves subtraction of 3rd term in RHS in the equation 
__global__ void step2(float* fn2, float* fn0)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;

	fn2[threadId] = fn2[threadId] - fn0[threadId] ;
}
__global__ void copy(float* fn1, float* fn0)
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x;
int threadId = blockId *(blockDim.x* blockDim.y)+(threadIdx.y *blockDim.x)+threadIdx.x;

	fn1[threadId] = fn0[threadId] ;
} 

					  



int main()
{	
	// intital matrix will be square matrix with dimensions N x N 
	int N = 1028;  // initalize the value of N	
	int t = 16;    // txt is the dimension length of block i.e txt is the number of threads 	
	int G = 64;	// GxG is the numnber of blocks in a grid 
	int size = N*N* sizeof(int);
	
	float f0[N*N], f1[N*N], f2[N*N],*fn1, *fn2,*fn0;  // initialize the three 1 D array 
	// here indexing goes according to bloks to block
	
	// intialize B 
	float h = 0.001  , At = 0.1 , c = 0.01  ,b ;
	b = (c*c*At*At) / (h*h) ;
	b= 0.0025; 
	


	//initialze the 1d array
	int i,j;
	
	for(j=0;j<N*N;j++){
			f0[j]=0;
			f1[j]=0;
			f2[j]=0;
				}
	int x = N*N/2;
	f1[x] = 5 ;   // this is the point where disturbance in intitalized






	cudaMalloc(&fn1, size);
	cudaMemcpy(fn1, f1 , size, cudaMemcpyHostToDevice); 

	cudaMalloc(&fn0, size);
	cudaMemcpy(fn0, f0, size, cudaMemcpyHostToDevice);

	cudaMalloc(&fn2, size);

	     
	dim3   DimBlock(t,t);  	
	dim3   DimGrid(G,G);  
	
	int n;      // n is the number of iteration 
	n = 4 ;
	


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
  

for(i=0 ; i<N ; i++)
	{
  		 for(j=0;j<N;j++){
			  int index = ((t*t)* ((j/t) + (i/t)*G)) + j%t + ((i%t)*t);
			printf("%f  ",f2[index]);
				}
			 printf("\n");
	}
		
}
