/*
  This is the flow component of the Amanzi code. 

  Copyright 2010-201x held jointly by LANS/LANL, LBNL, and PNNL. 
  Amanzi is released under the three-clause BSD License. 
  The terms of use and "as is" disclaimer for this license are 
  provided in the top-level COPYRIGHT file.

  Author: Konstantin Lipnikov (lipnikov@lanl.gov)
*/

#include <vector>

#include "Teuchos_RCP.hpp"

#include "errors.hh"
#include "Mesh.hh"
#include "TabularFunction.hh"

#include "Flow_PK.hh"

namespace Amanzi {
namespace Flow {

/* ******************************************************************
* Routine processes parameter list. It needs to be called only once
* on each processor.                                                     
****************************************************************** */
void Flow_PK::ProcessParameterList(Teuchos::ParameterList& plist)
{
  double rho = *(S_->GetScalarData("fluid_density"));

  // Process main one-line options (not sublists)
  atm_pressure_ = plist.get<double>("atmospheric pressure", FLOW_PRESSURE_ATMOSPHERIC);
 
  // Create the BC objects.
  Teuchos::RCP<Teuchos::ParameterList>
      bc_list = Teuchos::rcp(new Teuchos::ParameterList(plist.sublist("boundary conditions", true)));
  FlowBCFactory bc_factory(mesh_, bc_list);

  bc_pressure = bc_factory.CreatePressure(bc_submodel);
  bc_head = bc_factory.CreateStaticHead(atm_pressure_, rho, gravity_, bc_submodel);
  bc_flux = bc_factory.CreateMassFlux(bc_submodel);
  bc_seepage = bc_factory.CreateSeepageFace(atm_pressure_, bc_submodel);

  VV_ValidateBCs();
  ProcessBCs();

  // Create the source object if any
  if (plist.isSublist("source terms")) {
    std::string distribution_method_name = plist.get<std::string>("source and sink distribution method", "none");
    ProcessStringSourceDistribution(distribution_method_name, &src_sink_distribution); 

    Teuchos::RCP<Teuchos::ParameterList> src_list = Teuchos::rcpFromRef(plist.sublist("source terms", true));
    FlowSourceFactory src_factory(mesh_, src_list);
    src_sink = src_factory.createSource();
    src_sink_distribution = src_sink->CollectActionsList();
  }

  // Time integrator for period I, temporary called initial guess initialization
  if (plist.isSublist("initial guess pseudo time integrator")) {
    Teuchos::ParameterList& igs_list = plist.sublist("initial guess pseudo time integrator");

    std::string ti_method_name = igs_list.get<std::string>("time integration method", "none");
    ProcessStringTimeIntegration(ti_method_name, &ti_specs_igs_.ti_method);
    ProcessSublistTimeIntegration(igs_list, ti_method_name, ti_specs_igs_);
    ti_specs_igs_.ti_method_name = "initial guess pseudo time integrator";

    ti_specs_igs_.preconditioner_name = FindStringPreconditioner(igs_list);
    ti_specs_igs_.solver_name = FindStringLinearSolver(igs_list);

    ProcessStringErrorOptions(igs_list, &ti_specs_igs_.error_control_options);
  }

  // Time integrator for period II, temporary called steady-state time integrator
  if (plist.isSublist("steady state time integrator")) {
    Teuchos::ParameterList& sss_list = plist.sublist("steady state time integrator");

    std::string ti_method_name = sss_list.get<std::string>("time integration method", "none");
    ProcessStringTimeIntegration(ti_method_name, &ti_specs_sss_.ti_method);
    ProcessSublistTimeIntegration(sss_list, ti_method_name, ti_specs_sss_);
    ti_specs_sss_.ti_method_name = "steady state time integrator";

    ti_specs_sss_.preconditioner_name = FindStringPreconditioner(sss_list);
    ti_specs_sss_.solver_name = FindStringLinearSolver(sss_list);

    ProcessStringErrorOptions(sss_list, &ti_specs_sss_.error_control_options);

  } else if (vo_->getVerbLevel() >= Teuchos::VERB_LOW) {
    Teuchos::OSTab tab = vo_->getOSTab();
    *vo_->os() << vo_->color("yellow") << "steady-state calculation was not requested." 
               << vo_->reset() << std::endl;
  }

  // Time integrator for period III, called transient time integrator
  if (plist.isSublist("transient time integrator")) {
    Teuchos::ParameterList& trs_list = plist.sublist("transient time integrator");

    std::string ti_method_name = trs_list.get<std::string>("time integration method", "none");
    ProcessStringTimeIntegration(ti_method_name, &ti_specs_trs_.ti_method);
    ProcessSublistTimeIntegration(trs_list, ti_method_name, ti_specs_trs_);
    ti_specs_trs_.ti_method_name = "transient time integrator";

    ti_specs_trs_.preconditioner_name = FindStringPreconditioner(trs_list);
    ti_specs_trs_.solver_name = FindStringLinearSolver(trs_list);

    ProcessStringErrorOptions(trs_list, &ti_specs_trs_.error_control_options);

  } else if (vo_->getVerbLevel() >= Teuchos::VERB_LOW) {
    Teuchos::OSTab tab = vo_->getOSTab();
    *vo_->os() << vo_->color("yellow") << "no sublist '\"transient time integrator'\"" 
               << vo_->reset() << std::endl;
  }
}


/* ******************************************************************
* Process time integration sublist.
**************************************************************** */
void Flow_PK::ProcessSublistTimeIntegration(
    Teuchos::ParameterList& list, const std::string name, TI_Specs& ti_specs)
{
  Errors::Message msg;

  if (list.isSublist(name)) {
    Teuchos::ParameterList bdf1_list = list.sublist(name);

    // new way to define parameters overrides the above values.
    if (bdf1_list.isParameter("timestep controller type")) {
      std::string dT_method_name = bdf1_list.get<std::string>("timestep controller type");

      ti_specs.dT_method = 0;
      Teuchos::ParameterList dtlist;
      if (dT_method_name == "standard") {
        dtlist = bdf1_list.sublist("timestep controller standard parameters");
        ti_specs.dTfactor = dtlist.get<double>("time step increase factor");
      } else if (dT_method_name == "fixed") {
        dtlist = bdf1_list.sublist("timestep controller fixed parameters");
        ti_specs.dTfactor = dtlist.get<double>("time step increase factor");
      } else if (dT_method_name == "adaptive") {
        dtlist = bdf1_list.sublist("timestep controller adaptive parameters");
        ti_specs.dT_method = FLOW_DT_ADAPTIVE;
      }
      ti_specs.dTmax = dtlist.get<double>("max time step", Flow::FLOW_MAXIMUM_DT);
    }

    if (list.isSublist("initialization")) {
      Teuchos::ParameterList& ini_list = list.sublist("initialization");
      std::string name = ini_list.get<std::string>("method", "none");
      ti_specs.initialize_with_darcy = (name == "saturated solver");
      ti_specs.clip_saturation = ini_list.get<double>("clipping saturation value", -1.0);
      ti_specs.clip_pressure = ini_list.get<double>("clipping pressure value", -1e+10);

      ti_specs.solver_name_ini = FindStringLinearSolver(ini_list);
    }

    if (list.isSublist("pressure-lambda constraints")) {
      Teuchos::ParameterList& pl_list = list.sublist("pressure-lambda constraints");
      ti_specs.pressure_lambda_constraints = true;
      ti_specs.inflow_krel_correction = pl_list.get<bool>("inflow krel correction", "false");

      ti_specs.solver_name_constraint = FindStringLinearSolver(pl_list);
    }

  } else if (name != "none") {
    msg << "\nFlow PK: specified time integration sublist does not exist.";
    Exceptions::amanzi_throw(msg);
  }
}


/* ****************************************************************
* Process string for the time integration method.
**************************************************************** */
void Flow_PK::ProcessStringTimeIntegration(const std::string name, int* method)
{
  Errors::Message msg;

  if (name == "Picard") {
    *method = Flow::FLOW_TIME_INTEGRATION_PICARD;
  } else if (name == "backward Euler") {
    *method = Flow::FLOW_TIME_INTEGRATION_BACKWARD_EULER;
  } else if (name == "BDF1") {
    *method = Flow::FLOW_TIME_INTEGRATION_BDF1;
  } else if (name == "BDF2") {
    *method = Flow::FLOW_TIME_INTEGRATION_BDF2;
  } else {
    msg << "Flow PK: time integration method \"" << name.c_str() << "\" is not known.";
    Exceptions::amanzi_throw(msg);
  }
}


/* ****************************************************************
* Process string for the linear solver.
**************************************************************** */
void Flow_PK::ProcessStringSourceDistribution(const std::string name, int* method)
{
  if (name != "none") {
    Errors::Message msg;
    msg << "\nFlow_PK: \"source and sink distribution method\" is obsolete.\n"
        << "         see desription of sublist \"source terms\" in the native spec.\n";
    Exceptions::amanzi_throw(msg);
  }
}


/* ****************************************************************
* Find string for the preconditoner.
**************************************************************** */
std::string Flow_PK::FindStringPreconditioner(const Teuchos::ParameterList& list)
{   
  Errors::Message msg;
  std::string name; 

  if (list.isParameter("preconditioner")) {
    name = list.get<std::string>("preconditioner");
  } else {
    msg << "Flow PK: parameter <preconditioner> is missing either in TI or LS list.";
    Exceptions::amanzi_throw(msg);
  }

  if (! preconditioner_list_.isSublist(name)) {
    msg << "Flow PK: preconditioner \"" << name.c_str() << "\" does not exist.";
    Exceptions::amanzi_throw(msg);
  }
  return name;
}


/* ****************************************************************
* Find string for the preconditoner.
**************************************************************** */
std::string Flow_PK::FindStringLinearSolver(const Teuchos::ParameterList& list)
{   
  Errors::Message msg;
  std::string name; 

  if (list.isParameter("linear solver")) {
    name = list.get<std::string>("linear solver");
  } else {
    msg << "Flow PK: time integrator does not define <linear solver>.";
    Exceptions::amanzi_throw(msg);
  }

  if (! linear_operator_list_.isSublist(name)) {
    msg << "Flow PK: linear solver \"" << name.c_str() << "\" does not exist.";
    Exceptions::amanzi_throw(msg);
  }
  return name;
}


/* ****************************************************************
* Process string for error control options
**************************************************************** */
void Flow_PK::ProcessStringErrorOptions(Teuchos::ParameterList& list, int* control)
{
  *control = 0;
  if (list.isParameter("error control options")){
    std::vector<std::string> options;
    options = list.get<Teuchos::Array<std::string> >("error control options").toVector();

    for (int i=0; i < options.size(); i++) {
      if (options[i] == "pressure") {
        *control += FLOW_TI_ERROR_CONTROL_PRESSURE;
      } else if (options[i] == "saturation") {
        *control += FLOW_TI_ERROR_CONTROL_SATURATION;
      } else if (options[i] == "residual") {
        *control += FLOW_TI_ERROR_CONTROL_RESIDUAL;
      } else {
        Errors::Message msg;
        msg << "Flow PK: unknown error control option has been specified.";
        Exceptions::amanzi_throw(msg);
      }
    }
  }
}


/* ****************************************************************
* Find string for the preconditoner.
**************************************************************** */
void Flow_PK::OutputTimeHistory(
    const Teuchos::ParameterList& plist, std::vector<dt_tuple>& dT_history)
{
  if (plist.isParameter("plot time history") && 
      vo_->getVerbLevel() >= Teuchos::VERB_MEDIUM) {
    Teuchos::OSTab tab = vo_->getOSTab();
    *vo_->os() << "saving time history in file flow_dt_history.txt..." << std::endl;

    char file_name[30];
    sprintf(file_name, "flow_dt_history_%d.txt", ti_phase_counter++);

    std::ofstream ofile;
    ofile.open(file_name);

    for (double n = 0; n < dT_history.size(); n++) {
      ofile << std::setprecision(10) << dT_history[n].first / FLOW_YEAR << " " << dT_history[n].second << std::endl;
    }
    ofile.close();
  }
}


}  // namespace Flow
}  // namespace Amanzi
