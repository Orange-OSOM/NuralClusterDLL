#ifndef NuronsC
#define NuronsC

//#include"pch.h"
#include<utility>

#include "Nurons.h"


#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>



#include <curand.h>
#include <time.h> 
#include <chrono>

//load

#include <fstream>
#include <sstream> 
#include "parse.h"


namespace STE {
    // predeff

    __global__ void updateKernal(STE::Nuron* nurons, connection* conections, sts stats, int* rng);

    __global__ void updateActivation(STE::Nuron* nurons, connection* conections, sts stats, int* rng);

    __global__ void updateConections(STE::Nuron* nurons, connection* conections, sts stats, int* rng);

    __global__ void SaveKernal(char* nuronDecription, unsigned int infoPerNuron, STE::sts stats, STE::Nuron* nurons, connection* conections);

    __global__ void LoadKernal(char* dev_filText, unsigned int nurBlock, STE::sts stats, STE::Nuron* nurons, connection* connections);

    __global__ void setSensKernal(Nuron* nurons, unsigned quant, unsigned* ids, bool sensor);

    __global__ void updateSensKernal(Nuron* nurons, unsigned quant, unsigned* dev_ids, bool* dev_data);

    __global__ void updateOutKernal(Nuron* nurons, unsigned quant, unsigned* ids, bool* data);

    __global__ void rad(int* data, unsigned quantity, unsigned range, int offset);

    //math for gpu
    int u(int x) {
        double offset = .5;//0<#<1
        return (int)((tanh(900 * (x + offset)) / 2) + .5 + offset);
    }

    __device__ int uDev(int x) {
        double offset = .5;//0<#<1
        return (int)((tanh(900 * (x + offset)) / 2) + .5 + offset);
    }
    //deffs

        //exporting func (public:)
    __declspec(dllexport) Nurons::Nurons(unsigned int maxCons, unsigned int nuronRange, dim3 vol, unsigned int shape) {
        
        stats.volume = vol;
        //set total number of nurons
        stats.totalNum = vol.x * vol.y * vol.z;
        //allocate space for all nuron pointers
        allNurons = (Nuron*)malloc(stats.totalNum * sizeof(Nuron));
        //allocate sace for all nuron conections
        allConections = (connection*)malloc(stats.totalNum * maxCons * sizeof(connection));
        //set the maximum range for each nuron
        stats.maxRange = nuronRange;
        stats.maxConnections = maxCons;
        
        //set all conections to the default no nuron
        connection Default;
        for (unsigned i = 0; i < stats.totalNum * maxCons; i++)
        {
            allConections[i] = Default;
        }

        // initalize a nuron at every location allocated in the nuron allocation setp************************this needs to be rewritten
        int x = 0;
        int y = 0;
        int z = 0;
        for (unsigned int i = 0; i < stats.totalNum; i++)
        {
            //i can gpu accelorate this
            /*
            * here nurons are allocated and initalized
            *
            * nurons are allocated with id = to the position in the allocatedmemory.
            * they also recievve the memory locaion of their conections(witch are heald in one array for eas  copping to the gpu ram later			*/

            // makes a cube

            x = i % stats.volume.x;//we modulo of i andthe volume retuns a reppeting pattern from 0 to 1 under the volume thus the whole of the volume when puit in sequence
            y = (i / stats.volume.x) % stats.volume.y; //deviding i by the volume in the x direction gives a repeeting pattern that when evver i is a multiple of x increses indicating a new y value
            z = (i / (stats.volume.x * stats.volume.y)) % stats.volume.z; //same consept for y but devide by the area of one z heaight (x*y) 
            //std::cout << "i:"<<i<<" x:" << x << " y:" << y << " z:"<<z << std::endl;
            allNurons[i] = Nuron(maxCons, dim3(x, y, z), i, allConections + (i * maxCons), stats.maxRange, stats.maxNuronTime, stats.maxSensitivity);
            //printf("i:%d\n  x:%d\n  y:%d\n  z:%d\n\n",i,x,y,z);
        }
        
    }
     
    /*::Nurons(std::string file) {
        load(this, file);
    }*/

    __declspec(dllexport)Nurons::~Nurons() {
        //deallocate thearray of pointers to the nurons and the nuron conections 
        free(allConections);
        free(allNurons);
    }

    bool __declspec(dllexport) Nurons::updateCluster() {
        return errors.push(update());
    }

    bool __declspec(dllexport) Nurons::loadCluster(std::string in) {
        return errors.push(load(in));
    };

    bool __declspec(dllexport) Nurons::saveCluster(std::string out) {
        return errors.push(save(out));
    };

    bool __declspec(dllexport) Nurons::setNuronSensor(unsigned quant, unsigned* ids, bool sensor) {
        return errors.push(setNuronSens(quant, ids, sensor));
    };

    bool __declspec(dllexport) Nurons::updateSensorData(unsigned quant, unsigned* ids, bool* data) {
        return errors.push(updateSens(quant, ids, data));
    }

    bool __declspec(dllexport) Nurons::updateOutData(unsigned quant, unsigned* ids, bool* data) {
        return errors.push(updateOut(quant, ids, data));
    }

    void __declspec(dllexport) Nurons::IoData(unsigned quant, bool** dataPtr, unsigned* ids) {
        for (unsigned i = 0; i < quant; i++)
        {
            dataPtr[i] = &allNurons[ids[i]].activation;
        }
    }
    
    void Nurons::setNuronSens(unsigned id) {
        if (id < stats.totalNum) {
            allNurons[id].sensor = true;
        }
    }

    bool Nurons::getNuronSens(unsigned id) {
        if (id < stats.totalNum) {
            return allNurons[id].sensor;
        }
    }
   //error check
    bool __declspec(dllexport) Nurons::checkErrors() {
        return errors.isErr();
    }

    void __declspec(dllexport) Nurons::readErrors() {
        errors.reedAll();
    }
    
    
    //private:

    //depreceated untill purpas is deffined
    /* 
    cudaError_t Nurons::run() {
        //using keybord inpuit to force an exit, c is going to be set to the pressed key value;
        char c;
        std::cout << "press esc to exit! " << std::endl;
        //loop indefinatly
        cudaError_t cudaStatus = cudaSuccess;
        while (cudaStatus == cudaSuccess && true)
        {
            // get key board inpuit 
            c = getch();
            //compair inpuit to excape key charvalue witch is 27, then break the loop
            if (c == 27) break;

            //this launches the update routien and grabbs the error code;
            cudaStatus = this->update();

            // check if a cuda error occured, if so exit loop;
            if (cudaStatus != cudaSuccess) break;
        }

        // check if error occord 
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addWithCuda failed!");
            //***void errorHandler();
        }

        // reset device (deallocates vram??)
        //https://stackoverflow.com/questions/36012289/what-is-the-role-of-cudadevicereset-in-cuda
        //"Note that this function will reset the device immediately.", " is used to destroy a CUDA context, which means that all device allocations are removed."
        cudaStatus = cudaDeviceReset();
        // check if reset was sucess fule;
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceReset failed!");
            //void errorHandler();
        }

        //**print exit status
        std::cout << "exited: " << std::endl;
        return cudaStatus;
    }
    */

     cudaError_t Nurons::update() {//*
         //std::cout << "bob" << std::endl;
        //need to be re written to seporate read conetons and set actication
         
        //ptr to all nurond on gpu
        Nuron* dev_allNur = {};
        //ptr to all conectiond on the gpu
        connection* dev_allconects = {};
        //ptr to all nurons rng
        int* host_RNG;
        host_RNG = (int*)malloc((stats.totalNum * 4) * sizeof(int));
        int* dev_RNG = {};
        //cuda error vareable
        // Choose which GPU to run on, change this on a multi-GPU system.
        cudaError_t cudaStatus = cudaSetDevice(0);
        if (errors.isErr()) goto ErrorUpdate;
        
        // create a grid of threds with the quantity of all the nurons
        unsigned int theadsPerBlock = 1024;
        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);
        //dim3 grid(stats.totalNum, 1, 1);


