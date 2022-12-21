/******************************************************************************
;@ Student Name 1: Alex Kopylov
;@ Student 1 #: 301 384 850
;@ Student 1 userid (email): akopylov@sfu.ca
;@
;@ Student Name 2: Nick Chu
;@ Student 2 #: 301 440 034
;@ Student 2 userid (email) nmc10@sfu.ca: 
;@
;@ Below, edit to list any people who helped you with the code in this file,
;@      or put ‘none’ if nobody helped (the two of) you.
;@
;@ Helpers: None
;@
;@ Also, reference resources beyond the course textbooks and the course pages on Canvas
;@ that you used in making your submission.
;@
;@ Resources:  ___________
;@
;@% Instructions:
;@ * Put your name(s), student number(s), userid(s) in the above section.
;@ * Edit the "Helpers" line and "Resources" line.
;@ * Your group name should be "HW5_<userid1>_<userid2>" (eg. HW5_stu1_stu2)
;@ * Form groups as described at:  https://courses.cs.sfu.ca/docs/students
;@ * Submit your file to courses.cs.sfu.ca
;@
;@ Name        : BigFib.c
;@ Description : bigFib subroutine for HW5.
******************************************************************************/

#include <stdlib.h>
#include <errno.h>
#include "heapstats.h"

typedef unsigned int bigNumN[];

int bigAdd(bigNumN bigN0P, const bigNumN bigN1P, unsigned int maxN0Size);

unsigned int* adjustSize(unsigned int* array, int length)
{
	int i;
	for(i = length; i>0; i--)  // calculate actual size of result
	{
		if(array[i] != 0)
			break;
	}
	unsigned int* bNP = malloc(4*(i+1));  // allocate new memory
	bNP[0] = i;
	for(int j = 1; j<=i; j++)    // populate new array with answer
		bNP[j] = array[j];
	free(array);
	return bNP;
}
unsigned int* initialize(int maxSize)
{
	unsigned* bNa = malloc(4*(1 + maxSize));
	// check for null pointer being returned or not
	if (bNa)
	{
		*bNa = maxSize;	
		for(int i = 1; i<=maxSize; i++)
			bNa[i] = 0;
	}
	else {
		errno = ENOMEM;  //set memory error
	}
	return bNa;
}
	
int bigFib(int n, int maxSize, unsigned **bNP) {
	
	HEAPSTATS;
	if(n <0 || maxSize<0 || bNP == NULL) //check for invalid inputs
	{
		errno = EINVAL;
		return -1;	
	}
	
	if(maxSize>0) // check if size is not 0
	{		
		unsigned* bNa = initialize(maxSize);	//initialize bNa with maxSize
		if(bNa == NULL) // return -1 if not sufficient memory
			return -1;
		bNa[1] = 0;
			
		if(n==0)   //return F0 if n==0
		{
			*bNP = adjustSize(bNa, maxSize);
			return 0;
		}
		
		unsigned* bNb = initialize(maxSize); //initialize bNb with maxSize
		if(bNb == NULL) // return -1 if not sufficient memory
			return -1;
		bNb[1] = 1;
		
		if(n==1)    //return F1 if n==1
		{
			free(bNa);
			*bNP = adjustSize(bNb, maxSize);
			return 1;
		}
		unsigned* temp;
		for (int i = 2; i <= n; i++)
		{
				int x = bigAdd(bNa, bNb, maxSize);
				if(x == 1){  // check if overflow occured
					free(bNa);
					*bNP = adjustSize(bNb, maxSize);
					return i-1;
				}
				temp = bNa;   // swap the order on every loop iteration
				bNa = bNb;
				bNb = temp;
			
		}
		free(bNa);
		*bNP = adjustSize(bNb, maxSize); // if no overflow return the result Fn with actual n
		return n;
	}
	else{                  //  if  maxSize = 0, return a pointer to value 0, and return 0
		*bNP = malloc(4); 
		**bNP = 0;
		return 0;
	}
	
}