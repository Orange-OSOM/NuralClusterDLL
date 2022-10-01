# NuralClusterDLL
This project is intended to use the principle of Emergent behavior to be the framework for an artificial intelligence. The base concept is to code an approximation of a neuron cell and run that approximation in parallel using Nvidia's Cuda for parallelization. 

The finished system should include the following.

*A save system to store and recall states of the system. This includes all aspects of all neurons. This means that once an instance is saved and closed and reopened, the next tick should be seamless from the perspective of the system.

*A load system (see above).

*Initialization, generating an instance of the system.

*Update, this progresses the system one tick. Or progresses the system a specified number of ticks.

*attach/detach, linking simulated neurons to external code. Allowing for input/output.

*The neurons themselves. Subject to change. Current system includes position in the system. List of connections. Sensor status(attach {input to system}). Number of maximum connections. Time connected to each neuron. A list of each connected neuron. 

