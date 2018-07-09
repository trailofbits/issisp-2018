#!/bin/bash

#need to:
# pip install enum34
# pip install pyelftools
MCSEMA_SRC=/data/ubuntu1404/issisp/remill
LLVM_VER=6.0
CXX=clang++-${LLVM_VER}
CC=clang-${LLVM_VER}
LIFTER=/usr/local/bin/mcsema-lift-${LLVM_VER}
ABI_DIR=/tmp/
BIN_FILE=$1


#if [ -z ${BIN_FILE} ]; then
#  BIN_FILE=example
#  ${CC} -m64 -g -Wall -O0 -o ${BIN_FILE} authenticate.c -fno-stack-protector
#fi

MCSEMA_DIR=/usr/local
IN_DIR=$(pwd)
IN_FILE=${BIN_FILE}
OUT_DIR=$(pwd)
IDA_DIR=/opt/ida-6.7

function clean_check
{
  echo "Cleaning old output..."
  local in_file=${1}
  rm -rf ${OUT_DIR}/${in_file}.cfg ${OUT_DIR}/${in_file}.bc ${OUT_DIR}/${in_file}_out.txt ${OUT_DIR}/${in_file}_lifted* dwarf_debug.log global.protobuf
}

function recover_globals
{
	echo "Recovering Globals..."
	local in_file=${1}
	${MCSEMA_SRC}/tools/mcsema/tools/mcsema_disass/ida/var_recovery.py --binary \
	  ${IN_DIR}/${in_file} \
		--out ${OUT_DIR}/global.protobuf \
		--log_file dwarf_debug.log
}

function recover_cfg_ida
{
	echo "Recovering CFG and Stack Variables..."
	local in_file=${1}
	${MCSEMA_DIR}/bin/mcsema-disass --disassembler ${IDA_DIR}/idal64 \
		--entrypoint main \
		--arch amd64 \
		--os linux \
		--binary ${IN_DIR}/${in_file} \
		--output ${OUT_DIR}/${in_file}.cfg \
		--log_file ${OUT_DIR}/${in_file}_out.txt \
		--recover-stack-vars \
		--recover-global-vars \
		${OUT_DIR}/global.protobuf #\
		#--recover-exception
}

function recover_cfg_binja
{
	echo "Recovering CFG and Stack Variables..."
	local in_file=${1}
	${MCSEMA_DIR}/bin/mcsema-disass --disassembler binaryninja \
		--entrypoint main \
		--arch amd64 \
		--os linux \
		--binary ${IN_DIR}/${in_file} \
		--output ${OUT_DIR}/${in_file}.cfg \
		--log_file ${OUT_DIR}/${in_file}_out.txt \
		--recover-stack-vars 
}

function lift_binary
{
	echo "Lifting binary..."
	local in_file=${1}
	${LIFTER} --arch amd64 \
		--os linux \
		--cfg ${OUT_DIR}/${in_file}.cfg \
		--output ${OUT_DIR}/${in_file}.bc \
		--libc_constructor __libc_csu_init \
		--libc_destructor __libc_csu_fini
}

function new_binary
{
	echo "Generating lifted binary..."
	local in_file=${1}
	${CC}  -m64 -g -O0 -o ${OUT_DIR}/${in_file}-lifted \
		${OUT_DIR}/${in_file}.bc \
		-lmcsema_rt64-${LLVM_VER} \
		-L${MCSEMA_DIR}/lib
}

function new_binary_asan
{
        echo "Generating lifted binary..."
        local in_file=${1}
        ${CC} -fsanitize=address -m64 -g -O0 -o ${OUT_DIR}/${in_file}-lifted_asan \
                ${OUT_DIR}/${in_file}.bc \
                -lmcsema_rt64-${LLVM_VER} \
                -L${MCSEMA_DIR}/lib
}



clean_check ${IN_FILE}

recover_globals ${IN_FILE}

recover_cfg_binja ${IN_FILE}

lift_binary ${IN_FILE}

new_binary ${IN_FILE}

new_binary_asan ${IN_FILE}