        // delllet this---------------------------------------------------------------
       // dim3 RNG3(rand() % 100 + 900000, rand() % 100 + 900000, rand() % 100 + 900000);

   
        //cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice (update) failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrorUpdate;
        }

        // allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc (update) (nurons) failed!");
            goto ErrorUpdate;
        }

        // Copy nurons to device memory
        //                                                                  printf("!!!!!!!!!!!!!!!max connection cpu:%d\n", stats.maxConnections);
        //printf("!!!!!!!!!!!!!!!current connect:%d\n", allNurons[1].currnetConections);
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (nurons) failed!");
            goto ErrorUpdate;
        }

        //allocate meemory on device for all the connections
        cudaStatus = cudaMalloc((void**)&dev_allconects, stats.totalNum * stats.maxConnections * sizeof(connection));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc (update) (conections) failed!");
            goto ErrorUpdate;
        }
       

        //coppy all cenections to device memory
        cudaStatus = cudaMemcpy(dev_allconects, allConections, stats.totalNum * stats.maxConnections * sizeof(connection), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (conections) failed!");
            goto ErrorUpdate;
        }
        
        //aalocate memory on gpu for rng and xyz  for possible new conections in this step
        cudaStatus = cudaMalloc((void**)&dev_RNG, stats.totalNum * 4 * sizeof(int));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc (update) (rng) failed!");
            goto ErrorUpdate;
        }        

        //genorate all random numbers needed for each nuron
            //this section can be more efficent currntly calling a functioin that makes allocates device memory puits the rng naumbers there and then returs it to host meory passes it back and then nit gets puit back in to device memory. in the fututre create a function that can be passed a device pointer from htere handle the data on the gpu
        //prints remove later
        //debug std::cout << "\nrand:x,y,z\n";

        cudaStatus = Rand(&host_RNG, stats.totalNum*3, (stats.maxRange*2)+1, -stats.maxRange);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (rng) failed!");
            goto ErrorUpdate;
        }


        //debug: std::cout << "\nrand:prob\n";

        int* host_RNG_temp = &host_RNG[stats.totalNum * 3];

        cudaStatus = Rand(&host_RNG_temp, stats.totalNum, stats.maxConnections, 0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (rng) failed!");
            goto ErrorUpdate;
        }

        cudaStatus = cudaMemcpy(dev_RNG, host_RNG, stats.totalNum * 4 * sizeof(int), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (rng) failed!");
            goto ErrorUpdate;
        }

        /*for (unsigned i = 0; i < stats.totalNum * 4; i++)
        {
            printf("i: % d = %d\n", i, host_RNG[i]);
        }/**/

        // Launch a kernel on the GPU with one thread for each element.
        //std::cout << "testing" << std::endl;
        updateActivation <<< grid, theadsPerBlock >>> (dev_allNur, dev_allconects, stats, dev_RNG);//just added this 
        // Check for any errors launching the kernel

        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel (update) launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrorUpdate;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize (update) returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrorUpdate;
        }
        updateConections <<< grid, theadsPerBlock >>> (dev_allNur, dev_allconects, stats, dev_RNG);

        // Check for any errors launching the kernel
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel (update) launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrorUpdate;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize (update) returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrorUpdate;
        }

        // Copy nurons from gpu memory to cpu memory.
        cudaStatus = cudaMemcpy(allNurons, dev_allNur, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (Nurons) failed!");
            goto ErrorUpdate;
        }

        // Copy connections from gpu memory to cpu memory.
        cudaStatus = cudaMemcpy(allConections, dev_allconects, stats.totalNum*stats.maxConnections * sizeof(connection), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy (update) (conections) failed!");
            goto ErrorUpdate;
        }
        //printf("no err");
        
    ErrorUpdate:
        cudaFree(dev_allNur);
        cudaFree(dev_allconects);
        cudaFree(dev_RNG);
        free(host_RNG);

        if (cudaStatus != cudaSuccess) {
            if(!errors.isErr())errors.push(cudaStatus);
        }
       
       

        return cudaStatus;
    }


    //the issue is in this section
    __global__ void updateActivation(STE::Nuron * nurons, connection * conections, sts stats, int* rng) {
        //initilization---------------------------------------------------
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //end start--------------------------------------------------
        //printf("upActiv:%d", I);
        int timeAdd = 2;
        int timeSub = 1;
        int sensAdd = 2;
        int sensSub = 1;

        //printf("rngX:%d\nrngY:%d\nrngZ:%d\nrngT:%d\n\n", rngX, rngY, rngZ, rngT);
        if (stats.totalNum <= I) return;//exit if excess
        //if (I != 0)return;
        nurons[I].connections = conections + (I * stats.maxConnections);//set id on gpu
        //if (I == 0)printf("1Device current connect:%d\n", nurons[1].currnetConections);

        //summ all conceted nuron conections----------------------------------------------------------------------------------
        int fialValue = 0;
        //edit this
        for (unsigned i = 0; i < stats.maxConnections; i++) // accelorate this
        {
            
            
            if (nurons[I].connections[i].connected)
            {
                //printf("nurons[%d].connections[%d].connected = %d\n", I, i, nurons[I].connections[i].connected);
                if (nurons[nurons[I].connections[i].id].activation)
                {
                    //printf("%i:_con:%i_NC_times:%i\n",I,i, nurons[I].connections[i].time);
                    fialValue = fialValue + (nurons[I].connections[i].time);
                    nurons[I].connections[i].time = nurons[I].connections[i].time + timeAdd;
                    if (nurons[I].connections[i].time > nurons[I].maxNuronTime)
                    {
                        nurons[I].connections[i].time = nurons[I].maxNuronTime;
                    }
                }
                else
                {
                    //decreemt time  left and check if time is zeroif so remove from list
                    nurons[I].connections[i].time = nurons[I].connections[i].time - timeSub;
                    //printf("%i:_con:%i_NC_times:%i\n",I,i, nurons[I].connections[i].time);
                    if (nurons[I].connections[i].time < 1) {
                        //printf("remove!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                        nurons[I].connections[i].connected = false;
                        nurons[I].connections[i].time = 0;
                        nurons[I].connections[i].id = 0;
                        nurons[I].currnetConections--;
                    }
                }
            }
        }

        // activate or not-------------------------------------------------------------------------------------------
        if (!nurons[I].sensor)
        {
            if (fialValue > nurons[I].sensitivity) //if summation is more than its senitivity set true and increment sensitivity
            {
                nurons[I].activation = true;
                nurons[I].sensitivity += sensAdd;
            }
            else {
                nurons[I].activation = false;
                nurons[I].sensitivity -= sensSub;
            }

            if (nurons[I].sensitivity > nurons[I].maxSensitivity)
            {
                nurons[I].sensitivity = nurons[I].maxSensitivity;
            }

        }
        else {
           //do nothing, its activation should remain what was set during host process
            //should simplifie this after i finalize design
        }
    }

    __global__ void updateConections(STE::Nuron * nurons, connection * conections, sts stats, int* rng) {
        //initilization---------------------------------------------------
        //I will be referd to as the thred index but this is a simplification of of its actual meaning. 
        //nvidea gpus can compute a maximum number of theds at one time(this is diffrent per gpu (is allwas a multipule of 2)). 
        //and infact can not compute less or more.
        //nvidea handles computeing more threds by computing them in blocks. nvidea allows for theds, and blocks to be indexed 3 dimentonaly.
        // i chose to keep evrethingin one dimention for simplisity. 
        // in order to compute less threds than are in a block you siply exclude all threds beon then desierd index.
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        if (I >= stats.totalNum) {
          
            return;
        }
        else {
            nurons[I].connections = conections+I * stats.maxConnections;           
            
            //if location is out of bounds "reflect" it at the boundry
            int* rngX;
            int* rngY;
            int* rngZ;
            int* rngT;

            //rng contains all random numbers for each nuron. this includes rngx,rngy,rngz, and rng probability of new conection.
            //thees valus are stored in the single array in the order (example 2 nurons): x0,y0,z0,x1,y1,z1,p0,p1.
            //this pattern continues with more nurons
            //here rngx is set to the location in the array rng offset by (I is the thred index) I*3. for I = 0: first location of rng + 0
            //for I = 1: first location of rng + 3
            rngX = rng + (3 * I);
            rngY = rngX + 1; //here rngy is set to the location after rngx 
            rngZ = rngY + 1; //here rngz is set to the location after rngy

            // here rngT (the probability of the nuron forming a connection) is set to the first location in rng that has a location that contains a probability.
            // due to the way the random numbers are stored the first location is located at the first location of rng offset by 3* the total number of nurons.
            // this inital probabiliyy location must then be ofset by the index of the thred(I)
            rngT = rng + (3 * stats.totalNum) + I;

            unsigned xd = (uDev(*rngX) * *rngX) + (uDev(*rngX - stats.volume.x) * ((stats.volume.x - (*rngX % stats.volume.x) - 1) - *rngX)) + (uDev(-1 - *rngX) * (*rngX % stats.volume.x));
            unsigned yd = (uDev(*rngY) * *rngY) + (uDev(*rngY - stats.volume.y) * ((stats.volume.y - (*rngY % stats.volume.y) - 1) - *rngY)) + (uDev(-1 - *rngY) * (*rngY % stats.volume.y));
            unsigned zd = (uDev(*rngZ) * *rngZ) + (uDev(*rngZ - stats.volume.z) * ((stats.volume.z - (*rngZ % stats.volume.z) - 1) - *rngZ)) + (uDev(-1 - *rngZ) * (*rngZ % stats.volume.z));
            unsigned td = (uDev(*rngT) * *rngT) + (uDev(*rngT - stats.maxConnections) * ((stats.maxConnections - (*rngT % stats.maxConnections) - 1) - *rngT)) + (uDev(-1 - *rngT) * (*rngT % stats.maxConnections));

            
            //cpmpare a random number to the amount of un used connections----------------------------------------------------------------------------------------------------------

            //decide if nuron wil make connection.
            //if (*rngT > (nurons[I].currnetConections / stats.maxConnections) )
            //printf("%i < %u||%u||%u||%d\n", td, stats.maxConnections - nurons[I].currnetConections, stats.maxConnections , nurons[I].currnetConections, td < stats.maxConnections - nurons[I].currnetConections);
            if (td < stats.maxConnections-nurons[I].currnetConections) {
                nurons[I].currnetConections++;
                if (nurons[I].currnetConections > stats.maxConnections) return;
                for (unsigned i = 0; i < nurons[I].currnetConections; i++)
                {
                    if (!nurons[I].connections[i].connected)//if the the connection status is false create a connection
                    {
                        nurons[I].connections[i].connected = true;
                        // ana rbitry starting number
                        nurons[I].connections[i].time = 10;
                        // new connection id  =  z*area + y * maxXDimentid + x 

                        nurons[I].connections[i].id = (zd * (stats.volume.y * stats.volume.x)) + (yd * stats.volume.x) + xd;
                        i = nurons[I].currnetConections;
                        //debug printf("!NEW!->I:%u:||C#:%u||CId:%u||x:%u||y:%u||z:%u||Calk:%u||con#:%u\n", I, i, nurons[I].connections[i].id, xd, yd, zd, (zd * (stats.volume.y * stats.volume.x)) + (yd * stats.volume.x) + xd, nurons[I].currnetConections);

                    }
                    /*debug else
                    {
                        printf("I:%u:||C#:%u||CId:%u\n", I, i, nurons[I].connections[i].id);
                    }*/

                }
                //printf("----------------!NEW!->I:%u:||C#:%u||CId:%u||x:%u||y:%u||z:%u||Calk:%u||con#:%u\n", I, i, nurons[I].connections[i].id, xd, yd, zd, (zd * (stats.volume.y * stats.volume.x)) + (yd * stats.volume.x) + xd, nurons[I].currnetConections);

            }

            /*   if (x<0 || y<0 || z<0 || x>stats.volume.x || y>stats.volume.y || z>stats.volume.z) {
                //printf("connection started, but failed. connection will not be set.\n");
                //x = nurons[I].position.x;
                //y = nurons[I].position.y;
                //z = nurons[I].position.Z;
            }
            else if (true)
            {

                //printf("test");
                //incremnt number of connections
                nurons[I].currnetConections++;

                for (unsigned i = 0; i < nurons[I].currnetConections; i++)
                {
                    if (!nurons[I].connections[i].connected)//if the the connection status is false create a connection
                    {
                        nurons[I].connections[i].connected = true;
                        // ana rbitry starting number
                        nurons[I].connections[i].time = 10;
                        // new connection id  =  z*area + y * maxXDimentid + x 
                        nurons[I].connections[i].id = (z * (stats.volume.y * stats.volume.x)) + (y * stats.volume.x) + x;
                        i = nurons[I].currnetConections;
                    }

                }

            }*/
            
        }
        
    }
    
     cudaError_t Nurons::save(std::string fileName) {
        std::cout << "saving to file" << std::endl;
        unsigned int theadsPerBlock = 1024;

        std::string outpuit;
        // nurons
        outpuit =
            (std::string)"Nurons\n" +
            "total: " + std::to_string(stats.totalNum) + '\n' +
            "shape: " + std::to_string(stats.shape) + '\n' +
            "volume: " + std::to_string(stats.volume.x) + "," + std::to_string(stats.volume.y) + "," + std::to_string(stats.volume.z) + '\n' +
            "maxConnections: " + std::to_string(stats.maxConnections)+ '\n' +
            "maxRange: " + std::to_string(stats.maxRange);

        // allconnections gpu acceloration;

       /*
        Nurons
        total: #
        shape: #
        volume: X,Y,Z
        maxConnections: X
        maxSensitiity:
        maxNuronTime:
        maxRange:

        Nuron: # -----------------------8  + maxIdDigits
        position: #, #, # --------------11 + (maxIdDigits*3)+2
        Range: # -----------------------8  + maxRangeDigits
        sensitivity: # -----------------14 + maxSensitivityDigits
        curCons: -----------------------10 + maxconnectionsdigs
        activation: # ------------------13 + 1
        sensor: b ----------------------9  + 1
        currnetConnectionBool: ********-24 + (connectiosPerNuron-1)+(connectiosPerNuron)
        currentConnectionTime: ********-24 + (connectiosPerNuron-1)+(connectiosPerNuron*maxYimeDigits)
        currnetConnectionID: ********---22 + (connectiosPerNuron-1)+(connectiosPerNuron*maxIdDigits)


        Nuron : # + 1
        *
        *
        *
        *
        *
        */

        //ptr to all nurond on gpu+
        Nuron* dev_allNur = {};
        /* //ptr to nurons calss on gpu
        Nuron* dev_Nurs;*/
        //ptr to all conectiond on the gpu
        connection* dev_allconects = {};
        //ptr to the Nurons calss
        Nurons* dev_nuronsClass;
        //ptr to device momory holding the nuron decription c~ctring
        char* dev_NuronDecription = {};
        //ptr to device stats
        STE::sts* dev_stats;


        //ptr to nuron decription on host
        char* host_NuronDecription = {};

        unsigned int maxIdDigits = (unsigned int)log10(stats.totalNum) + 1;
        unsigned int maxSensitivityDigits = ((unsigned int)log10(stats.maxSensitivity) + 1);
        unsigned int MaxTimeDigits = ((unsigned int)log10(stats.maxNuronTime) + 1);
        unsigned int connectiosPerNuron = ((unsigned int)log10(stats.maxConnections) + 1);
        unsigned int maxRangeDigits = ((unsigned int)log10(stats.maxRange) + 1);

        unsigned int infoPerNuron =
            9 + maxIdDigits +//id
            11 + (maxIdDigits * 3) + 2 +//pos
            8 + maxRangeDigits +//range
            14 + maxSensitivityDigits +//sensitivity
            10 + connectiosPerNuron +
            13 + 1 +//activation
            11 + 1 +//isSensor
            17 + (stats.maxConnections - 1) + (stats.maxConnections) + // connections is connected ()bool
            17 + (stats.maxConnections - 1) + (stats.maxConnections * MaxTimeDigits) + //time of each connection
            15 + (stats.maxConnections - 1) + (stats.maxConnections * maxIdDigits);//id of each connection

        /*std::cout << " 8 + maxIdDigits = " << 8 + maxIdDigits << std::endl;
        std::cout << " 11 + (maxIdDigits * 3) + 2 = " << 11 + (maxIdDigits * 3) + 2 << std::endl;
        std::cout << "  8 + maxRangeDigits = " << 8 + maxRangeDigits << std::endl;
        std::cout << " 14 + maxSensitivityDigits = " << 14 + maxSensitivityDigits << std::endl;
        std::cout << " 13 + 1 = " << 13 + 1 << std::endl;
        std::cout << " 11 + 1 = " << 11 + 1 << std::endl;
        std::cout << " 17 + (connectiosPerNuron - 1) + (connectiosPerNuron) = " << 17 + (connectiosPerNuron - 1) + (connectiosPerNuron) << std::endl;
        std::cout << " 17 + (connectiosPerNuron - 1) + (connectiosPerNuron * MaxTimeDigits) = " << 17 + (connectiosPerNuron - 1) + (connectiosPerNuron * MaxTimeDigits) << std::endl;
        std::cout << " 15 + (connectiosPerNuron - 1) + (connectiosPerNuron * maxIdDigits) = " << 17 + (connectiosPerNuron - 1) + (connectiosPerNuron * maxIdDigits) << std::endl;
        */

        unsigned int host_NuronDecriptionSize = ((stats.totalNum * infoPerNuron) + 1);
        host_NuronDecription = (char*)malloc(host_NuronDecriptionSize * sizeof(char));



        //unsigned int threds = 64;
        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);

        
        std::ofstream myfile;

        //cuda error vareable
        cudaError_t cudaStatus = cudaSetDevice(0);
        if (errors.isErr()) 
        {
            std::cout << "bob";
            goto ErrorSAVE;
        }


        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrorSAVE;
        }
        /*
        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_stats, stats.totalNum * sizeof(STE::sts));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorSAVE;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_stats, &stats, stats.totalNum * sizeof(STE::sts), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorSAVE;
        }*/

        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorSAVE;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorSAVE;
        }

        //allocate meemory on device for all the connections
        cudaStatus = cudaMalloc((void**)&dev_allconects, stats.totalNum * stats.maxConnections * sizeof(connection));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorSAVE;
        }

        //coppy all cenections to device memory
        cudaStatus = cudaMemcpy(dev_allconects, allConections, stats.totalNum * stats.maxConnections * sizeof(connection), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorSAVE;
        }


        /* //allocate space on gpu for the Nurons Object NOT the Nurons them selves(the Nuron class)
          cudaStatus = cudaMalloc((void**)&dev_Nurs, sizeof(Nurons));
          if (cudaStatus != cudaSuccess) {
              fprintf(stderr, "cudaMalloc failed!");
              goto ErrorSAVE;
          }

          //coppy from the Nurons cals sto the device
          cudaStatus = cudaMemcpy(dev_Nurs, this, sizeof(Nurons), cudaMemcpyHostToDevice);
          if (cudaStatus != cudaSuccess) {
              fprintf(stderr, "cudaMemcpy failed!");
              goto ErrorSAVE;
          }*/


          //allocate space on the gpu for the text to be stored in
        cudaStatus = cudaMalloc((void**)&dev_NuronDecription, host_NuronDecriptionSize * sizeof(char));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorSAVE;
        }




        // Launch a kernel on the GPU with one thread for each element.

        SaveKernal << < grid, theadsPerBlock >> > (dev_NuronDecription, infoPerNuron, stats, dev_allNur, dev_allconects);



        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrorSAVE;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrorSAVE;
        }

        cudaStatus = cudaMemcpy(host_NuronDecription, dev_NuronDecription, host_NuronDecriptionSize * sizeof(char), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!\n");
            goto ErrorSAVE;
        }
        //std::cout << "end save" << std::endl;
        goto NoErrorSave;
    
    NoErrorSave:
        host_NuronDecription[host_NuronDecriptionSize - 1] = NULL;
        //std::cout << "-----------------------------------------------------------------------------------" << std::endl;
        if (errors.isErr())
        
        std::cout << "saving";
        outpuit = outpuit + host_NuronDecription;// +std::string(host_NuronDecription);
      
        myfile.open(fileName);
        myfile << outpuit;
        //std::cout << outpuit << std::endl;
        myfile.close();
                
        //std::cout << "\n\n\n\n\n\n\n\ncpu result \n" << host_NuronDecription << std::endl;
        cudaFree(dev_allNur);
        cudaFree(dev_allconects);
        cudaFree(dev_NuronDecription);
        free(host_NuronDecription);
        printf("Save function end\n");
        
        if (cudaStatus != cudaSuccess) {
            if (!errors.isErr())errors.push(cudaStatus);
        }
        return cudaStatus;
    ErrorSAVE:
        std::cout << "error saving: " << std::endl;

        myfile.close();
        errors.reedAll();
        std::cout << cudaGetErrorString(cudaStatus) << std::endl;

        cudaFree(dev_allNur);
        cudaFree(dev_allconects);
        cudaFree(dev_NuronDecription);
        free(host_NuronDecription);
        printf("Save function end\n");
        return cudaStatus;

    }

    __global__ void SaveKernal(char* nuronDecription, unsigned int infoPerNuron, STE::sts stats, STE::Nuron* nurons, connection* conections) {
        //unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //printf("nuron: %d\n", I);
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //loop through  maxDigitsId number of time (EX:4)
        if (I >= stats.totalNum) {
            //printf("extra id %i", I);

        }
        else {
            //printf("%u\n", I);
            //printf("extra id %i \n", I);


            //unsigned int position = I * infoPerNuron;
            /*
                Nuron: # -----------------------8 + maxIdDigits
                position: #, #, # --------------11 + (maxIdDigits*3)+2
                Range: # -----------------------8 + maxRangeDigits
                sensitivity: # -----------------14 + maxSensitivityDigits
                curCons: -----------------------11 + maxconnectionsdigs
                activation: # ------------------13 + 1
                sensor: b ----------------------9+1
                currnetConnectionBool: ********-24 + ((connectiosPerNuron*2)-1)
                currentConnectionTime: ********-24 + (connectiosPerNuron-1)+(connectiosPerNuron*maxYimeDigits)
                currnetConnectionID: ********---22 + (connectiosPerNuron-1)+(connectiosPerNuron*maxIdDigits)


                Nuron : # + 1
                *
                *
                *
                *
            */
            // decide the number of digits to use when writing position and id
            unsigned int maxDigitsId = (unsigned int)(log10((double)stats.totalNum) + 1);
            //number of digits 
            unsigned int digitsID;
            //a simple int to char converter
            char digits[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' };
            //current ptr to where we want to write text
            char* ptrStart;
            //vvvvvv trouble shooting
            ptrStart = nuronDecription + (I * infoPerNuron);

            //^^^^^^^^^^
            //temporary vareable to hold text
            char* tempVar = "\n\nNuron: ";

            //print id
            // a temporary vareable to be used in the loop if the max number of digits in the id is 4 (EX: 8593) we set maxdigitsIdTemp to 1000
            unsigned int maxdigitsIdTemp;

            //vvvvvvvvvvuncomment in the kenal
           // ptrStart = nuronDecription + (I * infoPerNuron);
            //^^^^^^^^^^


            digitsID = (unsigned int)log10((double)I) + 1;

            //coppy tempvar to the current pointed at adress 8 chariters long (8 chariters because {\n,N,u,r,o,n,:, }is 8 chariters)  -- tecnicaly there is a null pter at the end of tempvar but we dont want that coppied
            memcpy(ptrStart, tempVar, 9);
            //move the ptr addres 8 char units to pass the writtentext  
            ptrStart = ptrStart + 9;


            //set to max id digits
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));



            for (unsigned i = 0; i < maxDigitsId; i++)
            {
                /* at this point we wright each digit as a chariter.
                * ath the begining of the fires loop we have the following (with new line charters being shown before the newline itselv being displayeed happening)
                * "\n
                * Nuron: "
                * we also have maxdigitsIdTemp = 10^maxDigitsId (EX:10000)
                * and I is arbitrary (EX: 1500)
                */

                //after this line the next unused chariter in the memory loation pointed to by PtrStart is set to I/maxdigitsIdTemp (in our example this works out to 1500/1000 = 1 ...integers round down...)
                //we take the modulo to clamp numbers from 0 to 9 so we dont acess out side of the digits char array.
                //digits is used to change a single digit base 10 number to a single char 

                ptrStart[i] = digits[(I / maxdigitsIdTemp) % 10];
                //std::cout << "I: " << I << "\nmaxdigitsIdTemp: " << maxdigitsIdTemp << std::endl;  <--for testing
                //std::cout << ptrStart[i] << std::endl;                                             <--for testing
                //after this line we remove a zeo from maxdigitsIdTemp. using this metod we cycle through the whole id chariter by cahriter
                maxdigitsIdTemp = maxdigitsIdTemp / 10;

                // this is repeeted
                // in this method we get leading zeros witch i am fine with this means with an I of 50 and a max digits of 4  we get 0050
            }



            //we now move the ptrstart location maxdigitsID number of units witch leaves  ptrStart[]
            ptrStart = ptrStart + maxDigitsId;

            //print position x,y,z
            //the same method is repeted for x,y,and z values as the id number
            tempVar = "\nposition: ";
            memcpy(ptrStart, tempVar, 11);
            ptrStart = ptrStart + 11;

            //SAVE Xpos
            //std::cout << "Xpos: ";

            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
            for (unsigned i = 0; i < maxDigitsId; i++)//print id
            {
                ptrStart[i] = digits[(nurons[I].position.x / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
                //std::cout << ptrStart[i] << std::endl;                                            

            }
            ptrStart[maxDigitsId] = ',';
            ptrStart = ptrStart + maxDigitsId + 1;



            //SAVE ypos
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
            for (unsigned i = 0; i < maxDigitsId; i++)//print id
            {
                ptrStart[i] = digits[(nurons[I].position.y / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
            }
            ptrStart[maxDigitsId] = ',';
            ptrStart = ptrStart + maxDigitsId + 1;

            //SAVE Zpos
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
            for (unsigned i = 0; i < maxDigitsId; i++)//print id
            {
                ptrStart[i] = digits[(nurons[I].position.z / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
            }
            ptrStart = ptrStart + maxDigitsId;

            //std::cout << nuronDecription << std::endl;

            //print range
            //agan we use the same method but maxDigitsIdid is recalulated with the maximum range use to calulate the number of digits
            tempVar = "\nRange: ";
            memcpy(ptrStart, tempVar, 8);
            ptrStart = ptrStart + 8;
            maxDigitsId = (unsigned int)(log10((double)stats.maxRange) + 1);
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));

            for (unsigned i = 0; i < maxDigitsId; i++)
            {
                ptrStart[i] = digits[(stats.maxRange / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
            }
            ptrStart = ptrStart + maxDigitsId;



            //print sensitivity
            //agan we use the same method but maxDigitsIdid is recalulated with the maximum sensitivity use to calulate the number of digits
            tempVar = "\nsensitivity: ";
            memcpy(ptrStart, tempVar, 14);
            ptrStart = ptrStart + 14;

            maxDigitsId = (unsigned int)(log10((double)stats.maxSensitivity) + 1);
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
            for (unsigned i = 0; i < maxDigitsId; i++)
            {
                ptrStart[i] = digits[(stats.maxSensitivity / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
            }
            ptrStart = ptrStart + maxDigitsId;

            //print current connections
           //agan we use the same method but maxDigitsIdid is recalulated with the maximum sensitivity use to calulate the number of digits
            tempVar = "\ncurCons: ";
            memcpy(ptrStart, tempVar, 10);
            ptrStart = ptrStart + 10;

            maxDigitsId = (unsigned int)(log10((double)stats.maxConnections) + 1);
            maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
            for (unsigned i = 0; i < maxDigitsId; i++)
            {
                //printf("curcons: %d", digits[(stats.maxConnections / maxdigitsIdTemp) % 10]);
                ptrStart[i] = digits[(stats.maxConnections / maxdigitsIdTemp) % 10];
                maxdigitsIdTemp = maxdigitsIdTemp / 10;
            }
            ptrStart = ptrStart + maxDigitsId;/**/

            //print its activation (1= active,  0 = not active)
            //here it is simple cast the bool activation to an unsigned int the store the value 
            tempVar = "\nactivation: ";
            memcpy(ptrStart, tempVar, 13);
            ptrStart = ptrStart + 13;
            ptrStart[0] = digits[unsigned(nurons[I].activation) % 10];
            ptrStart = ptrStart + 1;


            //print if sensor (1= yes, 0 = no)
            tempVar = "\nisSensor: ";
            memcpy(ptrStart, tempVar, 11);
            ptrStart = ptrStart + 11;
            ptrStart[0] = digits[unsigned(nurons[I].sensor) % 10];
            ptrStart = ptrStart + 1;

            //print if nuron is connection conected (1 = conected = true, 0 = not)
            tempVar = "\ncurrentConBool: ";
            memcpy(ptrStart, tempVar, 17);
            ptrStart = ptrStart + 17;

            for (unsigned i = 0; i < stats.maxConnections; i++)
            {
                ptrStart[i * 2] = digits[(unsigned)(conections[stats.maxConnections * I + i].connected) % 10];
                //printf("\n %u,%u: %u", I,i, conections[stats.maxConnections * I + i].connected);
                ptrStart[(i * 2) + 1] = ',';
            }

            ptrStart = ptrStart + (2 * stats.maxConnections) - 1;


            //print connected nuron time
            tempVar = "\ncurrentConTime: ";
            memcpy(ptrStart, tempVar, 17);
            ptrStart = ptrStart + 17;


            maxDigitsId = (unsigned int)(log10((double)stats.maxNuronTime) + 1);


            for (unsigned i = 0; i < stats.maxConnections; i++)
            {
                maxdigitsIdTemp = pow((double)10, (double)(maxDigitsId - 1));
                for (unsigned j = 0; j < maxDigitsId; j++)
                {
                    //ptrStart[(i * (maxDigitsId + 1)) + j] = digits[(nurons->connections->time / maxdigitsIdTemp)%9];
                    ptrStart[j] = digits[(conections[stats.maxConnections * I + i].time / maxdigitsIdTemp) % 10];
                    maxdigitsIdTemp = maxdigitsIdTemp / 10;
                }
                ptrStart[maxDigitsId] = ',';
                ptrStart = ptrStart + maxDigitsId + 1;
            }

            ptrStart = ptrStart - 1;

            //print connected nuron ID
            tempVar = "\ncurrentConId: ";
            memcpy(ptrStart, tempVar, 15);
            ptrStart = ptrStart + 15;

            maxDigitsId = (unsigned int)(log10((double)stats.totalNum) + 1);

            for (unsigned i = 0; i < stats.maxConnections; i++)
            {
                maxdigitsIdTemp = (unsigned int)pow((double)10, (double)(maxDigitsId - 1));
                //printf("save:: Nur%u: (%u = %u)\n", I, i, conections[stats.maxConnections * I + i].id);
                for (unsigned j = 0; j < maxDigitsId; j++)
                {
                    ptrStart[j] = digits[(conections[stats.maxConnections * I + i].id / maxdigitsIdTemp) % 10];
                    
                    maxdigitsIdTemp = maxdigitsIdTemp / 10;
                }

                //printf("\n");
                if (i + 1 < stats.maxConnections)
                {
                    ptrStart[maxDigitsId] = ',';
                    ptrStart = ptrStart + 1;

                }
                
                ptrStart = ptrStart + maxDigitsId;
            }
        }
    }

     cudaError_t Nurons::load(std::string path) {

        unsigned int theadsPerBlock = 1024;

        //ptr to all nurond on gpu+
        Nuron* dev_allNur = {};
        connection* dev_allconects = {};
        char* dev_filText = {};

       
       
     
        //loads file headder
          //file opening magic
        //http://www.cplusplus.com/forum/beginner/229845/
        std::ifstream file{ path };
        std::string const str = static_cast<std::ostringstream> (std::ostringstream{} << file.rdbuf()).str();

        cudaError_t cudaStatus = cudaSetDevice(0);
       
       
            //set token to look for 
        std::string find = "total:";//<<make a way of modifing thees throu a save rule set
            //look for token
        unsigned int offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
            //save vlaue to memory
        unsigned int total = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);

            //repeat
        find = "shape:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        unsigned int shape = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);

        find = "volume:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        unsigned int volX = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);

        find = ",";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        unsigned int volY = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);

        find = ",";
        offset = offset + STE::parse::parseForLoc(find.data(), find.size(), str.data() + offset, str.size() + offset) + find.size() + 1;
        unsigned int volZ = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);
        dim3 vol(volX, volY, volZ);

        find = "maxConnections:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        unsigned int maxConnections = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);
        if (total = !vol.x * vol.y * vol.z) {
            return cudaStatus;
        }

        find = "maxRange:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        unsigned int maxRange = STE::parse::getUnsigned(str.data() + offset, str.size() - offset);
        if (total = !vol.x * vol.y * vol.z) {
            return cudaStatus;
        }

        //find the start of the first nuron description.||later crate an error handler for parse so that errors can be detetced.
        
        find = "maxRange:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size();
        find = "Nuron:";
        offset = offset + STE::parse::parseForLoc(find.data(), find.size(), str.data() + offset, str.size() - offset) -1;
      
        const char* NurDecStart = str.data() + offset;

        //find the end of the first nuron decription
        find = "currentConId:";
        offset = STE::parse::parseForLoc(find.data(), find.size(), str.data(), str.size()) + find.size() + 1;
        find = "\n";
        offset = offset + STE::parse::parseForLoc(find.data(), find.size(), str.data() + offset, str.size() + offset) + find.size();
        const char* endNurDes = str.data() + offset;
       
        //apply headder to curreent nurrons
        //temporary vareables
        Nuron* tempNurPtr;
        connection* tempConnPtr;
        //create a "Nurons" object with the paramiters from file
        STE::Nurons temp(maxConnections, maxRange, vol, shape);//<<using 1 for nuron range it will be changed later oin code.
        //coppy stats object from temp
        this->stats = temp.stats;

        if (errors.isErr()) goto ErrorLoad;

        if (str.data() == 0) {
            std::cout << "no save file found" << std::endl;
            //add err stuff add cutom errors
            errors.push(cudaStatus);
            goto ErrorLoad;
        }

        //point to memory from the original Nurons object 
        tempNurPtr = this->allNurons;
        tempConnPtr = this->allConections;

        //have original nurons object adopt the temp memory
        this->allNurons = temp.allNurons;
        this->allConections = temp.allConections;

        //have the temp nurons object adopt he data from the temp pointers 
        temp.allConections = tempConnPtr;
        temp.allNurons = tempNurPtr;
        //htis^^^ section crates a temporary Nurons object with the recorded paramaters in order to initalize the data.
        //and then this section swapps the data from the original object and the new object. 
        //this alows for the old data to be deallocated cleenly within the new object.


        //unsigned int threds = 64;
        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);


        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrorLoad;
        }

        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorLoad;
        }
        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorLoad;
        }

        //allocate meemory on device for all the connections
        cudaStatus = cudaMalloc((void**)&dev_allconects, stats.totalNum * stats.maxConnections * sizeof(connection));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorLoad;
        }
        //coppy all cenections to device memory
        cudaStatus = cudaMemcpy(dev_allconects, allConections, stats.totalNum * stats.maxConnections * sizeof(connection), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorLoad;
        }

          //allocate space on the gpu for the text to be stored in
        cudaStatus = cudaMalloc((void**)&dev_filText, (str.size()-(str.data()- NurDecStart)) * sizeof(char));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrorLoad;
        }

        cudaStatus = cudaMemcpy(dev_filText, NurDecStart, (str.size() - (str.data() - NurDecStart)) * sizeof(char), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorLoad;
        }


        // Launch a kernel on the GPU with one thread for each element.

        LoadKernal <<< grid, theadsPerBlock >>> (dev_filText, (endNurDes- NurDecStart),stats, dev_allNur, dev_allconects);



        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrorLoad;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrorLoad;
        }

        // Copy nurons from gpu memory to cpu memory.
        cudaStatus = cudaMemcpy(allNurons, dev_allNur, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorLoad;
        }

        // Copy connections from gpu memory to cpu memory.
        cudaStatus = cudaMemcpy(allConections, dev_allconects, stats.totalNum* stats.maxConnections * sizeof(int), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrorLoad;
        }

        //on gpu sat values for nurons;
        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed! Do you have a CUDA-capable GPU installed?");
            goto ErrorLoad;
        }

    ErrorLoad:
    
        cudaFree(dev_allNur);
        cudaFree(dev_allconects);
        cudaFree(dev_filText);
       
        if (cudaStatus != cudaSuccess) {
            if (!errors.isErr())errors.push(cudaStatus);
        }
        return cudaStatus;
    }
     
    __global__ void LoadKernal(char* dev_filText, unsigned int nurBlock, STE::sts stats, STE::Nuron* nurons, connection* connections) {
        /* 
        * Initilize
        * *textPtr1
        * 
        * set text ptr to the location of the relevent nuron
        * 
        */
        //nuron id
        
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //chech id dosent exceed number of nur
        if (I >= stats.totalNum) {
            //printf("extra id %i", I);
        }
        else {
            
            //current ptr to where we want to write text
            //move the startiung ptr to the start of the corisponding block
           // prob wont need this -> char* currentPtr 
            const char* startPtr = dev_filText + (I * (nurBlock));
            unsigned int offset = 0;
            //grab ans set stats
            //test check
            
            //printf("nurblock %d \n", I);
            /*if (I = 0)
            {
                printf("chariter: %c, nuron: \n", startPtr[2], I);
            }*/
            
            
           
               // printf("%d, %d, %c \n", nurons[I].id, STE::parseDev::getUnsigned(startPtr, nurBlock), (startPtr+2)[0]);
            

            //range -- make a function to do this (gpu runable)
            char* find = "Range:";
            unsigned findLen = 6;

           
            STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock);
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            nurons[I].range = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
            
            //sensitivity
            find = "sensitivity:";
            findLen = 12;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            nurons[I].sensitivity = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);

            //activation 
            find = "activation:";
            findLen = 11;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            nurons[I].activation = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
            
            //sensor
            find = "isSensor:";
            findLen = 9;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            nurons[I].sensor = (bool)STE::parseDev::getInt(startPtr + offset, nurBlock - offset);

            //current con bool (multy)
            find = "currentConBool:";
            findLen = 15;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            if (stats.maxConnections > 0) {// check math on this
                connections[stats.maxConnections * I ].connected = (bool)STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                if (stats.maxConnections > 1) {
                    for (unsigned i = 1; i < stats.maxConnections;i++)
                    {

                        find = ",";
                        offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
                        connections[stats.maxConnections * I + i].connected = (bool)STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                    }
                }
            }

           //current con time (multy)
            find = "currentConTime:";
            findLen = 15;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            if (stats.maxConnections > 0) {// check math on this
                connections[stats.maxConnections * I].connected = (bool)STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                if (stats.maxConnections > 1) {
                    for (unsigned i = 1; i < stats.maxConnections; i++)
                    {
                        find = ",";
                        offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
                        connections[stats.maxConnections * I + i].time = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                    }
                }
            }

            //current con ID (multy)
            find = "currentConId:";
            findLen = 13;
            offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
            if (stats.maxConnections > 0) {// check math on this
                connections[stats.maxConnections * I].connected = (bool)STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                if (stats.maxConnections > 1) {
                    for (unsigned i = 1; i < stats.maxConnections; i++)
                    {
                        find = ",";
                        offset = STE::parseDev::parseForLoc(find, findLen, startPtr, nurBlock) + findLen;
                        connections[stats.maxConnections * I + i].id = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
                    }
                }
                
            }
            
            //nurons[I].sensitivity = STE::parseDev::getInt(startPtr + offset, nurBlock - offset);
            
        }
    }

     cudaError_t Nurons::setNuronSens(unsigned quant, unsigned* ids, bool sensor) {

        unsigned int theadsPerBlock = 1024;

        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);

        Nuron* dev_allNur = {};
        unsigned* dev_ids = {};

        //cuda error vareable
        cudaError_t cudaStatus = cudaSetDevice(0);
        if (errors.isErr()) goto ErrSetSens;
       

        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrSetSens;
        }
       
        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrSetSens;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSens;
        }

        cudaStatus = cudaMalloc((void**)&dev_ids, quant * sizeof(unsigned));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrSetSens;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_ids, ids, quant *sizeof(unsigned), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSens;
        }

        // Launch a kernel on the GPU with one thread for each element.

        setSensKernal <<< grid, theadsPerBlock >>> (dev_allNur, quant,dev_ids, sensor);


        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrSetSens;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrSetSens;
        }

        cudaStatus = cudaMemcpy(allNurons, dev_allNur, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSens;
        }

        //std::cout << "end save" << std::endl;
        goto noErrSetSens;
    ErrSetSens:

    noErrSetSens:
        //std::cout << "\n\n\n\n\n\n\n\ncpu result \n" << host_NuronDecription << std::endl;
        cudaFree(dev_allNur);
        cudaFree(dev_ids);
        if (cudaStatus != cudaSuccess) {
            if (!errors.isErr())errors.push(cudaStatus);
        }
        return cudaStatus;
     }

    __global__ void setSensKernal(Nuron* nurons, unsigned quant, unsigned* ids, bool sensor) {
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //loop through  maxDigitsId number of time (EX:4)
        if (I >= quant) {
            return;
        }
        nurons[ids[I]].sensor = sensor;
    }

    cudaError_t Nurons::updateSens(unsigned quant, unsigned* ids, bool* data) {
        unsigned int theadsPerBlock = 1024;
        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);

        Nuron* dev_allNur = {};
        unsigned* dev_ids = {};
        bool* dev_data = {};

        //cuda error vareable
        cudaError_t cudaStatus = cudaSetDevice(0);
        if (errors.isErr()) goto ErrSetSenUpdate;

        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrSetSenUpdate;
        }

        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrSetSenUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSenUpdate;
        }

        cudaStatus = cudaMalloc((void**)&dev_ids, quant * sizeof(unsigned));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrSetSenUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_ids, ids, quant * sizeof(unsigned), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSenUpdate;
        }


        cudaStatus = cudaMalloc((void**)&dev_data, quant * sizeof(bool));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrSetSenUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_data, ids, quant * sizeof(bool), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSenUpdate;
        }
        // Launch a kernel on the GPU with one thread for each element.

        updateSensKernal <<< grid, theadsPerBlock >> > (dev_allNur, quant, dev_ids, dev_data);


        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrSetSenUpdate;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrSetSenUpdate;
        }

        cudaStatus = cudaMemcpy(allNurons, dev_allNur, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrSetSenUpdate;
        }

        //std::cout << "end save" << std::endl;
        goto noErrSetSenUpdate;
    ErrSetSenUpdate:

    noErrSetSenUpdate:
        //std::cout << "\n\n\n\n\n\n\n\ncpu result \n" << host_NuronDecription << std::endl;
        cudaFree(dev_allNur);
        cudaFree(dev_data);
        cudaFree(dev_ids);

        if (cudaStatus != cudaSuccess) {
            if (!errors.isErr())errors.push(cudaStatus);
        }

        return cudaStatus;
    }

    __global__ void updateSensKernal(Nuron* nurons, unsigned quant, unsigned* ids, bool* data) {
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //loop through  maxDigitsId number of time (EX:4)
        if (I >= quant) {
            return;
        }
        nurons[ids[I]].activation = data[I];
    }
     
    cudaError_t Nurons::updateOut(unsigned quant, unsigned* ids, bool* data) {
        unsigned int theadsPerBlock = 1024;
        dim3 grid((stats.totalNum / theadsPerBlock) + 1, 1, 1);

        Nuron* dev_allNur = {};
        unsigned* dev_ids = {};
        bool* dev_data = {};

        //cuda error vareable
        cudaError_t cudaStatus = cudaSetDevice(0);
        if (errors.isErr()) goto ErrOutDataUpdate;
        

        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto ErrOutDataUpdate;
        }

        //allocate space on the gpu for all the nurons and set the dev_allNur ptr to that location
        cudaStatus = cudaMalloc((void**)&dev_allNur, stats.totalNum * sizeof(STE::Nuron));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrOutDataUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_allNur, allNurons, stats.totalNum * sizeof(STE::Nuron), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrOutDataUpdate;
        }

        cudaStatus = cudaMalloc((void**)&dev_ids, quant * sizeof(unsigned));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrOutDataUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_ids, ids, quant * sizeof(unsigned), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrOutDataUpdate;
        }


        cudaStatus = cudaMalloc((void**)&dev_data, quant * sizeof(bool));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto ErrOutDataUpdate;
        }

        //Copy nurons to device memory
        cudaStatus = cudaMemcpy(dev_data, ids, quant * sizeof(bool), cudaMemcpyHostToDevice);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrOutDataUpdate;
        }
        // Launch a kernel on the GPU with one thread for each element.

        updateOutKernal <<< grid, theadsPerBlock >> > (dev_allNur, quant, dev_ids, dev_data);

        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto ErrOutDataUpdate;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto ErrOutDataUpdate;
        }

        cudaStatus = cudaMemcpy(data, dev_data, quant * sizeof(bool), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto ErrOutDataUpdate;
        }

        //std::cout << "end save" << std::endl;
        goto noErrOutDataUpdate;
    ErrOutDataUpdate:

    noErrOutDataUpdate:
        //std::cout << "\n\n\n\n\n\n\n\ncpu result \n" << host_NuronDecription << std::endl;
        cudaFree(dev_allNur);
        cudaFree(dev_data);
        cudaFree(dev_ids);
        
        if (cudaStatus != cudaSuccess) {
            if (!errors.isErr())errors.push(cudaStatus);
        }
        return cudaStatus;
    }

    __global__ void updateOutKernal(Nuron* nurons, unsigned quant, unsigned* ids, bool* data) {
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //loop through  maxDigitsId number of time (EX:4)
        if (I >= quant) {
            return;
        }
        data[I] = nurons[ids[I]].activation;
    }

    cudaError_t Rand(int** data, unsigned quantity, int range, int offset) //reruns a pointer to allo=cated memmory containg random numbers within the range and ofset
    {
        //comments remove latter
        // 
        // 
        //printf("range:%d", range);
        //ptr to all nurond on gpu
        int* results;
        //cuda error vareable
        cudaError_t cudaStatus = cudaSetDevice(0);
        
        //dim3 RNG3(rand() % 100 + 900000, rand() % 100 + 900000, rand() % 100 + 900000);

        // Choose which GPU to run on, change this on a multi-GPU system.
        cudaStatus = cudaSetDevice(0);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
            goto Test1Error;
        }

        // allocate space on the gpu forresults
        cudaStatus = cudaMalloc((void**)&results, quantity * sizeof(int));
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMalloc failed!");
            goto Test1Error;
        }
        //seed neds to change fix

        curandGenerator_t gen;
        curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
