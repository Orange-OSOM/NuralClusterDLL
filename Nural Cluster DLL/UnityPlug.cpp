#include "Nurons.h"
#include <map>
#include <Windows.h>


//unity stuff



extern "C"
{		static std::map<std::string, STE::Nurons> clusterList;
		static std::map<std::string, STE::Nurons>::iterator clustListItr;

		static bool nameSet;

		//static unsigned currentClusterIndex;

		__declspec(dllexport) void test() {

		}

		__declspec(dllexport) void debugWinOn() {
			ShowWindow(GetConsoleWindow(), SW_RESTORE);
		}

		__declspec(dllexport) void debugWinOff() {
			ShowWindow(GetConsoleWindow(), SW_HIDE);
		}

		//returns true and creats new cluster if no cluster exists with same name.
		__declspec(dllexport) bool createNC(char* in, unsigned int maxConections, unsigned int intnuronRange, unsigned x, unsigned y, unsigned z, unsigned int shape) {
			std::string name(in);
			dim3 volume(x, y, z);
			if (clusterList.find(name) == clusterList.end())return false;
			clusterList.emplace(name, STE::Nurons(maxConections, intnuronRange, volume, shape));
			return true;
		}

		// returns true if a cluster with the spesified name exists then sets the static iterator to that locatiuon, othrwise returns fales and sets the itoratior to the end of the map.
		__declspec(dllexport) bool selectCluster(char* in) {
			std::string name(in);
			clustListItr = clusterList.find(name);
			if (clusterList.find(name) == clusterList.end())return false;
			return true;
		}

		__declspec(dllexport) void cleanUp() {
			clusterList.clear();
		}

		__declspec(dllexport) void pop() {
			clusterList.erase(clustListItr);
		}

		__declspec(dllexport) bool updateCluster() {
			if (clustListItr == clusterList.end()) { return false; };
			return clustListItr->second.updateCluster();
		}

		__declspec(dllexport) bool loadCluster(char* in) {
			std::string name(in);
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.loadCluster(in);
		}

		__declspec(dllexport) bool saveCluster(char* in) {
			std::string out(in);
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.saveCluster(out);
		}

		//make a easu unity var type for ids
		__declspec(dllexport) bool setNuronSensor(unsigned quant, unsigned* ids, bool sensor) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.setNuronSensor(quant, ids, sensor);
		}

		__declspec(dllexport) bool updateSensorData(unsigned quant, unsigned* ids, bool* data) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.updateSensorData(quant, ids, data);
		}

		__declspec(dllexport) bool updateOutData(unsigned quant, unsigned* ids, bool* data) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.updateOutData(quant, ids, data);
		}

		__declspec(dllexport) bool getNuronSens(unsigned id) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.getNuronSens(id);
		}

		__declspec(dllexport) unsigned getNuronPosX(unsigned id) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.getAllNur()[id].position.x;
		}

		__declspec(dllexport) unsigned getNuronPosY(unsigned id) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.getAllNur()[id].position.y;
		}

		__declspec(dllexport) unsigned getNuronPosZ(unsigned id) {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.getAllNur()[id].position.z;
		}

		__declspec(dllexport) bool checkErrors() {
			if (clustListItr == clusterList.end())return false;
			return clustListItr->second.checkErrors();
		}

		__declspec(dllexport) void readErrors() {
			if (clustListItr == clusterList.end())return;
			clustListItr->second.readErrors();
		}
		//not for unity
		//static void IoData(unsigned quant, bool** dataPtr, unsigned* ids);// dangerous function


	

}
