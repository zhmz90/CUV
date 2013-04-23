#include "theano_ops.hpp" 
#include "../../../3rd_party/cuda_ndarray/conv.cu"
#include "../../../3rd_party/cuda_ndarray/cuda_ndarray.cuh"
#include <vector>
CudaNdarray* cnda_flip_dims2and3(CudaNdarray* self);
int  CudaNdarray_reshape_2(CudaNdarray * self, CudaNdarray * rval, int * rval_dims, unsigned int rval_nd);
namespace cuv{

namespace theano_ops{

PyMODINIT_FUNC initcuda_ndarray(void);
PyObject * CudaNdarray_dimshuffle(PyObject* _unused, PyObject* args);


void initcuda(){
    std::cout << "init cuda and py" << std::endl;
    Py_Initialize();
    initcuda_ndarray();
}

void finalize_cuda(){
   Py_Finalize();
}

void view(CudaNdarray*& nda, cuv::tensor<float,cuv::dev_memory_space>& ct){
    int nd = ct.ndim();
    nda = (CudaNdarray*)CudaNdarray_New(nd); // same number of dimensions
    int size = 1; // strides in contiguous tensor
    for(int i=nd-1;i>=0;--i){
        /*CudaNdarray_set_stride(nda, i, ct.shape(i)==1 ? 0: size);*/
        CudaNdarray_set_stride(nda, i, ct.stride(i));
        CudaNdarray_set_dim(nda, i, ct.shape(i));
        size = size * ct.shape(i);
    }
    cnda_copy_structure_to_device(nda);
    nda->devdata = ct.ptr();
}





void dim_shuffle2(cuv::tensor<float,cuv::dev_memory_space>& dst, cuv::tensor<float,cuv::dev_memory_space>& src, int new_dims[], unsigned int size){
    assert(src.ndim() == size);

    CudaNdarray *csrc;
    CudaNdarray *cdst;
    view(csrc, src);

   std::cout << std::endl;
    // shuffles the dims
    if(0 != CudaNdarray_dimshuffle(csrc, size,new_dims))
        throw std::runtime_error("could not dimshuffle tensor");

    // determines a new shape of a tensor
    std::vector<unsigned int> new_shape(size);
    int shape[size];
    for(unsigned int i = 0; i < size; i++){
       new_shape[i] = src.shape(new_dims[i]);
       shape[i] = new_shape[i];
    }

    dst.reshape(new_shape);
    view(cdst, dst);
    // reshapes to row_major
    if(1 !=CudaNdarray_reshape_2(csrc,cdst, shape, size))
       throw std::runtime_error("could not reshape tensor");

    for(int i = 0; i < size; i++){
        std::cout << " dim " << dst.shape(i) << "    " << CudaNdarray_HOST_DIMS(cdst)[i] << std::endl;
        std::cout << " stride " << dst.stride(i) << "    " << CudaNdarray_HOST_STRIDES(cdst)[i] << std::endl;
    }

    Py_DECREF(csrc);
    Py_DECREF(cdst);
}

void flip_dim2and3(cuv::tensor<float,cuv::dev_memory_space>& dst, cuv::tensor<float,cuv::dev_memory_space>& src){
    CudaNdarray *cout;
    CudaNdarray *cflipped;
    CudaNdarray *cdst;
    view(cout, src);
    view(cdst, dst);

    cflipped = cnda_flip_dims2and3(cout);


    unsigned int size = dst.ndim();
    int shape[size];
    for(unsigned int i = 0; i < size; i++){
        shape[i] = dst.shape(i);
        std::cout << shape[i]  <<  "   " << CudaNdarray_HOST_DIMS(cflipped)[i] << "   " << CudaNdarray_HOST_STRIDES(cflipped)[i]<< std::endl;
    }

    if(1 !=CudaNdarray_reshape_2(cflipped,cdst, shape, size)){
       std::cout << " in error " << std::endl;/* cursor */
       throw std::runtime_error("could not reshape tensor");
       Py_DECREF(cout);
       Py_DECREF(cflipped);
       Py_DECREF(cdst);
    }


    Py_DECREF(cout);
    std::cout << " in 5a " << std::endl;/* cursor */
    Py_DECREF(cflipped);
    Py_DECREF(cdst);
    std::cout << " in 6a " << std::endl;/* cursor */
}


}

}
