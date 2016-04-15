/*
  Operators

  Copyright 2010-201x held jointly by LANS/LANL, LBNL, and PNNL. 
  Amanzi is released under the three-clause BSD License. 
  The terms of use and "as is" disclaimer for this license are 
  provided in the top-level COPYRIGHT file.

  Author: Konstantin Lipnikov (lipnikov@lanl.gov)
*/

#include <cstdlib>
#include <cmath>
#include <iostream>
#include <string>
#include <vector>

// TPLs
#include "Teuchos_RCP.hpp"
#include "Teuchos_ParameterList.hpp"
#include "Teuchos_ParameterXMLFileReader.hpp"
#include "UnitTest++.h"

// Amanzi
#include "GMVMesh.hh"
#include "LinearOperatorFactory.hh"
#include "MeshFactory.hh"
#include "Mesh_MSTK.hh"
#include "mfd3d_diffusion.hh"
#include "Tensor.hh"

// Amanzi::Operators
#include "AnalyticMHD_01.hh"
#include "AnalyticMHD_02.hh"
#include "AnalyticMHD_03.hh"

#include "Operator.hh"
#include "OperatorAccumulation.hh"
#include "OperatorElectromagneticsMHD.hh"
#include "OperatorDefs.hh"
#include "Verification.hh"

