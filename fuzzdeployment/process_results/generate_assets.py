import argparse
import os

import matplotlib
import pandas as pd
import seaborn as sns
import statsmodels.formula.api as smf
from matplotlib import pyplot as plt
from scipy.stats import mannwhitneyu
from tabulate import tabulate

height = 4
aspect = 1.5
sns.set_theme(rc={'figure.figsize':(height*aspect, height)})
sns.set_style("whitegrid", {'axes.grid' : False})
matplotlib.rc('pdf', fonttype=42)

NUM_TRIALS = 10
TRIAL_LEN_HRS = 24

fuzzer_name_map = {
    "aflpp": "AFLPP",
    "cmplog": "AFLPP+C",
    "cmplog_dict": "AFLPP+CD",
    "optfuzz": "FOX",
    "optfuzz_dict": "FOX+D",
    "optfuzz_nogllvm": "FOXNG",
    "optfuzz_nogllvm_dict": "FOXNG+D",
    "optfuzz_dict_nogllvm": "FOXNG+D",
    "hastefuzz": "HasteFuzz",
    "hastefuzz_baseline": "HasteFuzz",
    "hastefuzz_cmplog": "HasteFuzz+C",
    "hastefuzz_cmplog_dict": "HasteFuzz+CD",
}

AFLPP = "AFLPP"
AFLPP_C = "AFLPP+C"
AFLPP_CD = "AFLPP+CD"
FOX = "FOX"
FOXNG = "FOXNG"
FOX_D = "FOX+D"
FOXNG_D = "FOXNG+D"
HASTEFUZZ = "HasteFuzz"
HASTEFUZZ_C = "HasteFuzz+C"
HASTEFUZZ_CD = "HasteFuzz+CD"

BASELINES = [
    AFLPP,
    AFLPP_C,
    AFLPP_CD,
]

fuzzer_col_order = [
    FOX,
    AFLPP,
    AFLPP_C,
    FOX_D,
    AFLPP_CD,

]

FUZZBENCH = "FuzzBench"
STANDALONE = "Standalone"

DATASETS = [
    FUZZBENCH,
    STANDALONE,
]


# Fuzzbench: Results name -> Project name in the paper
fuzzbench_project_name_map = {
    'bloaty'                        : 'bloaty',
    'curl'                          : 'curl',
    'freetype'                      : 'freetype',
    'harfbuzz'                      : 'harfbuzz',
    'jsoncpp'                       : 'jsoncpp',
    'lcms'                          : 'lcms',
    'lcms_cms_transform_fuzzer'     : 'lcms',
    'libjpeg'                       : 'libjpeg-turbo',
    'libpcap'                       : 'libpcap',
    'libpcap_fuzz_both'             : 'libpcap',
    'libpng_read_fuzzer'            : 'libpng',
    'libxml2_xml'                   : 'libxml2',
    'libxslt_xpath'                 : 'libxslt',
    'mbedtls'                       : 'mbedtls',
    'mbedtls_fuzz_dtlsclient'       : 'mbedtls',
    'openh264'                      : 'openh264',
    'openh264_decoder_fuzzer'       : 'openh264',
    'openssl'                       : 'openssl',
    'openthread'                    : 'openthread',
    'openthread_ot-ip6-send-fuzzer' : 'openthread',
    'proj4'                         : 'proj4',
    're2'                           : 're2',
    'sqlite3'                       : 'sqlite3',
    'sqlite3_ossfuzz'               : 'sqlite3',
    'stb_stbi_read_fuzzer'          : 'stb',
    'systemd'                       : 'systemd',
    'vorbis'                        : 'vorbis',
    'vorbis_decode_fuzzer'          : 'vorbis',
    'woff2'                         : 'woff2',
    'zlib'                          : 'zlib',
    'zlib_zlib_uncompress_fuzzer'   : 'zlib'
}

fuzzbench_projects = set(fuzzbench_project_name_map.values())

# Standalone: Results name -> Binary name in the paper
standalone_project_name_map = {
    'libarchive': 'bsdtar',
    'exiv2'     : 'exiv2',
    'ffmpeg'    : 'ffmpeg',
    'jasper'    : 'jasper',
    'nm-new'    : 'nm-new',
    'objdump'   : 'objdump',
    'xpdf'      : 'pdftotext',
    'readelf'   : 'readelf',
    'size'      : 'size',
    'strip-new' : 'strip-new',
    'tcpdump'   : 'tcpdump',
    'tiff2pdf'  : 'tiff2pdf',
    'tiff2ps'   : 'tiff2ps',
    'tiffcrop'  : 'tiffcrop',
    'libxml2'   : 'xmllint'
}

