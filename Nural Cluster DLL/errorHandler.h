#ifndef NURERRORH
#define NURERRORH
// https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__ERROR.html

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <string>
#include <vector>

namespace STE
{
	struct cudaError {
		//  https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__ERROR.html
		cudaError() {};
		cudaError(cudaError_t in) { cudaErr = in; };
		cudaError_t cudaErr;
		unsigned timeStamp;
		std::string GetString();
		void printError();
		std::string getName();
		void printName();
	};

	class errList {
	public:
		bool isErr();
		bool push(cudaError);
		bool push(cudaError_t newErr);
		cudaError pop();
		void clear();
		void reed(unsigned id);
		void reedAll();

	private:
		std::vector<cudaError> list;
		bool Err = false;

	};
}
#endif