//        srand(time(NULL));
        //uint64_t ms = std::chrono::duration_cast<std::chrono::milliseconds>
        uint64_t ms = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
//        curandSetPseudoRandomGeneratorSeed(gen, 7487 * rand());
        //debug std::cout << ms << std::endl;
        curandSetPseudoRandomGeneratorSeed(gen, 7487 * ms);
        curandGenerate(gen, ((unsigned*)results), quantity);
       
        // Launch a kernel on the GPU with one thread for each element.
         // create a grid of threds with the quantity of all the nurons
        unsigned int theadsPerBlock = 1024;
        dim3 grid((quantity / theadsPerBlock) + 1, 1, 1);
        rad <<< grid, theadsPerBlock >> > (results,quantity, range, offset);

        // Check for any errors launching the kernelwwww
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto Test1Error;
        }

        // cudaDeviceSynchronize waits for the kernel to finish, and returns
        // any errors encountered during the launch.
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
            goto Test1Error;
        }

        // Copy nurons from gpu memory to cpu memory.
        //free(data);//this seems wrong
       // *data = (int*)malloc(quantity * sizeof(int));

        cudaStatus = cudaMemcpy(*data, results, quantity * sizeof(int), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto Test1Error;
        }
        
      // printf("host rng:%d,%d,%d,%d-------\n", (*data)[0], (*data)[1], (*data)[2], (*data)[3]);

       /*debug for (size_t i = 0; i < quantity; i++)
        {
            std::cout << "value[" << i << "]:" << (*data)[i] << std::endl;
        }*/

    Test1Error:
    
        cudaFree(results);
        return cudaStatus;
    
    }

    //optomize rand by adding a boolian to the function to handle the destination ptr as a device or host ptr.

    __global__ void rad(int* data, unsigned quantity ,unsigned range, int offset) {
        
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //chech id dosent exceed number of nur
        if (I >= quantity) {
            return;
            //printf("extra id %i", I);
        }
        //try curand
        //debug printf("I:%u - Data:%i = %i mod %u + %i\n", I,data[I] % range + offset, data[I], range, offset);
        data[I] =( data[I] % range + offset);
        
        //printf("Data: %i\n", data[I]);
    }
}

