#!/bin/bash

# must run this script: using: bash run.sh
# download dataset and evaluate scripts
if [ 1 -eq 0 ]; then 
    mkdir -p tools
    cd tools/
    wget https://raw.githubusercontent.com/moses-smt/mosesdecoder/master/scripts/tokenizer/tokenizer.perl
    wget https://raw.githubusercontent.com/moses-smt/mosesdecoder/master/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.de
    wget https://raw.githubusercontent.com/moses-smt/mosesdecoder/master/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.en
    sed -i "s/$RealBin\/..\/share\/nonbreaking_prefixes//" tokenizer.perl
    wget https://raw.githubusercontent.com/moses-smt/mosesdecoder/master/scripts/generic/multi-bleu.perl
    cd ../

    # download datasets 
    echo 'downloading dataset'
    mkdir -p datasets/multi30k
    wget http://www.quest.dcs.shef.ac.uk/wmt16_files_mmt/training.tar.gz &&  tar -xf training.tar.gz -C datasets/multi30k && rm training.tar.gz
    wget http://www.quest.dcs.shef.ac.uk/wmt16_files_mmt/validation.tar.gz && tar -xf validation.tar.gz -C datasets/multi30k && rm validation.tar.gz
    wget https://staff.fnwi.uva.nl/d.elliott/wmt16/mmt16_task1_test.tgz && tar -xf mmt16_task1_test.tgz -C datasets/multi30k && rm mmt16_task1_test.tgz
fi 

# preprocess data 
if [ 1 -eq 0 ]; then 
    for l in en de; do 
        for f in datasets/multi30k/*.$l; do 
            echo $f;
            if [ "$f" != *"test"* ]; then 
                sed -i "$ d" $f; 
            fi;  
        done; 
    done

    for l in en de; do for f in datasets/multi30k/*.$l; do perl ./tools/tokenizer.perl -a -no-escape -l $l -q  < $f > $f.atok; done; done
fi 

if [ 1 -eq 0 ]; then 
    python ./misc/preprocess.py -train_src datasets/multi30k/train.en.atok -train_tgt datasets/multi30k/train.de.atok \
    -valid_src datasets/multi30k/val.en.atok \
    -valid_tgt datasets/multi30k/val.de.atok -save_data datasets/multi30k.atok.low -lower
fi 


# train network 
if [ 1 -eq 1 ]; then 
    python main.py --data datasets/multi30k.atok.low.train.pt --checkpoint_folder ./checkpoint_folder --ngpu '1' --cuda
fi

# test network 
if [ 1 -eq 0 ]; then 
python translate.py -gpu 0 -model ./checkpoint_folder/model_acc_69.81_ppl_5.89_e11.pt -src datasets/multi30k/test.en.atok -tgt datasets/multi30k/test.de.atok -replace_unk -verbose -output multi30k.test.pred.atok
fi 

# evaluate model 
if [ 1 -eq 0 ]; then 
    perl ./tools/multi-bleu.perl ./datasets/multi30k/test.de.atok < ./multi30k.test.pred.atok
fi 
