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

`sudo apt install libprotobuf-dev libprotoc-dev thrift-compiler`

## Create and enable swap space
This prevents us from running out of memory while building cuDF. I followed [this link](https://devtalk.nvidia.com/default/topic/1041894/jetson-agx-xavier/creating-a-swap-file/)

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
$ conda install cmake boost-cpp cython pandas cffi rapidjson \
  double-conversion flatbuffers zstd numba
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


### Thrift
Parquet headers in Arrow use CXXFunctionals that aren't available in newer versions of Thrift. Instead, leverage v0.10.
```
$ export PY_PATH=$CONDA_PREFIX
$ git clone https://github.com/apache/thrift.git
$ cd thrift
$ git checkout -b 0.10.0
$ ./bootstrap.sh
$ ./configure --without-java --prefix=$CONDA_PREFIX
$ sudo make install
```

### libcudf
Note: I had to edit [ConfigureArrow](https://github.com/rapidsai/cudf/blob/master/cpp/cmake/Modules/ConfigureArrow.cmake) to enable building with Python since pyarrow is not available in the conda channels. Set: `DARROW_PYTHON=ON`, `DARROW_COMPUTE=ON`, `DARROW_BUILD_SHARED=ON`, `DARROW_ORC=ON`, and `DARROW_PARQUET=ON`

Note: I could not get a successful build of libcudf with parallel compilation, i.e. `make -j6` and edited the build.sh script to build with one core.

```
$ git clone --recurse-submodules https://github.com/rapidsai/cudf.git
$ cd cudf
$ ./build.sh libcudf
```
Add Arrow install directory to LD_LIBRARY_PATH

`export LD_LIBRARY_PATH=<...>/cpp/build/arrow/install/lib:$LD_LIBRARY_PATH`

Add Arrow install directory to ARROW_HOME

`export ARROW_HOME=<...>/cpp/build/arrow/install`

Add Parquet install directory to PARQUET_HOME

`export PARQUET_HOME=<...>/cpp/build/arrow/install`

Install Python Arrow bindings
```
$ export PYARROW_WITH_ORC=1
$ export PYARROW_WITH_PARQUET=1
$ cd cpp/build/arrow/arrow/python
$ python setup.py build_ext --inplace
$ python setup.py install --single-version-externally-managed --record=record.txt
```

### cuDF
I had to edit cudf's setup.py to add the include dir for Arrow, adding `cpp/build/arrow/install/include`
```
$ ./build.sh cudf
```

