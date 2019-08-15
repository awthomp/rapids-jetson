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
$ conda install cmake_setuptools boost-cpp cython pandas cffi rapidjson \
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

### libcudf
Note: I had to edit [ConfigureArrow](https://github.com/rapidsai/cudf/blob/master/cpp/cmake/Modules/ConfigureArrow.cmake) to enable building with Python since pyarrow is not available in the available conda channels. Set: `DARROW_PYTHON=ON`, `DARROW_COMPUTE=ON`, and `DARROW_BUILD_SHARED=ON`

Note: I could not get a successful build of libcudf with parallel compilation, i.e. `make -j6` and edited the build.sh script to build with one core.

```
$ git clone --recurse-submodules https://github.com/rapidsai/cudf.git
$ cd cudf
$ ./build.sh libcudf
```
Install Python Arrow bindings
```
$ cd cpp/build/arrow/arrow/python
$ python setup.py build_ext --inplace
$ python setup.py install --single-version-externally-managed --record=record.txt
```
