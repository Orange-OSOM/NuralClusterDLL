#include "Nuron.h"

namespace STE{
    __declspec(dllexport) Nuron::Nuron(unsigned int maxCons, dim3 pos, int identifier, connection* conectonPtr, unsigned int rangeInf, unsigned int MaxNurTime, unsigned int maxSens) {
        id = identifier;
        position = pos;
        connections = conectonPtr;
        maxConections = maxCons;
        maxNuronTime = MaxNurTime;
        range = range;
        currnetConections = 0;
        /*std::cout << "\nid: " << id << std::endl;
        std::cout << "connections: " << connections << std::endl;
        std::cout << "maxConections\n";
        std::cout << "id_time_connected";
        for (unsigned i = 0; i < maxCons; i++)
        {
            std::cout << conectonPtr[i].id << "_"<< conectonPtr[i].time<<"_" << conectonPtr[i].connected;
        }
        std::cout<< std::endl;
        std::cout << "maxNuronTime: " << maxNuronTime << std::endl;
        std::cout << "range: " << range << std::endl;*/
    }

    __declspec(dllexport) Nuron::~Nuron() {

    }
}