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
#include "MeshFactory.hh"
#include "GMVMesh.hh"
#include "LinearOperatorPCG.hh"
#include "NumericalIntegration.hh"
#include "Tensor.hh"

// Operators
#include "Analytic00.hh"
#include "OperatorDefs.hh"
#include "PDE_Abstract.hh"


/* *****************************************************************
* Exactness test for high-order Crouziex-Raviart elements.
* **************************************************************** */
TEST(OPERATOR_DIFFUSION_HIGH_ORDER_CROUZIEX_RAVIART) {
  using namespace Teuchos;
  using namespace Amanzi;
  using namespace Amanzi::AmanziMesh;
  using namespace Amanzi::AmanziGeometry;
  using namespace Amanzi::Operators;
  using namespace Amanzi::WhetStone;

  Epetra_MpiComm comm(MPI_COMM_WORLD);
  int MyPID = comm.MyPID();
  if (MyPID == 0) std::cout << "\nTest: 2D elliptic solver, high-order Crouzier-Raviart" << std::endl;

  // read parameter list
  std::string xmlFileName = "test/operator_diffusion.xml";
  ParameterXMLFileReader xmlreader(xmlFileName);
  ParameterList plist = xmlreader.getParameters();

  // create a mesh framework
  ParameterList region_list = plist.sublist("regions");
  Teuchos::RCP<GeometricModel> gm = Teuchos::rcp(new GeometricModel(2, region_list, &comm));

  MeshFactory meshfactory(&comm);
  meshfactory.preference(FrameworkPreference({MSTK, STKMESH}));
  RCP<const Mesh> mesh = meshfactory(0.0, 0.0, 1.0, 1.0, 4, 4, gm, true, true);
  // RCP<const Mesh> mesh = meshfactory("test/median7x8_filtered.exo", gm, true, true);

  int nfaces_wghost = mesh->num_entities(AmanziMesh::FACE, AmanziMesh::Parallel_type::ALL);
  int nnodes_wghost = mesh->num_entities(AmanziMesh::NODE, AmanziMesh::Parallel_type::ALL);

  // create boundary data (no mixed bc)
  ParameterList op_list = plist.sublist("PK operator")
                               .sublist("diffusion operator Crouzeix-Raviart");
  int order = op_list.get<int>("method order");

  Analytic00 ana(mesh, 1.0, 2.0, order);

  Point xv(2), x0(2), x1(2);
  AmanziMesh::Entity_ID_List nodes;

  Teuchos::RCP<BCs> bc_f = Teuchos::rcp(new BCs(mesh, AmanziMesh::FACE, DOF_Type::VECTOR));
  std::vector<int>& bc_model_f = bc_f->bc_model();
  std::vector<std::vector<double> >& bc_value_f = bc_f->bc_value_vector(order);

  for (int f = 0; f < nfaces_wghost; f++) {
    const Point& xf = mesh->face_centroid(f);

    if (fabs(xf[0]) < 1e-6 || fabs(xf[0] - 1.0) < 1e-6 ||
        fabs(xf[1]) < 1e-6 || fabs(xf[1] - 1.0) < 1e-6) {
      mesh->face_get_nodes(f, &nodes);

      mesh->node_get_coordinates(nodes[0], &x0);
      mesh->node_get_coordinates(nodes[1], &x1);

      bc_model_f[f] = OPERATOR_BC_DIRICHLET;
      double s0(0.0), s1(0.0), s2(0.0);
      int m(3);
      for (int n = 0; n <= m; ++n) {
        double gp = q1d_points[m - 1][n];
        double gw = q1d_weights[m - 1][n];
        xv = x0 * gp + x1 * (1.0 - gp);
        s0 += gw * ana.pressure_exact(xv, 0.0);
        s1 += gw * ana.pressure_exact(xv, 0.0) * (0.5 - gp);
        s2 += gw * ana.pressure_exact(xv, 0.0) * (0.5 - gp) * (0.5 - gp);
      }
      bc_value_f[f][0] = s0;
      if (order > 1) bc_value_f[f][1] = s1;
      if (order > 2) bc_value_f[f][2] = s2;
    }
  }

  // create diffusion operator 
  Teuchos::RCP<PDE_Abstract> op = Teuchos::rcp(new PDE_Abstract(op_list, mesh));
  op->AddBCs(bc_f, bc_f);
  
  // populate the diffusion operator
  Teuchos::RCP<Operator> global_op = op->global_operator();
  global_op->Init();
  op->UpdateMatrices(Teuchos::null, Teuchos::null);
  op->ApplyBCs(true, true);

  global_op->SymbolicAssembleMatrix();
  global_op->AssembleMatrix();

  // create preconditioner using the base operator class
  ParameterList slist;
  slist.set<std::string>("preconditioner type", "diagonal");
  global_op->InitializePreconditioner(slist);
  global_op->UpdatePreconditioner();

  // solve the problem
  ParameterList lop_list = plist.sublist("solvers")
                                .sublist("AztecOO CG").sublist("pcg parameters");
  AmanziSolvers::LinearOperatorPCG<Operator, CompositeVector, CompositeVectorSpace>
      solver(global_op, global_op);
  solver.Init(lop_list);

  CompositeVector rhs = *global_op->rhs();
  CompositeVector solution(rhs);
  solution.PutScalar(0.0);

  int ierr = solver.ApplyInverse(rhs, solution);

  if (MyPID == 0) {
    std::cout << "pressure solver (pcg): ||r||=" << solver.residual() 
              << " itr=" << solver.num_itrs()
              << " code=" << solver.returned_code() << std::endl;
  }

  // compute pressure error
  solution.ScatterMasterToGhosted();
  Epetra_MultiVector& pf = *solution.ViewComponent("face", false);

  double pnorm, pl2_err, pinf_err;
  ana.ComputeEdgeMomentsError(pf, 0.0, 3, pnorm, pl2_err, pinf_err);

  if (MyPID == 0) {
    printf("L2(p)=%12.9f  Inf(p)=%12.9f  itr=%3d\n", pl2_err, pinf_err, solver.num_itrs());

    CHECK(pl2_err < 1e-10 && pinf_err < 1e-2);
  }
}


