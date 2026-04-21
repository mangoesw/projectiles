let
  # https://status.nixos.org.
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/4c1018dae018162ec878d42fec712642d214fdfa.tar.gz") {};
  julia = pkgs.julia-bin.withPackages [
    "SimpleNonlinearSolve"
    # "DifferentialEquations"
    "OrdinaryDiffEq"
    "MLJ"
    "DynamicQuantities"
    "SymbolicRegression"
    # "StaticArrays"
    "Plots"
    "ModelingToolkit"
  ];
in pkgs.mkShell {
  buildInputs = [ julia ];
}
