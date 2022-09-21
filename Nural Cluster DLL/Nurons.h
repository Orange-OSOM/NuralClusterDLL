#ifndef NuronsH
#define NuronsH
 //https://app.zenflowchart.com/app

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <conio.h>
#include <iostream>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <vector>


#include "Nuron.h"
#include "errorHandler.h"

namespace STE
{
	cudaError_t Rand(int** data, unsigned quantity, int range, int offset);

	class sts {
	public:
		unsigned int totalNum = 0; // number of nurons in the cluster
		unsigned int shape = 0;
		dim3 volume;
		unsigned maxNuronTime = 9999999;
		unsigned maxRange = 0;
		unsigned maxConnections = 0;
		unsigned maxSensitivity = 1000;
		//unsigned int conectPerNuron = 6; // Default maximum nimber of connections per nuron
	};

	class __declspec(dllexport)  Nurons {
	public:
		//exported
		//Nurons();
		Nurons(unsigned int maxConections, unsigned int intnuronRange, dim3 volume, unsigned int shape);
		void setNuronSens(unsigned id);
		bool updateCluster();
		bool loadCluster(std::string in);
		bool saveCluster(std::string out);
		bool setNuronSensor(unsigned quant, unsigned* ids, bool sensor);
		bool getNuronSens(unsigned id);
		bool updateSensorData(unsigned quant, unsigned* ids, bool* data);
		bool updateOutData(unsigned quant, unsigned* ids, bool* data);

		void IoData(unsigned quant, bool** dataPtr, unsigned* ids);// dangerous function
		bool checkErrors();
		void readErrors();

		Nuron* getAllNur() {return allNurons;};
		//not exported but part intrinsilcy part of class.
		~Nurons();

		//depreceated
		//cudaError_t run();//runs indefinitly


	private:
		//vars
		STE::errList errors;
		sts stats;
		Nuron* allNurons;//array of pointers to nurons
		connection* allConections; // array of all the conections of all nurons || N1{N2,N5,N3,...},N2{N1,N5,N3,...},N3{N2,N5,N1,...} would be saved as {N2,N5,N3,...,N1,N5,N3,...,N2,N5,N1,...,...} 
		//funcs
		//cudaError_t run();
		cudaError_t update();
		//cudaError_t Nurons::load(std::string path);
		cudaError_t load(std::string);
		cudaError_t save(std::string filePath);
		cudaError_t setNuronSens(unsigned quant, unsigned* ids, bool sensor);
		cudaError_t updateSens(unsigned quant, unsigned* ids, bool* data);
		cudaError_t updateOut(unsigned quant, unsigned* ids, bool* data);
	};
}

/*
TO DO
* error handler
* small save
* Debugger/visualizer
*/


#endif