/* *****************************************************************
* Exactness test for high-order Lagrange elements.
* **************************************************************** */
void RunHighOrderLagrange(std::string vem_name, bool polygonal_mesh) {
  using namespace Teuchos;
  using namespace Amanzi;
  using namespace Amanzi::AmanziMesh;
  using namespace Amanzi::AmanziGeometry;
  using namespace Amanzi::Operators;
  using namespace Amanzi::WhetStone;

  Epetra_MpiComm comm(MPI_COMM_WORLD);
  int MyPID = comm.MyPID();
  if (MyPID == 0) std::cout << "\nTest: 2D elliptic solver, high-order " << vem_name << std::endl;

  // read parameter list
  std::string xmlFileName = "test/operator_diffusion.xml";
  ParameterXMLFileReader xmlreader(xmlFileName);
  ParameterList plist = xmlreader.getParameters();

  // create a mesh framework
  ParameterList region_list = plist.sublist("regions");
  Teuchos::RCP<GeometricModel> gm = Teuchos::rcp(new GeometricModel(2, region_list, &comm));

  MeshFactory meshfactory(&comm);
  meshfactory.preference(FrameworkPreference({MSTK, STKMESH}));
  RCP<const Mesh> mesh;
  if (polygonal_mesh) {
    mesh = meshfactory("test/median7x8_filtered.exo", gm, true, true);
  } else {
    mesh = meshfactory(0.0, 0.0, 1.0, 1.0, 4, 4, gm, true, true);
  }

  int nfaces_wghost = mesh->num_entities(AmanziMesh::FACE, AmanziMesh::Parallel_type::ALL);
  int nnodes_wghost = mesh->num_entities(AmanziMesh::NODE, AmanziMesh::Parallel_type::ALL);

  // create boundary data (no mixed bc)
  ParameterList op_list = plist.sublist("PK operator")
                               .sublist("diffusion operator " + vem_name);
  int order = op_list.get<int>("method order");

  Analytic00 ana(mesh, 1.0, 2.0, order);

  Point xv(2), x0(2), x1(2);
  AmanziMesh::Entity_ID_List nodes;

  Teuchos::RCP<BCs> bc_v = Teuchos::rcp(new BCs(mesh, AmanziMesh::NODE, DOF_Type::SCALAR));
  std::vector<int>& bc_model_v = bc_v->bc_model();
  std::vector<double>& bc_value_v = bc_v->bc_value();

  for (int v = 0; v < nnodes_wghost; v++) {
    mesh->node_get_coordinates(v, &xv);
    if (fabs(xv[0]) < 1e-6 || fabs(xv[0] - 1.0) < 1e-6 ||
        fabs(xv[1]) < 1e-6 || fabs(xv[1] - 1.0) < 1e-6) {
      bc_model_v[v] = OPERATOR_BC_DIRICHLET;
      bc_value_v[v] = ana.pressure_exact(xv, 0.0);
    }
  }

  Teuchos::RCP<BCs> bc_f = Teuchos::rcp(new BCs(mesh, AmanziMesh::FACE, DOF_Type::VECTOR));
  std::vector<int>& bc_model_f = bc_f->bc_model();
  std::vector<std::vector<double> >& bc_value_f = bc_f->bc_value_vector(order - 1);

  for (int f = 0; f < nfaces_wghost; f++) {
    const Point& xf = mesh->face_centroid(f);

    if (fabs(xf[0]) < 1e-6 || fabs(xf[0] - 1.0) < 1e-6 ||
        fabs(xf[1]) < 1e-6 || fabs(xf[1] - 1.0) < 1e-6) {
      mesh->face_get_nodes(f, &nodes);

      mesh->node_get_coordinates(nodes[0], &x0);
      mesh->node_get_coordinates(nodes[1], &x1);

      bc_model_f[f] = OPERATOR_BC_DIRICHLET;
      double s0(0.0), s1(0.0);
      for (int n = 0; n < 3; ++n) {
        xv = x0 * q1d_points[2][n] + x1 * (1.0 - q1d_points[2][n]);
        s0 += q1d_weights[2][n] * ana.pressure_exact(xv, 0.0);
        s1 += q1d_weights[2][n] * ana.pressure_exact(xv, 0.0) * (0.5 - q1d_points[2][n]);
      }
      bc_value_f[f][0] = s0;
      if (order > 2) bc_value_f[f][1] = s1;
    }
  }

  // create diffusion operator 
  Teuchos::RCP<PDE_Abstract> op = Teuchos::rcp(new PDE_Abstract(op_list, mesh));
  op->AddBCs(bc_v, bc_v);
  op->AddBCs(bc_f, bc_f);
  
  // populate the diffusion operator
  Teuchos::RCP<Operator> global_op = op->global_operator();
  global_op->Init();
  op->UpdateMatrices(Teuchos::null, Teuchos::null);
  op->ApplyBCs(true, true);

  global_op->SymbolicAssembleMatrix();
  global_op->AssembleMatrix();

  // create preconditioner using the base operator class
  ParameterList slist;
  slist.set<std::string>("preconditioner type", "diagonal");
  global_op->InitializePreconditioner(slist);
  global_op->UpdatePreconditioner();

  // solve the problem
  ParameterList lop_list = plist.sublist("solvers")
                                .sublist("AztecOO CG").sublist("pcg parameters");
  AmanziSolvers::LinearOperatorPCG<Operator, CompositeVector, CompositeVectorSpace>
      solver(global_op, global_op);
  solver.Init(lop_list);

  CompositeVector rhs = *global_op->rhs();
  CompositeVector solution(rhs);
  solution.PutScalar(0.0);

  int ierr = solver.ApplyInverse(rhs, solution);

  if (MyPID == 0) {
    std::cout << "pressure solver (pcg): ||r||=" << solver.residual() 
              << " itr=" << solver.num_itrs()
              << " code=" << solver.returned_code() << std::endl;
  }

  // compute pressure error
  solution.ScatterMasterToGhosted();
  Epetra_MultiVector& pn = *solution.ViewComponent("node", false);
  Epetra_MultiVector& pf = *solution.ViewComponent("face", false);

  double pnorm, l2n_err, infn_err, hnorm, h1n_err;
  ana.ComputeNodeError(pn, 0.0, pnorm, l2n_err, infn_err, hnorm, h1n_err);

  double tmp, l2f_err, inff_err;
  ana.ComputeEdgeMomentsError(pf, 0.0, 3, tmp, l2f_err, inff_err);

  double l2c_err, infc_err;
  bool flag(false);
  if (solution.HasComponent("cell")) {
    flag = true;
    Epetra_MultiVector& pc = *solution.ViewComponent("cell", false);
    ana.ComputeCellError(pc, 0.0, tmp, l2c_err, infc_err);
  }

  if (MyPID == 0) {
    printf("Node: L2(p)=%12.9f  H1(p)=%12.9f  itr=%3d\n", l2n_err, h1n_err, solver.num_itrs());
    printf("Edge: L2(p)=%12.9f  Inf(p)=%12.9f \n", l2f_err, inff_err);
    if (flag) printf("Cell: L2(p)=%12.9f  Inf(p)=%12.9f \n", l2c_err, infc_err);

    CHECK(l2n_err < 1e-10 && h1n_err < 2e-1);
    CHECK(l2f_err < 1e-10 && inff_err < 1e-10);
  }
}

TEST(OPERATOR_DIFFUSION_HIGH_ORDER_LAGRANGE) {
  RunHighOrderLagrange("Lagrange", false);
  RunHighOrderLagrange("Lagrange serendipity", true);
}

