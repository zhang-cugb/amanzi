/*
  Operators

  Copyright 2010-201x held jointly by LANS/LANL, LBNL, and PNNL. 
  Amanzi is released under the three-clause BSD License. 
  The terms of use and "as is" disclaimer for this license are 
  provided in the top-level COPYRIGHT file.

  Authors: Konstantin Lipnikov (lipnikov@lanl.gov)
           Ethan Coon (ecoon@lanl.gov)

  Operator whose unknowns are defined by general schema.

  The only thing really implemented here is the visitor pattern Op
  acceptors. Everything else should be done in the base class, with
  the exception of special assembly issues.
*/

#ifndef AMANZI_OPERATOR_SCHEMA_HH_
#define AMANZI_OPERATOR_SCHEMA_HH_

#include "DenseVector.hh"
#include "Operator.hh"
#include "Schema.hh"

namespace Amanzi {
namespace Operators {

class Operator_Schema : public Operator {
 public:
  // main constructor
  // The input CVS is the domain and range of the operator.
  Operator_Schema(const Teuchos::RCP<const CompositeVectorSpace>& cvs_col,
                  const Teuchos::RCP<const CompositeVectorSpace>& cvs_row,
                  Teuchos::ParameterList& plist,
                  const Schema& schema_col,
                  const Schema& schema_row) :
      Operator(cvs_col, cvs_row, plist, schema_col, schema_row) {
    set_schema_string(schema_col.CreateUniqueName());
  }

  // rhs update
  virtual void UpdateRHS(const CompositeVector& source, bool volume_included);

  // visit methods for Apply
  virtual int ApplyMatrixFreeOp(const Op_Cell_Schema& op,
          const CompositeVector& X, CompositeVector& Y) const;

  // driver symbolic assemble creates supermap using new schema
  virtual void SymbolicAssembleMatrix();

  // visit methods for symbolic assemble
  virtual void SymbolicAssembleMatrixOp(const Op_Cell_Schema& op,
          const SuperMap& map, GraphFE& graph,
          int my_block_row, int my_block_col) const;
  
  // visit methods for assemble
  virtual void AssembleMatrixOp(const Op_Cell_Schema& op,
          const SuperMap& map, MatrixFE& mat,
          int my_block_row, int my_block_col) const;

  // local <-> global communications
  void ExtractVectorOp(int c, const Schema& schema,
                       WhetStone::DenseVector& v, const CompositeVector& X) const ;
  void AssembleVectorOp(int c, const Schema& schema,
                        const WhetStone::DenseVector& v, CompositeVector& X) const;
};

}  // namespace Operators
}  // namespace Amanzi


#endif

    

