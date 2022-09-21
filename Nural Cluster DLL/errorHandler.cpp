#ifndef NURERRORC
#define NURERRORC

#include "errorHandler.h"

namespace STE
{
	//cudaError-------------------------------
	std::string cudaError::GetString() {
		return std::string(cudaGetErrorString(cudaErr));
	}

	void cudaError::printError() {
		std::cout << this->GetString();
	}

	std::string cudaError::getName() {
		return std::string(cudaGetErrorString(cudaErr));
	}

	void cudaError::printName() {
		std::cout << this->getName();
	}

	//errList----------------------
	bool errList::push(cudaError newErr) {
		if (newErr.cudaErr == cudaSuccess) {
			return true;
		}
		list.push_back(newErr);
		Err = true;
		return false;
	}

	bool errList::push(cudaError_t newErr) {
		return	push(STE::cudaError(newErr));
	}

	cudaError errList::pop() {
		cudaError err = list.back();
		list.pop_back();
		return err;
	}

	void errList::clear() {
		list.clear();
	}

	void errList::reed(unsigned id) {
		std::cout << "err #" << id << ": " << list.at(id).getName() << " -> "<<list.at(id).GetString()<<std::endl;
	}

	void errList::reedAll() {
		for (unsigned i = 0; i < list.size(); i++)
		{
			reed(i);
		}
	}

	bool errList::isErr() {
		return Err;
	}
}

#endif