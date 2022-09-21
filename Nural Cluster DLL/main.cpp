#include <iostream>
#include <Windows.h>
#include <cuda.h>
#include <chrono>
#include "Nurons.h"
//#include <thrust/host_vector.h>
//#include <thrust/device_vector.h>
#include <fstream>
#include <sstream> 

#include "parse.h"

#include <string>
#include <fstream>
#include <streambuf>

void main() //test for nural cluster
{
	
	
	STE::Nurons Test(3, 1, dim3(4, 2, 9), 1);
	//Test.load("C:/Users/orang/Documents/programm test files/nurons/saves/Test1.txt");
	for (size_t i = 0; i < 1000; i++)
	{
		Test.update();
	}
	
	Test.save("C:/Users/orang/Documents/programm test files/nurons/saves/Test12.txt");



	

	//Test.ru*/
	
}