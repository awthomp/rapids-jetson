# RAPIDS Pre-Reqs
## Software Dependencies
Compiler requirements:

* gcc version 5.4+
* nvcc version 9.2+
* cmake version 3.12.4+

CUDA/GPU requirements:

* CUDA 9.2+
* NVIDIA driver 396.44+
* Pascal architecture or better

`sudo apt install libprotobuf-dev libprotoc-dev zstd`

# Create and enable swap space
I followed [this link](https://devtalk.nvidia.com/default/topic/1041894/jetson-agx-xavier/creating-a-swap-file/)

## Conda For ARM
* Install [conda4aarch64](https://github.com/jjhelmus/conda4aarch64/releases).
* Add c4aarch64 and conda-forge channels to conda configuration
```
$ conda config --add channels c4aarch64
$ conda config --add channels conda-forge
```

# cuDF
## Conda Dependencies
```
$ conda install -c numba numba
$ conda install cmake boost-cpp cython pandas cffi rapidjson \
  double-conversion flatbuffers
```

## Pip Dependencies
```
$ pip install cmake-setuptools
```

## GitHub Dependencies
### DLPack
```
$ git clone https://github.com/dmlc/dlpack.git
$ cd dlpack
$ mkdir build && cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX
$ make -j6
$ make install
```

## Install Directions
### RMM
```
$ git clone --recurse-submodules https://github.com/rapidsai/rmm.git
$ cd rmm
$ mkdir build && cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX
$ make -j6
$ make install
```

### cuStrings
```
$ git clone --recurse-submodules https://github.com/rapidsai/custrings.git
$ cd custrings
$ ./build.sh
```

### ORC
```
$ git clone https://github.com/apache/orc.git
$ cd orc
$ mkdir build && cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DBUILD_JAVA=OFF
$ make package
$ make test-out
```

### libcudf
Note: I had to edit [ConfigureArrow](https://github.com/rapidsai/cudf/blob/master/cpp/cmake/Modules/ConfigureArrow.cmake) to enable building with Python since pyarrow is not available in the available conda channels. Set: `DARROW_PYTHON=ON`, `DARROW_COMPUTE=ON`, and `DARROW_BUILD_SHARED=ON`

Note: I could not get a successful build of libcudf with parallel compilation, i.e. `make -j6` and edited the build.sh script to build with one core.

```
$ git clone --recurse-submodules https://github.com/rapidsai/cudf.git
$ cd cudf
$ ./build.sh libcudf
```
Add Arrow install directory to LD_LIBRARY_PATH

`export LD_LIBRARY_PATH=<...>/cpp/build/arrow/install/lib:$LD_LIBRARY_PATH`

Add Arrow install directory to ARROW_HOME

`export ARROW_HOME=<...>/cpp.build/arrow/install`

Compression stuff: https://stackoverflow.com/questions/48157198/how-can-i-statically-link-arrow-when-building-parquet-cpp

Install Python Arrow bindings
```
$ cd cpp/build/arrow/arrow/python
$ python setup.py build_ext --inplace
$ python setup.py install --single-version-externally-managed --record=record.txt
```

### cuDF
I had to edit cudf's setup.py to add the include dir for Arrow, adding `cpp/build/arrow/install/include`
```
$ ./build.sh cudf
```

