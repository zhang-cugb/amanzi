/*
  WhetStone, Version 2.2
  Release name: naka-to.

  Copyright 2010-201x held jointly by LANS/LANL, LBNL, and PNNL. 
  Amanzi is released under the three-clause BSD License. 
  The terms of use and "as is" disclaimer for this license are 
  provided in the top-level COPYRIGHT file.

  Author: Konstantin Lipnikov (lipnikov@lanl.gov)

  Derham complex: mimetic inner products on edges.
*/

#ifndef AMANZI_DERHAM_EDGE_HH_
#define AMANZI_DERHAM_EDGE_HH_

#include "Teuchos_RCP.hpp"

#include "Mesh.hh"

#include "DenseMatrix.hh"
#include "InnerProductL2.hh"
#include "Tensor.hh"

namespace Amanzi {
namespace WhetStone {

class DeRham_Edge : public virtual InnerProductL2 { 
 public:
  DeRham_Edge(const Teuchos::RCP<const AmanziMesh::Mesh>& mesh) 
    : mesh_(mesh),
      d_(mesh->space_dimension()) {};
  ~DeRham_Edge() {};

  virtual int L2consistency(int c, const Tensor& T, DenseMatrix& N, DenseMatrix& Mc, bool symmetry) override;
  virtual int MassMatrix(int c, const Tensor& T, DenseMatrix& M) override; 

  virtual int L2consistencyInverse(int c, const Tensor& T, DenseMatrix& R, DenseMatrix& Wc, bool symmetry) override;
  virtual int MassMatrixInverse(int c, const Tensor& T, DenseMatrix& W) override; 

 protected:
  int L2consistency2D_(int c, const Tensor& T, DenseMatrix& N, DenseMatrix& Mc);
  int L2consistency3D_(int c, const Tensor& T, DenseMatrix& N, DenseMatrix& Mc);

  int L2consistencyInverse2D_(int c, const Tensor& T, DenseMatrix& R, DenseMatrix& Wc);
  int L2consistencyInverse3D_(int c, const Tensor& T, DenseMatrix& R, DenseMatrix& Wc);

 protected:
  Teuchos::RCP<const AmanziMesh::Mesh> mesh_;
  int d_;
};

}  // namespace WhetStone
}  // namespace Amanzi

#endif

