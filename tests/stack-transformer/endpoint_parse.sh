set -o errexit
set -o pipefail
. set_environment.sh
set -o nounset

# sanity check
[ ! -f tests/stack-transformer/endpoint_parse.sh ] && \
    echo "Please call this as bash tests/stack-transformer/endpoint_parse.sh" && \
    exit 1

# set data to be used
# DATA=/dccstor/ykt-parse/SHARED/MODELS/AMR/transition-amr-parser/
DATA=DATA/AMR/
ORACLE_TAG=o5+Word100
PREPRO_TAG="RoBERTa-large-top24"
TRAIN_TAG=stnp6x6
# reference file
AMR_DEV_FILE=/dccstor/ykt-parse/SHARED/CORPORA/AMR/LDC2016T10_preprocessed_tahira/dev.txt.removedWiki.noempty.JAMRaligned

input_file=${DATA}/oracles/$ORACLE_TAG/dev.en

# Set model to be used
# features_folder=${DATA}/features/qaldlarge_extracted/
# checkpoints_dir=${DATA}/models/stack_transformer_6x6_nopos-qaldlarge_prepro_o3+Word100-stnp6x6-seed42/
features_folder=${DATA}/features/${ORACLE_TAG}_${PREPRO_TAG}
checkpoints_dir=${DATA}/models/${ORACLE_TAG}_${PREPRO_TAG}_${TRAIN_TAG}-seed42/

# folder where we write data
rm -f DATA.tests/endpoint.amr DATA.tests/endpoint.smatch
mkdir -p DATA.tests/

# TODO: Remove extra arguments, read only folder checkpoint and deduce aregs
# from it
# run decoding
# kernprof -l transition_amr_parser/parse.py \
amr-parse \
    --in-tokenized-sentences $input_file \
    --in-checkpoint $checkpoints_dir/checkpoint_top3-average_SMATCH.pt \
    --roberta-batch-size 10 \
    --batch-size 128 \
    --out-amr DATA.tests/endpoint.amr

# python -m line_profiler parse.py.lprof
 
# FIXME: removed for debugging
#    --roberta-cache-path ./cache/roberta.large \

smatch.py \
     --significant 4  \
     -f $AMR_DEV_FILE \
     DATA.tests/endpoint.amr \
     -r 10 \
     > DATA.tests/endpoint.smatch

cat DATA.tests/endpoint.smatch
