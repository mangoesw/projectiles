let
  # https://status.nixos.org.
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/6201e203d09599479a3b3450ed24fa81537ebc4e.tar.gz") {};
  julia = pkgs.julia-bin.withPackages [
    "SimpleNonlinearSolve"
    "DifferentialEquations"
    "MLJ"
    "DynamicQuantities"
    "SymbolicRegression"
    "StaticArrays"
    "Plots"
  ];
in pkgs.mkShell {
  buildInputs = [ julia ];
}
