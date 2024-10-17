import argparse
import os
import shutil

import pandas as pd

AFLPP = "AFLPP"
FOX = "FOX"
FOXNG = "FOXNG"
FOX_D = "FOX+D"
FOXNG_D = "FOXNG+D"
HASTEFUZZ = "HasteFuzz"
HASTEFUZZ_C = "HasteFuzz+C"
HASTEFUZZ_CD = "HasteFuzz+CD"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--old_inp", type=str, help="Old processed data directory", default="results/01_22_2024")
    parser.add_argument("--new_inp", type=str, help="New processed data directory", default="results/04_30_2024")
    parser.add_argument("--out", type=str, help="Output file path", default="results/merged")
    return parser.parse_args()


def main(args: argparse.Namespace):
    # copy all the new data that does not require splicing:
    if os.path.exists(args.out):
        shutil.rmtree(args.out)
    shutil.copytree(args.old_inp, args.out)
    shutil.copytree(args.new_inp, args.out, dirs_exist_ok=True)



    dataset = "cov.csv"
    df_old = pd.read_csv(os.path.join(args.old_inp, dataset), index_col=0)
    df_new = pd.read_csv(os.path.join(args.new_inp, dataset), index_col=0)

    # ignore gllvm FOX and HasteFuzz
    df_old = df_old[~df_old.fuzzer.isin({FOX, FOX_D, HASTEFUZZ, HASTEFUZZ_C, HASTEFUZZ_CD})]
    # remove old AFLPP runs that have been rerun
    df_old = df_old[~df_old.project.isin(set(df_new[df_new.fuzzer == AFLPP].project.unique()))]

    # relabel FOXNG and FOXNG+D as FOX and FOX+D
    df_new.loc[df_new.fuzzer == FOXNG, 'fuzzer'] = FOX
    df_new.loc[df_new.fuzzer == FOXNG_D, 'fuzzer'] = FOX_D

    df = pd.concat([df_old, df_new])

    df.to_csv(os.path.join(args.out, dataset))

if __name__ == "__main__":
    main(parse_args())
