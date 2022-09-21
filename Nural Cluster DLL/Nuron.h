#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

namespace STE
{
	struct connection {
	public:
		int id = 0; // the id of the conected nuron
		int time = 2; //time left to decat in cycles
		bool connected = false; // is it used?
	};

	class __declspec(dllexport)  Nuron {
	public:

		unsigned int maxConections;
		unsigned int maxNuronTime;
		unsigned int maxSensitivity;
		unsigned int currnetConections = 0;
		int id; // the identfier of each nuronm
		dim3 position; // the phisical location of each nuron in a virtual space
		unsigned int range; // the phisical range that each nuron can connect , only odd numbers

		bool activation = false;
		bool sensor = false;
		int sensitivity = 0; // how sensitive is the nuron to it stimulis (inverted)
		//unsigned int maxConections; // possibaly unneaded as this is saved in Nurons
		connection* connections; //pointer to the location of the first element in its connection list// not used in cpu side but sill set for conseptualization might remove
		//double activation = 0; // i forgot what this was


		Nuron(unsigned int maxCons, dim3 pos, int identifier, connection* conectonPtr, unsigned int rangeInf, unsigned int MaxNurTime, unsigned int maxSens);
		~Nuron();
	};
}
