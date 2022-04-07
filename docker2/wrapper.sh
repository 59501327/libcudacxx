#! /bin/bash

function usage {
  echo "Usage: ${0} [flags...] path/to/libcudacxx"
  echo
  echo "Configure a docker container for libcudacxx that is ready to run tests"
  echo
  echo "-h, -help, --help       : Print this message."
  echo "--verbose               : Enable verbose output"
  echo "--enable-nvcxx          : Configure for NVC++"
  echo "--cuda-tools-dir <file> : Tools for building CUDA applications, e.g. nvcc/nvc++"

  exit -3
}

function section_separator {
  for i in {0..79}
  do
    echo -n "#"
  done
  echo
}

function abspath {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

SCRIPT_PATH=$(cd $(dirname ${0}); pwd -P)

pushd SCRIPT_PATH

# Default to GCC
HOST_CXX=gcc

while test ${#} != 0
do
  case "${1}" in
  -h) usage ;;
  -help) usage ;;
  --help) usage ;;
  --enable-nvcxx)   NVCXX_ENABLED=1 ;;
  --cuda-tools-dir) shift; CUDA_DIR=$(abspath ${1}) ;;
  --cudacxx-bin)    shift; CUDACXX_PATH="--build-arg CUDACXX_PATH=${1}" ;;
  --host-cxx)       shift; HOST_CXX=${1} ;;
  --verbose)        VERBOSE=1 ;;
  *)                LIBCUDACXX_DIR=$(abspath ${1}) ;;
  esac
  shift
done

HOST_CXX_ARG="--build-arg HOST_CXX=$HOST_CXX"

################################################################################
# Dump Variables

VARIABLES="
  PATH
  PWD
  LIBCUDACXX_DIR
  VERBOSE
  CUDA_DIR
  CUDACXX_PATH
  HOST_CXX
  HOST_CXX_ARG
  NVCXX_ENABLED
"

section_separator

for VARIABLE in ${VARIABLES}
do
  printf "# VARIABLE %s%q\n" "${VARIABLE}=" "${!VARIABLE}"
done


################################################################################
# Begin building container

section_separator

tempdir=$(mktemp -d)

docker build -f base.Dockerfile    -t cccl/base   ${CUDA_DIR}
docker build -f config.Dockerfile  -t cccl/config-${HOST_CXX} ${CUDACXX_PATH} ${HOST_CXX_ARG} ${LIBCUDACXX_DIR}
