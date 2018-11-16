/*
  Operators

  Copyright 2010-201x held jointly by LANS/LANL, LBNL, and PNNL. 
  Amanzi is released under the three-clause BSD License. 
  The terms of use and "as is" disclaimer for this license are 
  provided in the top-level COPYRIGHT file.

  Author: Konstantin Lipnikov (lipnikov@lanl.gov)
*/

#ifndef AMANZI_RECONSTRUCTION_CELL_HH_
#define AMANZI_RECONSTRUCTION_CELL_HH_

#include <vector>

#include "Epetra_IntVector.h"
#include "Epetra_MultiVector.h"
#include "Teuchos_RCP.hpp"

#include "CompositeVector.hh"
#include "DenseMatrix.hh"
#include "DenseVector.hh"
#include "Mesh.hh"
#include "Point.hh"

#include "Reconstruction.hh"


namespace Amanzi {
namespace Operators {

class ReconstructionCell : public Reconstruction {  
 public:
  ReconstructionCell() {};
  ReconstructionCell(Teuchos::RCP<const Amanzi::AmanziMesh::Mesh> mesh) : Reconstruction(mesh) {};
  ~ReconstructionCell() {};

  // save pointer to the already distributed field.
  virtual void Init(Teuchos::RCP<const Epetra_MultiVector> field,
                    Teuchos::ParameterList& plist, int component = 0) override;

  // unlimited gradient
  // -- compute gradient and keep it internally
  virtual void ComputeGradient() override;

  // -- compute gradient only in specified cells
  void ComputeGradient(const AmanziMesh::Entity_ID_List& ids,
                       std::vector<AmanziGeometry::Point>& gradient);

  // calculate value of a linear function at point p
  double getValue(int c, const AmanziGeometry::Point& p);
  double getValue(const AmanziGeometry::Point& gradient, int c, const AmanziGeometry::Point& p);

  // access
  Teuchos::RCP<CompositeVector> gradient() { return gradient_; }

 private:
  void PopulateLeastSquareSystem_(AmanziGeometry::Point& centroid,
                                  double field_value,
                                  WhetStone::DenseMatrix& matrix,
                                  WhetStone::DenseVector& rhs);

  // On intersecting manifolds, we extract neighboors living in the same manifold
  // using a smoothness criterion.
  void CellFaceAdjCellsNonManifold_(AmanziMesh::Entity_ID c,
                                    AmanziMesh::Parallel_type ptype,
                                    std::vector<AmanziMesh::Entity_ID>& cells) const;
 private:
  int dim, poly_order_;
  Teuchos::RCP<CompositeVector> gradient_;
};

}  // namespace Operators
}  // namespace Amanzi

#endif