extern "C"
{


}









//https://docs.nvidia.com/cuda/curand/host-api-overview.html
#endif







//Repressed================================================================================================
/*
    __global__ void updateKernal(STE::Nuron* nurons, connection* conections, sts stats, int* rng) {// only works when all nurons have the same number of max connections-

       //initilization---------------------------------------------------
        unsigned int I = (blockIdx.x * blockDim.x) + threadIdx.x;
        //end start--------------------------------------------------

        int timeAdd = 2;
        int timeSub = 1;
        int sensAdd = 2;
        int sensSub = 1;

        int* rngX;
        int* rngY;
        int* rngZ;
        int* rngT;

        rngX = rng + (3 * I);
        rngY = rngX + 1;
        rngZ = rngY + 1;
        rngT = rng + (3 * stats.totalNum) + I;

        //printf("rngX:%d\nrngY:%d\nrngZ:%d\nrngT:%d\n\n", rngX, rngY, rngZ, rngT);
        if (stats.totalNum < I) return;//exit if excee
        //if (I != 0)return;
        nurons[I].connections = conections + (I * stats.maxConnections);
        //if (I == 0)printf("1Device current connect:%d\n", nurons[1].currnetConections);


        //summ all conceted nuron conections----------------------------------------------------------------------------------
        int fialValue = 0;
        for (unsigned i = 0; i < stats.maxConnections; i++) // accelorate this
        {
            if (nurons[I].connections[i].connected)
            {
                if (nurons[nurons[I].connections[i].id].activation)
                {
                    fialValue = fialValue + (nurons[I].connections[i].time);
                    if (nurons[I].connections[i].time += timeAdd > nurons[I].maxNuronTime)
                    {
                        nurons[I].connections[i].time = nurons[I].maxNuronTime;
                    }

                }
                else
                {
                    //decreemt time  left and check if time is zeroif so remove from list
                    if (nurons[I].connections[i].time -= timeSub < 1) {
                        nurons[I].connections[i].connected = false;
                        nurons[I].connections[i].time = 0;
                        nurons[I].currnetConections--;
                    }
                }
            }
        }

        //if (I == 0)printf("2Device current connect:%d\n", nurons[1].currnetConections);

        // activate or not-------------------------------------------------------------------------------------------
        if (!nurons[I].sensor)
        {
            if (fialValue > nurons[I].sensitivity)
            {
                nurons[I].activation = true;
                nurons[I].sensitivity += sensAdd;
            }
            else {
                nurons[I].activation = false;
                nurons[I].sensitivity += sensSub;
            }

            if (nurons[I].sensitivity > nurons[I].maxSensitivity)
            {
                nurons[I].sensitivity = nurons[I].maxSensitivity;
            }

        }
        else {
            //write to sensor
            //nurons[I].activation = true;
        }


        //cpmpare a random number to the amount of un used connections----------------------------------------------------------------------------------------------------------
        rngX = rng + (3 * I);
        rngY = rngX + 1;
        rngZ = rngY + 1;
        rngT = rng + (3 * stats.totalNum) + I;

        if(*rngT> (nurons[I].currnetConections / stats.maxConnections))
        {
            if (nurons[I].currnetConections>0) {
                printf("got 2");
            }


            unsigned int xLow = nurons[I].range;
            unsigned int xHigh = xLow;
            unsigned int yLow = xLow;
            unsigned int yHigh = xLow;
            unsigned int zLow = xLow;
            unsigned int zHigh = xLow;

            //make shure selection is in the volume of nurons
            if (nurons[I].position.x + xHigh > stats.volume.x)
            {
                xHigh = stats.volume.x - nurons[I].position.x;
            }

            if ((int)(nurons[I].position.x - xLow) < 0)
            {
                xLow = nurons[I].position.x;
            }

            if (nurons[I].position.y + yHigh > stats.volume.y)
            {
                yHigh = stats.volume.y - nurons[I].position.y;
            }

            if ((int)(nurons[I].position.y - yLow) < 0)
            {
                yLow = nurons[I].position.y;
            }

            if (nurons[I].position.z + zHigh > stats.volume.z)
            {
                zHigh = stats.volume.z - nurons[I].position.z;
            }

            if ((int)(nurons[I].position.z - zLow) < 0)
            {
                zLow = nurons[I].position.z;
            }

            //choos a location
            int x = nurons[I].position.x + *rngX % (xLow + 1 + xHigh) - xLow;
            int y = nurons[I].position.y + *rngY % (xLow + 1 + yHigh) - yLow;
            int z = nurons[I].position.z + *rngZ % (zLow + 1 + zHigh) - zLow;


            for (unsigned i = 0; i < nurons[I].currnetConections; i++)
            {
                if (!nurons[I].connections[i].connected)
                {

                    nurons[I].connections[i].connected = true;
                    // ana rbitry starting number
                    nurons[I].connections[i].time = 500;
                    // new connection id  =  z*area + y * maxXDimentid + x
                    nurons[I].connections[i].id = (z * (stats.volume.y * stats.volume.x)) + (y * stats.volume.x) + x;
                   // printf("is:%d  \n", I);
                    //incremnt number of connections
                    nurons[I].currnetConections++;
                    i = stats.maxConnections;
                    printf("connecting(%d)to(%d-{%d,%d,%d})\n", I, (z* (stats.volume.y* stats.volume.x)) + (y * stats.volume.x) + x,x,y,z);
                }
            }
        }
        //addconnections
        //goal probability of forming a new conection decreses with number of currnet connections.
    }
    */