control_standalone_project_name_map = {
    'libarchive': 'bsdtar',
    'exiv2'     : 'exiv2',
    'ffmpeg'    : 'ffmpeg',
    'jasper'    : 'jasper',
    'nm-new'    : 'nm-new',
    'objdump'   : 'objdump',
    'xpdf'      : 'pdftotext',
    'readelf'   : 'readelf',
    'size'      : 'size',
    'strip-new' : 'strip-new',
    'tcpdump'   : 'tcpdump',
    'tiff2pdf'  : 'tiff2pdf',
    'tiff2ps'   : 'tiff2ps',
    'tiffcrop'  : 'tiffcrop',
}

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inp", type=str, default="results/merged", help="The directory containing the input csv files parsed from raw data by parse_results.py.")
    parser.add_argument("--out", type=str, default="paper_assets", help="The directory to save the generated assets like tables and figures.")
    parser.add_argument("--limited", action="store_true", help="Generate assets for the limited run")
    return parser.parse_args()


def main(args: argparse.Namespace):
    if args.limited:
        args.out += "_limited"
    os.makedirs(args.out, exist_ok=True)

    # Figure 2, 4 (appendix); Table 3, 4, 10 (appendix), 11 (appendix): Coverage and Mann-Whitney U test
    df = pd.read_csv(os.path.join(args.inp, 'cov.csv'), index_col=0)
    df = df.sort_values(by=["project", "fuzzer"])
    df["dataset"] = df.project.isin(fuzzbench_projects).map({True: FUZZBENCH, False: STANDALONE})


    # Table 3, 4: Coverage
    for tname, dataset in zip(["Table 3", "Table 4"], DATASETS):
        cov_df = df[(df.dataset == dataset) & (df.hour == df.hour.max())].groupby(["project", "fuzzer"], as_index=False).mean(numeric_only=True)[["project", "fuzzer", "edges_found"]]
        cov_df = cov_df.pivot(index="project", columns="fuzzer", values="edges_found")
        cov_df = cov_df[fuzzer_col_order]
        print(f"{tname}: Coverage for {dataset} projects")
        table = tabulate(cov_df, headers="keys", tablefmt="simple", floatfmt=".0f")
        save_path = os.path.join(args.out, f'{tname}.txt')
        print(f"Saving to {save_path}")
        with open(save_path, 'w') as f:
            f.write(table + "\n")

    if args.limited:
        return

    # Figure 2, 4 (appendix): Coverage
    for fname, dataset in zip(["Figure 2", "Figure 4"], reversed(DATASETS)):
        if dataset == FUZZBENCH:
            continue
        print(f"{fname}: Coverage for {dataset} projects")

        df_plot = df[df.dataset == dataset]
        projects = df_plot.project.unique()

        col_wrap = 5 if dataset == FUZZBENCH else 4

        g = sns.relplot(data=df_plot, x="hour", y="edges_found", hue="fuzzer", style="fuzzer", col="project", kind="line", col_wrap=col_wrap, facet_kws={"sharex": False, "sharey": False}, markers=True, dashes=False, height=3)
        sns.move_legend(g, "upper center", ncol=len(df.fuzzer.unique()), bbox_to_anchor=(0.5, 1.04), frameon=False, fontsize="x-large", title=None)
        for i, ax in enumerate(g.axes.flat):
            ax.set_xticks(range(0, 25, 4))
            ax.set_title(f"({chr(ord('a') + i)}) {projects[i]}", fontweight='bold')
        g.set_xlabels("Time (hours)")
        g.set_ylabels("Edges found")
        plt.tight_layout()
        save_path = os.path.join(args.out, f'{fname}.pdf')
        print(f"Saving to {save_path}")
        plt.savefig(save_path, bbox_inches='tight')


    # Figure 3; Table 7: Control space size
    df = pd.read_csv(os.path.join(args.inp, 'control.csv'), index_col=0)
    df = df.replace({"fuzzer": fuzzer_name_map})
    df = df.replace({"project": control_standalone_project_name_map})
    control_space_size_fuzzers = ["FOX", "AFLPP"]
    df = df[df.fuzzer.isin(control_space_size_fuzzers)]
    df = df.groupby(["project", "fuzzer", "hour"], as_index=False).mean(numeric_only=True)[["project", "fuzzer", "hour", "control_size"]]

    # Figure 3
    fname = "Figure 3"
    print(f"{fname}: Control space size for standalone projects")
    df_plot = df[df.project == "xmllint"]
    ax = sns.lineplot(data=df_plot, x="hour", y="control_size", hue="fuzzer", style="fuzzer", markers=True, dashes=False)
    ax.set_xticks(range(0, 25, 4))
    ax.set_xlabel("Time (hours)")
    ax.set_ylabel("Control space size")
    ax.legend(title=None)
    plt.tight_layout()
    save_path = os.path.join(args.out, f'{fname}.pdf')
    print(f"Saving to {save_path}")
    plt.savefig(save_path, bbox_inches='tight')

    # Table 7
    control_at_12_df = df[(~df.project.isin(fuzzbench_projects)) & (df.hour == 12)].sort_values("project")
    control_at_12_df = control_at_12_df.pivot(index="project", columns="fuzzer", values="control_size")[control_space_size_fuzzers]
    control_at_12_df

    control_space_reduction_at_12 = (1 - control_at_12_df['FOX'] / control_at_12_df['AFLPP']) * 100

    control_at_24_df = df[(~df.project.isin(fuzzbench_projects)) & (df.hour == df.hour.max())].sort_values("project")
    control_at_24_df = control_at_24_df.pivot(index="project", columns="fuzzer", values="control_size")[control_space_size_fuzzers]
    control_at_24_df.sort_index()

    control_space_reduction_at_24 = (1 - control_at_24_df['FOX'] / control_at_24_df['AFLPP']) * 100

    control_table = pd.merge(control_at_12_df.rename(columns=lambda x: f"{x} (12h)"), control_at_24_df.rename(columns=lambda x: f"{x} (24h)"), on="project")
    control_table = control_table[["FOX (12h)", "FOX (24h)", "AFLPP (12h)", "AFLPP (24h)"]]
    tname = "Table 7"
    print(f"{tname}: Control space size for standalone projects")
    table = tabulate(control_table, tablefmt="simple", floatfmt=".0f", headers="keys")
    save_path = os.path.join(args.out, f'{tname}.txt')
    print(f"Saving to {save_path}")
    with open(save_path, 'w') as f:
        f.write(table + "\n")


    # Table 8: Ablation study results
    df = pd.read_csv(os.path.join(args.inp, "ablation.csv"), index_col=0)
    df = df.groupby(["project", "fuzzer"], as_index=False).mean(numeric_only=True)[["project", "fuzzer", "edges_found"]]
    df = df.pivot(index="project", columns="fuzzer", values="edges_found")
    df = df[["FOX", "FOX-BASE", "FOX-SCHED"]]
    tname = "Table 8"
    print(f"{tname}: Ablation study results")
    table = tabulate(df, tablefmt="simple", floatfmt=".0f", headers="keys")
    save_path = os.path.join(args.out, f'{tname}.txt')
    print(f"Saving to {save_path}")
    with open(save_path, 'w') as f:
        f.write(table + "\n")

    # Table 9: Reached and flipped branches
    df = pd.read_csv(os.path.join(args.inp, "reached_flipped.csv"), index_col=0)
    df = df.groupby(["project", "fuzzer"], as_index=False).mean(numeric_only=True)[["project", "fuzzer", "nodes_reached", "nodes_flipped"]]
    df = df.rename(columns={"nodes_reached": "R", "nodes_flipped": "F"})
    df = df.replace({"fuzzer": fuzzer_name_map})
    df = df.pivot(index="project", columns="fuzzer", values=["R", "F"])
    df = df[[(stat, fuzzer) for fuzzer in fuzzer_col_order for stat in ["R", "F"]]]
    tname = "Table 9"
    print(f"{tname}: Reached and flipped branches for standalone projects")
    table = tabulate(df, tablefmt="simple", floatfmt=".0f", headers="keys")
    save_path = os.path.join(args.out, f'{tname}.txt')
    print(f"Saving to {save_path}")
    with open(save_path, 'w') as f:
        f.write(table + "\n")


if __name__ == "__main__":
    main(parse_args())