/* *****************************************************************
* TBW 
* **************************************************************** */
template<class Analytic>
void ResistiveMHD(double c_t, double tolerance, bool initial_guess) {
  using namespace Teuchos;
  using namespace Amanzi;
  using namespace Amanzi::AmanziMesh;
  using namespace Amanzi::AmanziGeometry;
  using namespace Amanzi::Operators;

  Epetra_MpiComm comm(MPI_COMM_WORLD);
  int MyPID = comm.MyPID();

  if (MyPID == 0) std::cout << "\nTest: Resistive MHD, tol=" << tolerance << std::endl;

  // read parameter list
  std::string xmlFileName = "test/operator_electromagnetics.xml";
  ParameterXMLFileReader xmlreader(xmlFileName);
  ParameterList plist = xmlreader.getParameters();

  // create a MSTK mesh framework
  ParameterList region_list = plist.get<Teuchos::ParameterList>("Regions");
  Teuchos::RCP<GeometricModel> gm = Teuchos::rcp(new GeometricModel(3, region_list, &comm));

  FrameworkPreference pref;
  pref.clear();
  pref.push_back(MSTK);

  MeshFactory meshfactory(&comm);
  meshfactory.preference(pref);

  bool request_faces(true), request_edges(true);
  // RCP<const Mesh> mesh = meshfactory(0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 3, 3, 3, gm, request_faces, request_edges);
  RCP<const Mesh> mesh = meshfactory("test/hex_split_faces5.exo", gm, request_faces, request_edges);

  // create resistivity coefficient
  double time = 1.0;
  Analytic ana(mesh);
  WhetStone::Tensor Kc(3, 2);

  Teuchos::RCP<std::vector<WhetStone::Tensor> > K = Teuchos::rcp(new std::vector<WhetStone::Tensor>());
  int ncells_owned = mesh->num_entities(AmanziMesh::CELL, AmanziMesh::OWNED);

  for (int c = 0; c < ncells_owned; c++) {
    const AmanziGeometry::Point& xc = mesh->cell_centroid(c);
    Kc = ana.Tensor(xc, time);
    K->push_back(Kc);
  }

  // create boundary data
  int nedges_owned = mesh->num_entities(AmanziMesh::EDGE, AmanziMesh::OWNED);
  int nedges_wghost = mesh->num_entities(AmanziMesh::EDGE, AmanziMesh::USED);
  int nfaces_wghost = mesh->num_entities(AmanziMesh::FACE, AmanziMesh::USED);

  std::vector<int> bc_model(nedges_wghost, OPERATOR_BC_NONE);
  std::vector<double> bc_value(nedges_wghost);
  std::vector<double> bc_mixed;

  std::vector<int> edirs;
  AmanziMesh::Entity_ID_List cells, edges;

  for (int f = 0; f < nfaces_wghost; ++f) {
    const AmanziGeometry::Point& xf = mesh->face_centroid(f);

    if (fabs(xf[0]) < 1e-6 || fabs(xf[0] - 1.0) < 1e-6 ||
        fabs(xf[1]) < 1e-6 || fabs(xf[1] - 1.0) < 1e-6 ||
        fabs(xf[2]) < 1e-6 || fabs(xf[2] - 1.0) < 1e-6) {

      mesh->face_get_edges_and_dirs(f, &edges, &edirs);
      int nedges = edges.size();
      for (int i = 0; i < nedges; ++i) {
        int e = edges[i];
        double len = mesh->edge_length(e);
        const AmanziGeometry::Point& tau = mesh->edge_vector(e);
        const AmanziGeometry::Point& xe = mesh->edge_centroid(e);

        bc_model[e] = OPERATOR_BC_DIRICHLET;
        bc_value[e] = (ana.electric_exact(xe, time) * tau) / len;
      }
    }
  }
  Teuchos::RCP<BCs> bc = Teuchos::rcp(new BCs(OPERATOR_BC_TYPE_EDGE, bc_model, bc_value, bc_mixed));

  // create electromagnetics operator
  Teuchos::ParameterList olist = plist.get<Teuchos::ParameterList>("PK operator")
                                      .get<Teuchos::ParameterList>("electromagnetics operator");
  Teuchos::RCP<OperatorElectromagneticsMHD> op_mhd = Teuchos::rcp(new OperatorElectromagneticsMHD(olist, mesh));
  op_mhd->SetBCs(bc, bc);

  // create/extract solution maps
  const CompositeVectorSpace& cvs_e = op_mhd->global_operator()->DomainMap();

  Teuchos::RCP<CompositeVectorSpace> cvs_b = Teuchos::rcp(new CompositeVectorSpace());
  cvs_b->SetMesh(mesh)->SetGhosted(true)
       ->AddComponent("face", AmanziMesh::FACE, 1);

  CompositeVector E(cvs_e);
  CompositeVector B(*cvs_b);

  // create source for a manufactured solution.
  CompositeVector source(cvs_e);
  Epetra_MultiVector& src = *source.ViewComponent("edge");

  for (int c = 0; c < ncells_owned; c++) {
    mesh->cell_get_edges(c, &edges);
    int nedges = edges.size();
    double vol = 3.0 * mesh->cell_volume(c) / nedges;

    for (int n = 0; n < nedges; ++n) {
      int e = edges[n];
      double len = mesh->edge_length(e);
      const AmanziGeometry::Point& tau = mesh->edge_vector(e);
      const AmanziGeometry::Point& xe = mesh->edge_centroid(e);

      src[0][e] += (ana.source_exact(xe, time) * tau) / len * vol;
    }
  }
  source.GatherGhostedToMaster("edge");

  // set up initial guess for a time-dependent problem
  Epetra_MultiVector& Ee = *E.ViewComponent("edge");
  Ee.PutScalar(0.0);

  if (initial_guess) {
    for (int e = 0; e < nedges_owned; e++) {
      double len = mesh->edge_length(e);
      const AmanziGeometry::Point& tau = mesh->edge_vector(e);
      const AmanziGeometry::Point& xe = mesh->edge_centroid(e);

      Ee[0][e] = (ana.electric_exact(xe, time) * tau) / len;
    }
  } 

  // set up the diffusion operator
  op_mhd->SetTensorCoefficient(K);
  op_mhd->UpdateMatrices();

  // Add an accumulation term.
  CompositeVector phi(cvs_e);
  phi.PutScalar(c_t);

  Teuchos::RCP<Operator> global_op = op_mhd->global_operator();
  Teuchos::RCP<OperatorAccumulation> op_acc =
      Teuchos::rcp(new OperatorAccumulation(AmanziMesh::EDGE, global_op));

  double dT = 1.0;
  op_acc->AddAccumulationTerm(E, phi, dT, "edge");

  // BCs, sources, and assemble
  op_mhd->ApplyBCs(true, true);
  global_op->SymbolicAssembleMatrix();
  global_op->AssembleMatrix();
  global_op->UpdateRHS(source, false);
  op_mhd->ModifyMatrices(E, B);

  ParameterList slist = plist.get<Teuchos::ParameterList>("Preconditioners");
  global_op->InitPreconditioner("Hypre AMG", slist);

  // Test SPD properties of the matrix and preconditioner.
  Verification ver(global_op);
  ver.CheckMatrixSPD(true, true);
  ver.CheckPreconditionerSPD(true, true);

  // Solve the problem.
  ParameterList lop_list = plist.get<Teuchos::ParameterList>("Solvers");
  AmanziSolvers::LinearOperatorFactory<Operator, CompositeVector, CompositeVectorSpace> factory;
  Teuchos::RCP<AmanziSolvers::LinearOperator<Operator, CompositeVector, CompositeVectorSpace> >
     solver = factory.Create("AztecOO CG", lop_list, global_op);

  CompositeVector& rhs = *global_op->rhs();
  int ierr = solver->ApplyInverse(rhs, E);

  op_mhd->ModifyFields(E, B);

  // verify convergence
  int num_itrs = solver->num_itrs();
  CHECK(num_itrs < 100);

  if (MyPID == 0) {
    std::cout << "pressure solver (" << solver->name() 
              << "): ||r||=" << solver->residual() << " itr=" << solver->num_itrs()
              << " code=" << solver->returned_code() << std::endl;
  }

  // compute various errors
  double enorm, el2_err, einf_err;
  ana.ComputeEdgeError(Ee, time, enorm, el2_err, einf_err);

  if (MyPID == 0) {
    el2_err /= enorm; 
    el2_err /= enorm;
    printf("L2(e)=%10.7f  Inf(e)=%9.6f  itr=%3d  size=%d\n", el2_err, einf_err,
            solver->num_itrs(), rhs.GlobalLength());

    CHECK(el2_err < tolerance);
  }
}


TEST(RESISTIVE_MHD_LINEAR) {
  ResistiveMHD<AnalyticMHD_01>(1.0e-3, 1e-3, false);
}

