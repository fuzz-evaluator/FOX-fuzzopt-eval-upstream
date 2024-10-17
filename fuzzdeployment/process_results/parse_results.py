import argparse
import re
import os
import logging
import pandas as pd
import numpy as np
from collections import namedtuple
from tqdm import tqdm

WD_SCHEDULER_LOG_COLS = [
    "time_s",
    "selected_border_edge_id",
    "selected_seed_id",
    "max_inst_weight",
    "max_noninst_weight",
    "selected_noninst",
    "total_noninst_weight",
    "noninst_count",
    "total_weight",
    "frontier_size",
    "handler_count",
    "skipped_edge_count",
    "shared_mode",
    "total_frontier_discovery_time",
    "num_queued_items"
]

# Fuzzers: Fuzzer name -> Fuzzer name in the paper
fuzzer_name_map = {
    "aflpp": "AFLPP",
    "cmplog": "AFLPP+C",
    "cmplog_dict": "AFLPP+CD",
    "baseline": "FOX-BASE",
    "optfuzz_nolinesearch": "FOX-SCHED",
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

IGNORE_FUZZERS = {
    "hastefuzz": "HasteFuzz",
    "hastefuzz_baseline": "HasteFuzz",
    "hastefuzz_cmplog": "HasteFuzz+C",
    "hastefuzz_cmplog_dict": "HasteFuzz+CD",
}

dict_fuzzers = {f:n for f, n in fuzzer_name_map.items() if "dict" in f}
non_dict_fuzzers = {f:n for f, n in fuzzer_name_map.items() if "dict" not in f}


def fuzzer_name(dir_name: str):
    fuzzers = dict_fuzzers if "dict" in dir_name else non_dict_fuzzers
    candidates = [(f, n) for f, n in fuzzers.items() if dir_name.endswith(f)]
    if len(candidates) == 0:
        raise ValueError(f"Unknown fuzzer {dir_name}")
    return max(candidates, key=lambda x: len(x[0]))


# Fuzzbench: Results name -> Project name in the paper
fuzzbench_project_name_map = {
    'bloaty'                        : 'bloaty',
    'curl'                          : 'curl',
    'freetype'                      : 'freetype',
    'harfbuzz'                      : 'harfbuzz',
    'jsoncpp'                       : 'jsoncpp',
    'lcms'                          : 'lcms',
    'lcms_cms_transform_fuzzer'     : 'lcms',
    'libjpeg-turbo'                 : 'libjpeg-turbo',
    'libjpeg'                       : 'libjpeg-turbo',
    'libpcap'                       : 'libpcap',
    'libpcap_fuzz_both'             : 'libpcap',
    'libpng'                        : 'libpng',
    'libpng_read_fuzzer'            : 'libpng',
    # 'libxml2'                       : 'libxml2',
    'libxml2_xml'                   : 'libxml2',
    'libxslt'                       : 'libxslt',
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
    'stb'                           : 'stb',
    'stb_stbi_read_fuzzer'          : 'stb',
    'systemd'                       : 'systemd',
    'vorbis'                        : 'vorbis',
    'vorbis_decode_fuzzer'          : 'vorbis',
    'woff2'                         : 'woff2',
    'zlib'                          : 'zlib',
    'zlib_zlib_uncompress_fuzzer'   : 'zlib'
}

# Standalone: Results name -> Binary name in the paper
standalone_project_name_map = {
    'bsdtar'    : 'bsdtar',
    'libarchive': 'bsdtar',
    'exiv2'     : 'exiv2',
    'ffmpeg'    : 'ffmpeg',
    'jasper'    : 'jasper',
    'nm-new'    : 'nm-new',
    'objdump'   : 'objdump',
    'pdftotext' : 'pdftotext',
    'xpdf'      : 'pdftotext',
    'readelf'   : 'readelf',
    'size'      : 'size',
    'strip-new' : 'strip-new',
    'tcpdump'   : 'tcpdump',
    'tiff2pdf'  : 'tiff2pdf',
    'tiff2ps'   : 'tiff2ps',
    'tiffcrop'  : 'tiffcrop',
    'xmllint'   : 'xmllint',
    'libxml2'   : 'xmllint'
}

fuzzbench_projects = set(fuzzbench_project_name_map.values())
project_name_map = {**fuzzbench_project_name_map, **standalone_project_name_map}

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw_data", type=str, required=True, help ="Directory containing the raw results data")
    parser.add_argument("--all", action="store_true", help="Collect all data")
    parser.add_argument("--edges", action="store_true", help="Collect edge counts")
    parser.add_argument("--execs", action="store_true", help="Collect execs")
    parser.add_argument("--control", action="store_true", help="Collect control size")
    parser.add_argument("--cov", action="store_true", help="Collect plot data")
    parser.add_argument("--crashes", action="store_true", help="Collect crash data")
    parser.add_argument("--reached_flipped", action="store_true", help="Collect reached flipped records")
    parser.add_argument("--metadata", type=str, help="Directory containing the FOX metadata for each project")
    parser.add_argument("--out", type=str, help="Output directory", default=os.getcwd())
    args = parser.parse_args()

    if args.all:
        args.edges = True
        args.execs = True
        args.control = True
        args.cov = True
        args.crashes = True
        args.reached_flipped = True

    return args


ProjectMetadata = namedtuple("ProjectMetadata", ["border_edge_parent_first_id", "num_of_children", "border_edge_child"])


def load_metadata(path: str):
    metadata = dict()

    for target in result_dirs(path):
        if target.name.endswith("raw_data"):
            continue
        if target.name == "tarballs":
            continue

        border_edges_path = os.path.join(target.path, "border_edges")
        if not os.path.exists(border_edges_path):
            logging.warning(f"Skipping {target.path}, no border_edges file")
            continue

        border_edge_child = dict()
        with open(border_edges_path, "r") as f:
            for i, line in enumerate(f):
                _, child, _, _ = line.split()
                border_edge_child[i] = int(child)

        border_edges_cache_path = os.path.join(target.path, "border_edges_cache")
        if not os.path.exists(border_edges_cache_path):
            logging.warning(f"Skipping {target.path}, no border_edges_cache file")
            continue

        border_edge_parent_first_id = dict()
        num_of_children = dict()
        with open(border_edges_cache_path, "r") as f:
            for i, line in enumerate(f):
                parent, first_id, num_children = map(int, line.split())
                border_edge_parent_first_id[parent] = first_id
                num_of_children[parent] = num_children

        project = project_name_map[target.name]
        metadata[project] = ProjectMetadata(border_edge_parent_first_id, num_of_children, border_edge_child)

    return metadata


IGNORE_DIRS = {
    "ablation",
    "fox_metadata",
    "tarballs",
    "magma_results",
    "bin_data",
    "br_node_id_data",
    "introspection"
}

IGNORE_SUFFIXES = {"raw_data"}

IGNORE_PREFIXES = {"results"}


def ignore_dir(dir_name: str):
    return dir_name in IGNORE_DIRS or \
        any(dir_name.startswith(prefix) for prefix in IGNORE_PREFIXES) or \
            any(dir_name.endswith(suffix) for suffix in IGNORE_SUFFIXES)


dirs = lambda path: [d for d in os.scandir(path) if d.is_dir()]
files = lambda path: [f for f in os.scandir(path) if f.is_file()]
result_dirs = lambda path: [d for d in dirs(path) if not ignore_dir(d.name)]


def main(args):
    if not os.path.exists(args.raw_data):
        logging.error(f"{args.raw_data} does not exist")
        return
    
    if args.edges:
        total_edges = dict()

    if args.execs:
        execs_records = []

    if args.control:
        control_dfs = []

    if args.cov:
        cov_dfs = []

    if args.reached_flipped:
        if args.metadata is None:
            logging.error("Metadata file is required to collect reached flipped records")
            return
        metadata = load_metadata(args.metadata)
        reached_flipped_records = []

    if args.crashes:
        crash_records = []

    pb = tqdm(result_dirs(args.raw_data))

    for result in pb:
        pb.write(f"Processing {result.path}")

        try:
            fuzzer_str, fuzzer = fuzzer_name(result.name)
            project_str = result.name.replace(fuzzer_str, "").rstrip("_")
            project = project_name_map[project_str]
            if fuzzer_str in IGNORE_FUZZERS:
                continue
        except ValueError:
            logging.warning(f"Skipping {result.path}, unable to parse project and fuzzer")
            continue
        except KeyError:
            logging.warning(f"Skipping {result.path}, unknown project {project_str}")
            continue

        for run in dirs(result.path):
            try:
                _, number = run.name.split("_")
            except ValueError:
                logging.warning(f"Skipping {run.path}, unable to parse run number")
                continue

            if args.control:
                wd_scheduler_log_file = os.path.join(run.path, "default", "wd_scheduler_log")
                if os.path.exists(wd_scheduler_log_file):
                    df = pd.read_csv(wd_scheduler_log_file, sep='\s+', names=WD_SCHEDULER_LOG_COLS, usecols=["time_s", "frontier_size", "skipped_edge_count"])
                    df["frontier_size"] = df["frontier_size"] - df["skipped_edge_count"]
                    df = df.drop(columns=["skipped_edge_count"])
                    df["time_s"] = pd.to_timedelta(df["time_s"], unit="s")
                    control_df = df.groupby(pd.Grouper(key="time_s", freq="1h")).max(numeric_only=True).reset_index()
                    control_df["hour"] = 1 + (control_df["time_s"].dt.seconds / 3600).astype(int)
                    control_df = control_df.drop(columns=["time_s"])
                    control_df["project"] = project
                    control_df["fuzzer"] = fuzzer
                    control_df["run"] = number
                    control_df = control_df.rename(columns={"frontier_size": "control_size"})
                    control_dfs.append(control_df)
                elif fuzzer.startswith("FOX"):
                    logging.warning(f"wd_scheduler_log_file not found for {run.path}")


                queue = os.path.join(run.path, "default", "queue")
                if not os.path.exists(queue):
                    logging.warning(f"Skipping {run.path}, no queue directory")
                    continue

                if not fuzzer.startswith("FOX"):
                    times = np.array([int(re.findall(r"time:(\d+)", seed.name)[0]) / 1000 for seed in files(queue)])
                    num_seeds_over_24hrs = [(times <= 3600 * i).sum() for i in range(1, 25)]
                    control_df = pd.DataFrame.from_records([(i + 1, project, fuzzer, number, num_seeds_over_24hrs[i]) for i in range(24)], columns=["hour", "project", "fuzzer", "run", "control_size"])
                    control_dfs.append(control_df)

            if args.edges or args.execs:
                fuzzer_stats = os.path.join(run.path, "default", "fuzzer_stats")
                if not os.path.exists(fuzzer_stats):
                    logging.warning(f"Skipping {run.path}, no fuzzer_stats file")
                    continue

                with open(fuzzer_stats, "r") as f:
                    for line in f:
                        if args.edges and line.startswith("total_edges"):
                            total_edges_project = int(line.split(":")[1].strip())
                            if project in total_edges and total_edges_project != total_edges[project]:
                                logging.warning(f"total_edges for {project} is inconsistent across runs: {total_edges[project]} != {total_edges_project}")
                            total_edges[project] = total_edges_project
                        elif args.execs and line.startswith("execs_done"):
                            execs_done = int(line.split(":")[1].strip())
                            execs_records.append((project, fuzzer, number, execs_done))

            if args.cov:
                plot_data_file = os.path.join(run.path, "default", "plot_data")
                if not os.path.exists(plot_data_file):
                    logging.warning(f"Skipping {run.path}, no plot_data file")
                    continue

                df = pd.read_csv(plot_data_file)
                df = df.rename(columns=lambda x: x.strip())
                df["time_delta"] = pd.to_timedelta(df["# relative_time"], unit="s")
                df = df[["time_delta", "edges_found"]]
                df["project"] = project
                df["fuzzer"] = fuzzer
                df["run"] = number
                cov_dfs.append(df)

            if args.reached_flipped and project not in fuzzbench_projects:
                fuzz_bitmap_file = os.path.join(run.path, "default", "fuzz_bitmap")
                if not os.path.exists(fuzz_bitmap_file):
                    logging.warning(f"Skipping {run.path}, no fuzz_bitmap file")
                    continue

                with open(fuzz_bitmap_file, "rb") as f:
                    fuzz_bitmap = np.frombuffer(f.read(), dtype=np.uint8) != 0xff
            
                if project not in metadata:
                    logging.warning(f"Skipping {run.path}, no metadata for {project}")
                    continue
                project_metadata: ProjectMetadata = metadata[project]

                nodes_reached = 0
                nodes_flipped = 0

                for parent, reached in enumerate(fuzz_bitmap):
                    if not reached or parent not in project_metadata.num_of_children:
                        continue

                    num_children = project_metadata.num_of_children[parent]
                    if num_children < 2:
                        continue

                    nodes_reached += 1

                    first_id = project_metadata.border_edge_parent_first_id[parent]
                    nodes_flipped += all(fuzz_bitmap[project_metadata.border_edge_child[edge]] for edge in range(first_id, first_id + num_children))
            
                reached_flipped_records.append((project, fuzzer, number, nodes_reached, nodes_flipped))

            if args.crashes:
                crashes_dir = os.path.join(run.path, "default", "crashes")
                if not os.path.exists(crashes_dir):
                    logging.warning(f"Skipping {run.path}, no crashes directory")
                    continue

                num_crashes = len([f for f in files(crashes_dir) if f.name != "README.txt"])

                crash_records.append((project, fuzzer, number, num_crashes))

    os.makedirs(args.out, exist_ok=True)
    os.chdir(args.out)

    if args.control:
        control_df = pd.concat(control_dfs, ignore_index=True)
        control_df.to_csv("control.csv")

    if args.edges:
        df = pd.DataFrame.from_records([(project in fuzzbench_projects, project, total_edges[project]) for project in total_edges], columns=["fuzzbench", "project", "total_edges"])
        df.sort_values(by=["fuzzbench", "project"], inplace=True)
        df.to_csv("edges.csv")

    if args.execs:
        execs_df = pd.DataFrame.from_records(execs_records, columns=["project", "fuzzer", "run", "execs"])
        execs_df.to_csv("execs.csv")

    if args.cov:
        cov_df = pd.concat(cov_dfs, ignore_index=True)
        cov_df = cov_df.groupby(["project", "fuzzer", "run", pd.Grouper(key="time_delta", freq="1h")]).max().reset_index()
        cov_df["hour"] = 1 + (cov_df.time_delta.dt.seconds / 3600).astype(int)
        cov_df = cov_df.drop(columns=["time_delta"])
        cov_df.to_csv("cov.csv")

    if args.reached_flipped:
        reached_flipped_df = pd.DataFrame.from_records(reached_flipped_records, columns=["project", "fuzzer", "run", "nodes_reached", "nodes_flipped"])
        reached_flipped_df.to_csv("reached_flipped.csv")

    if args.crashes:
        crash_df = pd.DataFrame.from_records(crash_records, columns=["project", "fuzzer", "run", "num_crashes"])
        crash_df.to_csv("crashes.csv")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main(parse_args())
