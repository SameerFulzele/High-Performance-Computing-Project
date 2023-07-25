#include <iostream>
#include <cmath>

using namespace std;

int main()
{

	int size = 8;
	int t = 200;
	double c = 1;
	double h = 0.01;
	double timeStep = h/sqrt(2);
	double b = c*c*timeStep*timeStep/h/h;
	int A[size][size][t];
	for (int p = 0; p < t; p++)
	{
		for (int i = 0; i<size; i++)
		{
			for (int j = 0; j < size; j++)
			{
				A[i][j][p] = 0;
				if(i == 3 && j == 3 && p == 1)
					A[i][j][1] = 6;
			}
		}
	}
		

	for (int p = 2; p < t; p++)
		for (int i = 1; i < size-1; i++)
			for (int j = 1; j < size-1; j++){
				A[i][j][p] = 2*A[i][j][p-1] - A[i][j][p-2] + b*(A[i-1][j][p-1]+A[i+1][j][p-1]+A[i][j-1][p-1]+A[i][j+1][p-1]-4*A[i][j][p-1]);
			}

	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			cout << A[i][j][199] << " ";
		}
		cout << endl;
	}

}
